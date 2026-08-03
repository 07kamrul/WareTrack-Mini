import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:waretrack_mini/core/api_services/api_connection_guard.dart';
import 'package:waretrack_mini/core/api_services/base_api.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/services/device_info_service.dart';
import 'package:waretrack_mini/core/services/export_file_service.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';

typedef SendMultipartRequest =
    Future<http.StreamedResponse> Function(http.MultipartRequest request);

final class MissingDeviceVerificationException implements Exception {
  const MissingDeviceVerificationException();
}

final class MissingSendMailEmailException implements Exception {
  const MissingSendMailEmailException();
}

final class MissingSendMailFileException implements Exception {
  const MissingSendMailFileException();
}

final class EmptySendMailFileException implements Exception {
  const EmptySendMailFileException();
}

final class SendMailApiException implements Exception {
  const SendMailApiException(this.message);

  final String message;
}

final class SendMailService {
  SendMailService(
    this._localStorage, {
    ApiConnectionGuard? connectionGuard,
    SendMultipartRequest? sendRequest,
    Future<String> Function()? getAndroidId,
  }) : _connectionGuard = connectionGuard,
       _sendRequest = sendRequest ?? _send,
       _getAndroidId = getAndroidId ?? DeviceInfoService.getAndroidId;

  static final Uri _sendMailUri = BaseApi.endpoint('send-mail');
  static const Duration _requestTimeout = Duration(seconds: 30);

  final LocalStorage _localStorage;
  final ApiConnectionGuard? _connectionGuard;
  final SendMultipartRequest _sendRequest;
  final Future<String> Function() _getAndroidId;

  Future<void> validateAuthentication() async {
    await _readAuthentication();
  }

  Future<void> send({
    required String email,
    required String selectedFormat,
    required ExportFileResult exportResult,
  }) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw const MissingSendMailEmailException();
    }

    final authentication = await _readAuthentication();
    final file = File(exportResult.filePath).absolute;
    final fileExists = await file.exists();
    final fileSize = fileExists ? await file.length() : 0;

    if (!fileExists) {
      throw const MissingSendMailFileException();
    }
    if (fileSize == 0) {
      throw const EmptySendMailFileException();
    }

    final request = http.MultipartRequest('POST', _sendMailUri);
    request.fields['accesscode'] = authentication.accesscode;
    request.fields['device_uuid'] = authentication.deviceUuid;
    request.fields['email'] = normalizedEmail;
    request.files.add(await http.MultipartFile.fromPath('files[]', file.path));

    Future<http.StreamedResponse> sendRequest() =>
        _sendRequest(request).timeout(_requestTimeout);
    final streamedResponse = _connectionGuard == null
        ? await sendRequest()
        : await _connectionGuard.run(sendRequest);
    final response = await http.Response.fromStream(streamedResponse);

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid send mail response.');
    }
    final isSuccessful =
        decoded['success'] == true || decoded['status'] == true;

    if (isSuccessful) {
      return;
    }

    final message = decoded['message'];
    throw SendMailApiException(
      message is String && message.trim().isNotEmpty ? message : '',
    );
  }

  static Future<http.StreamedResponse> _send(http.MultipartRequest request) {
    return request.send();
  }

  Future<_SendMailAuthentication> _readAuthentication() async {
    final accesscode =
        (await _localStorage.readString(kVerificationCode))?.trim() ?? '';
    final deviceUuid = (await _getAndroidId()).trim();

    if (accesscode.isEmpty || deviceUuid.isEmpty) {
      throw const MissingDeviceVerificationException();
    }
    return _SendMailAuthentication(
      accesscode: accesscode,
      deviceUuid: deviceUuid,
    );
  }
}

final class _SendMailAuthentication {
  const _SendMailAuthentication({
    required this.accesscode,
    required this.deviceUuid,
  });

  final String accesscode;
  final String deviceUuid;
}
