import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waretrack_mini/core/services/device_info_service.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/api_services/auth_service.dart';
import 'package:waretrack_mini/core/api_services/api_connection_guard.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';

void main() {
  test('does not call verification API while offline', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response('{}', 200);
    });
    final dataSource = AuthServiceImpl(
      client,
      localStorage: InMemoryLocalStorage(),
      connectionGuard: ApiConnectionGuard(checkReachability: () async => false),
      getAndroidId: () async => 'android-device-id',
    );

    await expectLater(
      dataSource.codeVerify('ABC123'),
      throwsA(predicate((error) => error != null && isApiOfflineError(error))),
    );
    expect(requestCount, 0);
  });

  test(
    'does not call verification API when Android ID cannot be retrieved',
    () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });
      final dataSource = AuthServiceImpl(
        client,
        localStorage: InMemoryLocalStorage(),
        getAndroidId: () =>
            throw Exception(DeviceInfoService.retrievalErrorMessage),
      );

      await expectLater(
        dataSource.codeVerify('ABC123'),
        throwsA(
          predicate(
            (error) => error.toString().contains(
              DeviceInfoService.retrievalErrorMessage,
            ),
          ),
        ),
      );

      expect(requestCount, 0);
    },
  );

  /*
  TODO: Temporarily disabled with checkDeviceVerification().
  test(
    'checks server verification status with device_uuid and app payload',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'status': false}), 200);
      });
      final dataSource = AuthServiceImpl(
        client,
        localStorage: InMemoryLocalStorage(),
        getAndroidId: () async => 'android-device-id',
      );

      final result = await dataSource.checkDeviceVerification();

      expect(result, isNull);
      expect(capturedRequest.url.path, '/api/device-verify');
      expect(jsonDecode(capturedRequest.body), {
        'device_uuid': 'android-device-id',
        ...AppBuildConfig.apiPayload,
      });
    },
  );

  test('unverified server response clears cached verification data', () async {
    final storage = InMemoryLocalStorage();
    await storage.writeBool(kIsVerified, true);
    await storage.writeString(kVerificationCode, 'OLD-CODE');
    await storage.writeString(kDeviceUuid, 'old-device-id');
    await storage.writeString(kDeviceVerificationResponse, '{}');
    await storage.writeString(kDeviceVerificationData, '{}');
    await storage.writeString(kAuthUserData, '{}');
    await storage.writeString(kCompanyId, 'old-company-id');
    await storage.writeString(kCode, 'old-code');
    await storage.writeString(kDatachar01, 'old-datachar01');
    await storage.writeString(kDatachar02, 'old-datachar02');
    await storage.writeString(kAppName, 'old-app-name');
    await storage.writeString(kAppVersion, 'old-app-version');
    await storage.writeString(kAccesscode, 'old-accesscode');
    final dataSource = AuthServiceImpl(
      MockClient(
        (request) async => http.Response(jsonEncode({'status': false}), 200),
      ),
      localStorage: storage,
      getAndroidId: () async => 'android-device-id',
    );

    await dataSource.checkDeviceVerification();

    expect(await storage.readBool(kIsVerified), isFalse);
    expect(await storage.readString(kVerificationCode), isNull);
    expect(await storage.readString(kDeviceUuid), isNull);
    expect(await storage.readString(kDeviceVerificationResponse), isNull);
    expect(await storage.readString(kDeviceVerificationData), isNull);
    expect(await storage.readString(kAuthUserData), isNull);
    expect(await storage.readString(kCompanyId), isNull);
    expect(await storage.readString(kCode), isNull);
    expect(await storage.readString(kDatachar01), isNull);
    expect(await storage.readString(kDatachar02), isNull);
    expect(await storage.readString(kAppName), isNull);
    expect(await storage.readString(kAppVersion), isNull);
    expect(await storage.readString(kAccesscode), isNull);
  });

  test(
    'treats status false response as unverified even with 4xx status',
    () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({'status': false, 'message': 'Device is not verified'}),
          422,
        ),
      );
      final dataSource = AuthServiceImpl(
        client,
        localStorage: InMemoryLocalStorage(),
        getAndroidId: () async => 'android-device-id',
      );

      final result = await dataSource.checkDeviceVerification();

      expect(result, isNull);
    },
  );

  test('does not send startup request with empty device_uuid', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response(jsonEncode({'status': false}), 200);
    });
    final dataSource = AuthServiceImpl(
      client,
      localStorage: InMemoryLocalStorage(),
      getAndroidId: () async => '  ',
    );

    await expectLater(
      dataSource.checkDeviceVerification(),
      throwsA(
        predicate(
          (error) => error.toString().contains(
            DeviceInfoService.retrievalErrorMessage,
          ),
        ),
      ),
    );

    expect(requestCount, 0);
  });

  test('throws for server error so startup can show retry', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({'status': false, 'message': 'Server error'}),
        500,
      ),
    );
    final dataSource = AuthServiceImpl(
      client,
      localStorage: InMemoryLocalStorage(),
      getAndroidId: () async => 'android-device-id',
    );

    await expectLater(
      dataSource.checkDeviceVerification(),
      throwsA(predicate((error) => error.toString().contains('Server error'))),
    );
  });
  */

  test('verifies access code with accesscode and device_uuid', () async {
    late http.Request capturedRequest;
    final storage = InMemoryLocalStorage();
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({'status': true, 'data': _userJson}),
        200,
      );
    });
    final dataSource = AuthServiceImpl(
      client,
      localStorage: storage,
      getAndroidId: () async => 'android-device-id',
    );

    final result = await dataSource.codeVerify('ABC123');

    expect(result.code, 1);
    expect(capturedRequest.url.path, '/api/code-verify');
    expect(jsonDecode(capturedRequest.body), {
      'accesscode': 'ABC123',
      'device_uuid': 'android-device-id',
      ...AppBuildConfig.apiPayload,
    });
    expect(await storage.readBool(kIsVerified), isTrue);
    expect(await storage.readString(kVerificationCode), 'ABC123');
    expect(await storage.readString(kAccesscode), '12345678');
    expect(await storage.readString(kDeviceUuid), 'android-device-id');
    expect(await storage.readString(kCompanyId), '2');
    expect(await storage.readString(kCode), '1');
    expect(await storage.readString(kDatachar01), 'one');
    expect(await storage.readString(kDatachar02), 'two');
    expect(jsonDecode((await storage.readString(kCodeVerifyResponseJson))!), {
      'status': true,
      'data': _userJson,
    });
  });

  test('caches trial end time when datachar03 is present', () async {
    final storage = InMemoryLocalStorage();
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'status': true,
          'data': {..._userJson, 'datachar03': '2026-07-30 13:08:51'},
        }),
        200,
      ),
    );
    final dataSource = AuthServiceImpl(
      client,
      localStorage: storage,
      getAndroidId: () async => 'android-device-id',
    );

    await dataSource.codeVerify('ABC123');

    expect(
      await storage.readString(kTrialEndTime),
      DateTime.parse('2026-07-30 13:08:51').toIso8601String(),
    );
  });

  test('does not cache a trial end time when datachar03 is absent', () async {
    final storage = InMemoryLocalStorage();
    final client = MockClient(
      (request) async =>
          http.Response(jsonEncode({'status': true, 'data': _userJson}), 200),
    );
    final dataSource = AuthServiceImpl(
      client,
      localStorage: storage,
      getAndroidId: () async => 'android-device-id',
    );

    await dataSource.codeVerify('ABC123');

    expect(await storage.readString(kTrialEndTime), isNull);
  });

  test('leaves a previously cached trial end time untouched when the new '
      'response has an unparseable datachar03', () async {
    final storage = InMemoryLocalStorage();
    await storage.writeString(kTrialEndTime, '2026-08-01T00:00:00.000');
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'status': true,
          'data': {..._userJson, 'datachar03': 'not-a-date'},
        }),
        200,
      ),
    );
    final dataSource = AuthServiceImpl(
      client,
      localStorage: storage,
      getAndroidId: () async => 'android-device-id',
    );

    await dataSource.codeVerify('ABC123');

    expect(await storage.readString(kTrialEndTime), '2026-08-01T00:00:00.000');
  });

  group('verifyDeviceTrial', () {
    test('active response reports device_uuid and app payload', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'status': true,
            'message': 'ok',
            'data': {'trial_status': 'active', 'expire_date': '2026-08-08'},
          }),
          200,
        );
      });
      final dataSource = AuthServiceImpl(
        client,
        localStorage: InMemoryLocalStorage(),
        getAndroidId: () async => 'android-device-id',
      );

      final result = await dataSource.verifyDeviceTrial();

      expect(result.isActive, isTrue);
      expect(result.expireDate, DateTime.parse('2026-08-08'));
      expect(capturedRequest.url.path, '/api/device-verify');
      expect(jsonDecode(capturedRequest.body), {
        'device_uuid': 'android-device-id',
        ...AppBuildConfig.apiPayload,
      });
    });

    test('expired response reports isActive false', () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'status': true,
            'message': 'expired',
            'data': {'trial_status': 'expired', 'expire_date': '2026-08-01'},
          }),
          200,
        ),
      );
      final dataSource = AuthServiceImpl(
        client,
        localStorage: InMemoryLocalStorage(),
        getAndroidId: () async => 'android-device-id',
      );

      final result = await dataSource.verifyDeviceTrial();

      expect(result.isActive, isFalse);
    });

    test('accepts trial_expire_date as an alternate date key', () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'status': true,
            'data': {
              'trial_status': 'active',
              'trial_expire_date': '2026-08-08',
            },
          }),
          200,
        ),
      );
      final dataSource = AuthServiceImpl(
        client,
        localStorage: InMemoryLocalStorage(),
        getAndroidId: () async => 'android-device-id',
      );

      final result = await dataSource.verifyDeviceTrial();

      expect(result.expireDate, DateTime.parse('2026-08-08'));
    });

    test('propagates offline error without calling the API', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });
      final dataSource = AuthServiceImpl(
        client,
        localStorage: InMemoryLocalStorage(),
        connectionGuard: ApiConnectionGuard(
          checkReachability: () async => false,
        ),
        getAndroidId: () async => 'android-device-id',
      );

      await expectLater(
        dataSource.verifyDeviceTrial(),
        throwsA(
          predicate((error) => error != null && isApiOfflineError(error)),
        ),
      );
      expect(requestCount, 0);
    });
  });

  /*
  TODO: Temporarily disabled with checkDeviceVerification().
  test('successful device verification caches full server response', () async {
    final storage = InMemoryLocalStorage();
    await storage.writeString(kVerificationCode, 'EXISTING');
    final responseJson = {
      'status': true,
      'message': 'verified',
      'data': _userJson,
    };
    final client = MockClient(
      (request) async => http.Response(jsonEncode(responseJson), 200),
    );
    final dataSource = AuthServiceImpl(
      client,
      localStorage: storage,
      getAndroidId: () async => 'android-device-id',
    );

    await dataSource.checkDeviceVerification();

    final expectedResponseJson = {
      'message': 'verified',
      'status': true,
      'data': {
        'company_id': '2',
        'code': '1',
        'datachar01': 'one',
        'datachar02': 'two',
        'accesscode': '12345678',
        'status': '1',
      },
    };

    expect(await storage.readBool(kIsVerified), isTrue);
    expect(await storage.readString(kVerificationCode), '12345678');
    expect(await storage.readString(kDeviceUuid), isNull);
    expect(
      jsonDecode((await storage.readString(kDeviceVerificationResponse))!),
      expectedResponseJson,
    );
    expect(
      jsonDecode((await storage.readString(kDeviceVerificationData))!),
      _userJson,
    );
    expect(jsonDecode((await storage.readString(kAuthUserData))!), _userJson);
    expect(await storage.readString(kCompanyId), '2');
    expect(await storage.readString(kCode), '1');
    expect(await storage.readString(kDatachar01), 'one');
    expect(await storage.readString(kDatachar02), 'two');
    expect(await storage.readString(kAppName), 'one');
    expect(await storage.readString(kAppVersion), 'two');
    expect(await storage.readString(kAccesscode), '12345678');
  });
  */
}

const Map<String, dynamic> _userJson = {
  'code': 1,
  'company_id': 2,
  'status': 1,
  'kcode2': 3,
  'accesscode': 12345678,
  'datachar01': 'one',
  'datachar02': 'two',
};
