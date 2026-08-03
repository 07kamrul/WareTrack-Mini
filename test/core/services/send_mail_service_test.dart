import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:waretrack_mini/core/services/export_file_service.dart';
import 'package:waretrack_mini/core/api_services/send_mail_service.dart';
import 'package:waretrack_mini/core/api_services/api_connection_guard.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';

void main() {
  test('does not call send-mail API while offline', () async {
    final storage = await _verifiedStorage();
    final file = await _nonEmptyTestFile('send-mail-offline.csv');
    addTearDown(() => file.delete());
    final client = _RecordingClient(
      responseBody: '{"success":true,"message":"sent"}',
    );

    await expectLater(
      SendMailService(
        storage,
        connectionGuard: ApiConnectionGuard(
          checkReachability: () async => false,
        ),
        sendRequest: client.send,
        getAndroidId: _androidId,
      ).send(
        email: 'receiver@example.com',
        selectedFormat: 'csv',
        exportResult: ExportFileResult(
          fileName: 'export.csv',
          filePath: file.path,
          mimeType: 'text/csv',
        ),
      ),
      throwsA(isA<ApiOfflineException>()),
    );
    expect(client.request, isNull);
  });

  test(
    'sends cached authentication and generated file as multipart data',
    () async {
      final storage = InMemoryLocalStorage();
      await storage.writeString(kVerificationCode, '66982739');
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}send-mail-test.csv',
      );
      await file.writeAsString('test');
      addTearDown(() => file.delete());
      final client = _RecordingClient(
        responseBody: '{"success":true,"message":"sent"}',
      );

      await SendMailService(
        storage,
        sendRequest: client.send,
        getAndroidId: _androidId,
      ).send(
        email: 'receiver@example.com',
        selectedFormat: 'csv',
        exportResult: ExportFileResult(
          fileName: 'export.csv',
          filePath: file.path,
          mimeType: 'text/csv',
        ),
      );

      expect(client.request?.fields, <String, String>{
        'accesscode': '66982739',
        'device_uuid': 'f88dc561ce1b4da9',
        'email': 'receiver@example.com',
      });
      expect(client.request?.files.single.field, 'files[]');
      expect(client.request?.files.single.filename, file.uri.pathSegments.last);
      expect(client.request?.files.single.length, greaterThan(0));
      expect(
        client.request?.headers['content-type'],
        startsWith('multipart/form-data; boundary='),
      );
      expect(
        client.request?.headers['content-type'],
        isNot('application/json'),
      );
    },
  );

  test('rejects missing cached authentication before sending', () async {
    final client = _RecordingClient(
      responseBody: '{"success":true,"message":"sent"}',
    );

    expect(
      SendMailService(
        InMemoryLocalStorage(),
        sendRequest: client.send,
        getAndroidId: _androidId,
      ).validateAuthentication(),
      throwsA(isA<MissingDeviceVerificationException>()),
    );
    expect(client.request, isNull);
  });

  test('returns API message when success is not true', () async {
    final storage = InMemoryLocalStorage();
    await storage.writeString(kVerificationCode, '66982739');
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}send-mail-error.csv',
    );
    await file.writeAsString('test');
    addTearDown(() => file.delete());

    expect(
      SendMailService(
        storage,
        sendRequest: _RecordingClient(
          responseBody: '{"success":false,"message":"API error"}',
        ).send,
        getAndroidId: _androidId,
      ).send(
        email: 'receiver@example.com',
        selectedFormat: 'csv',
        exportResult: ExportFileResult(
          fileName: 'export.csv',
          filePath: file.path,
          mimeType: 'text/csv',
        ),
      ),
      throwsA(
        isA<SendMailApiException>().having(
          (error) => error.message,
          'message',
          'API error',
        ),
      ),
    );
  });

  test('accepts explicit boolean status true response', () async {
    final storage = await _verifiedStorage();
    final file = await _nonEmptyTestFile('send-mail-status-true.csv');
    addTearDown(() => file.delete());

    await SendMailService(
      storage,
      sendRequest: _RecordingClient(
        responseBody: '{"status":true,"message":"sent"}',
      ).send,
      getAndroidId: _androidId,
    ).send(
      email: 'receiver@example.com',
      selectedFormat: 'csv',
      exportResult: ExportFileResult(
        fileName: 'export.csv',
        filePath: file.path,
        mimeType: 'text/csv',
      ),
    );
  });

  test('rejects HTTP 200 response without explicit success flag', () async {
    final storage = await _verifiedStorage();
    final file = await _nonEmptyTestFile('send-mail-missing-success.csv');
    addTearDown(() => file.delete());

    expect(
      SendMailService(
        storage,
        sendRequest: _RecordingClient(
          responseBody: '{"message":"Mail was not confirmed"}',
          statusCode: 200,
        ).send,
        getAndroidId: _androidId,
      ).send(
        email: 'receiver@example.com',
        selectedFormat: 'csv',
        exportResult: ExportFileResult(
          fileName: 'export.csv',
          filePath: file.path,
          mimeType: 'text/csv',
        ),
      ),
      throwsA(
        isA<SendMailApiException>().having(
          (error) => error.message,
          'message',
          'Mail was not confirmed',
        ),
      ),
    );
  });

  test('rejects string success value instead of boolean true', () async {
    final storage = await _verifiedStorage();
    final file = await _nonEmptyTestFile('send-mail-string-success.csv');
    addTearDown(() => file.delete());

    expect(
      SendMailService(
        storage,
        sendRequest: _RecordingClient(
          responseBody: '{"success":"true","message":"Invalid success flag"}',
        ).send,
        getAndroidId: _androidId,
      ).send(
        email: 'receiver@example.com',
        selectedFormat: 'csv',
        exportResult: ExportFileResult(
          fileName: 'export.csv',
          filePath: file.path,
          mimeType: 'text/csv',
        ),
      ),
      throwsA(isA<SendMailApiException>()),
    );
  });

  test('returns empty API message when response has no message', () async {
    final storage = await _verifiedStorage();
    final file = await _nonEmptyTestFile('send-mail-no-message.csv');
    addTearDown(() => file.delete());

    expect(
      SendMailService(
        storage,
        sendRequest: _RecordingClient(responseBody: '{"success":false}').send,
        getAndroidId: _androidId,
      ).send(
        email: 'receiver@example.com',
        selectedFormat: 'csv',
        exportResult: ExportFileResult(
          fileName: 'export.csv',
          filePath: file.path,
          mimeType: 'text/csv',
        ),
      ),
      throwsA(
        isA<SendMailApiException>().having(
          (error) => error.message,
          'message',
          isEmpty,
        ),
      ),
    );
  });

  test('rejects a missing generated file before sending', () async {
    final storage = await _verifiedStorage();
    final client = _RecordingClient(
      responseBody: '{"success":true,"message":"sent"}',
    );

    expect(
      SendMailService(
        storage,
        sendRequest: client.send,
        getAndroidId: _androidId,
      ).send(
        email: 'receiver@example.com',
        selectedFormat: 'csv',
        exportResult: const ExportFileResult(
          fileName: 'missing.csv',
          filePath: 'missing.csv',
          mimeType: 'text/csv',
        ),
      ),
      throwsA(isA<MissingSendMailFileException>()),
    );
    expect(client.request, isNull);
  });

  test('rejects an empty generated file before sending', () async {
    final storage = await _verifiedStorage();
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}send-mail-empty.csv',
    );
    await file.writeAsBytes(const <int>[]);
    addTearDown(() => file.delete());
    final client = _RecordingClient(
      responseBody: '{"success":true,"message":"sent"}',
    );

    expect(
      SendMailService(
        storage,
        sendRequest: client.send,
        getAndroidId: _androidId,
      ).send(
        email: 'receiver@example.com',
        selectedFormat: 'csv',
        exportResult: ExportFileResult(
          fileName: 'empty.csv',
          filePath: file.path,
          mimeType: 'text/csv',
        ),
      ),
      throwsA(isA<EmptySendMailFileException>()),
    );
    expect(client.request, isNull);
  });

  test('rejects an empty email before sending', () async {
    final client = _RecordingClient(
      responseBody: '{"success":true,"message":"sent"}',
    );

    expect(
      SendMailService(InMemoryLocalStorage(), sendRequest: client.send).send(
        email: ' ',
        selectedFormat: 'csv',
        exportResult: const ExportFileResult(
          fileName: 'export.csv',
          filePath: 'export.csv',
          mimeType: 'text/csv',
        ),
      ),
      throwsA(isA<MissingSendMailEmailException>()),
    );
    expect(client.request, isNull);
  });
}

Future<InMemoryLocalStorage> _verifiedStorage() async {
  final storage = InMemoryLocalStorage();
  await storage.writeString(kVerificationCode, '66982739');
  return storage;
}

Future<String> _androidId() async => 'f88dc561ce1b4da9';

Future<File> _nonEmptyTestFile(String name) async {
  final file = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}$name',
  );
  await file.writeAsString('test');
  return file;
}

final class _RecordingClient {
  _RecordingClient({required this.responseBody, this.statusCode = 200});

  final String responseBody;
  final int statusCode;
  http.MultipartRequest? request;

  Future<http.StreamedResponse> send(http.MultipartRequest request) async {
    this.request = request;
    await request.finalize().drain<void>();
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(responseBody)),
      statusCode,
    );
  }
}
