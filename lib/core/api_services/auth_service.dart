import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:waretrack_mini/core/api_services/api_connection_guard.dart';
import 'package:waretrack_mini/core/api_services/base_api.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/services/device_info_service.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/data/models/device_verification_response_model.dart';
import 'package:waretrack_mini/data/models/trial_status_model.dart';
import 'package:waretrack_mini/data/models/user_model.dart';

abstract class AuthService {
  // TODO: Temporarily disabled.
  // Future<UserModel?> checkDeviceVerification();
  Future<UserModel> codeVerify(String code);

  /// Trial build only — registers device_uuid with the server (or
  /// re-checks an already-registered one) and returns its current trial
  /// status. See TrialService.
  Future<TrialStatusModel> verifyDeviceTrial();
}

class AuthServiceImpl implements AuthService {
  // TODO: Temporarily disabled with checkDeviceVerification().
  // static final Uri _deviceVerifyUri = BaseApi.endpoint('device-verify');
  static final Uri _codeVerifyUri = BaseApi.endpoint('code-verify');
  static final Uri _trialVerifyUri = BaseApi.endpoint('device-verify');
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const String _logName = 'DeviceVerification';

  final http.Client client;
  final LocalStorage localStorage;
  final Future<String> Function() _getAndroidId;

  AuthServiceImpl(
    this.client, {
    required this.localStorage,
    ApiConnectionGuard? connectionGuard,
    Future<String> Function()? getAndroidId,
  }) : _connectionGuard = connectionGuard,
       _getAndroidId = getAndroidId ?? DeviceInfoService.getAndroidId;

  final ApiConnectionGuard? _connectionGuard;

  /// Falls back to English when [AppSettingsController] isn't registered
  /// (e.g. in unit tests that construct [AuthServiceImpl] directly).
  static AppLocalizations get _l10n =>
      (sl.isRegistered<AppSettingsController>()
              ? sl<AppSettingsController>().settings.language
              : AppLanguage.english)
          .localizations;

  // TODO: Temporarily disabled.
  // @override
  // Future<UserModel?> checkDeviceVerification() async {
  //   try {
  //     final String deviceUuid = await _getRequiredDeviceUuid();
  //     final response = await _postRequest(_deviceVerifyUri, {
  //       'device_uuid': deviceUuid,
  //       ...AppBuildConfig.apiPayload,
  //     });
  //     final json = _decodeResponse(response);
  //
  //     if (response.statusCode == 200 && json['status'] == true) {
  //       final model = DeviceVerificationResponseModel.fromJson(json);
  //       final data = _readData(json);
  //       final user = UserModel.fromJson(data);
  //       await _cacheSuccessfulVerification(
  //         model: model,
  //         dataJson: data,
  //         verificationCode: _readAccesscode(json, data),
  //       );
  //       return user;
  //     }
  //
  //     if (response.statusCode < 500 && json['status'] == false) {
  //       await _clearVerificationCache();
  //       return null;
  //     }
  //
  //     throw Exception(json['message'] ?? 'Unable to check the device verification status.');
  //   } catch (e) {
  //     throw Exception(e.toString());
  //   }
  // }

  @override
  Future<UserModel> codeVerify(String code) async {
    try {
      final String deviceUuid = await _getRequiredDeviceUuid();
      final response = await _postRequest(_codeVerifyUri, {
        'accesscode': code,
        'device_uuid': deviceUuid,
        ...AppBuildConfig.apiPayload,
      });
      final json = _decodeResponse(response);

      if (response.statusCode == 200 && json['status'] == true) {
        final model = DeviceVerificationResponseModel.fromJson(json);
        final data = _readData(json);
        final user = UserModel.fromJson(data);
        await _cacheSuccessfulVerification(
          model: model,
          dataJson: data,
          responseJson: json,
          deviceUuid: deviceUuid,
          verificationCode: code,
        );
        return user;
      }

      throw Exception(json['message'] ?? _l10n.authenticationFailedRetry);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<TrialStatusModel> verifyDeviceTrial() async {
    final String deviceUuid = await _getRequiredDeviceUuid();
    final response = await _postRequest(_trialVerifyUri, {
      'device_uuid': deviceUuid,
      ...AppBuildConfig.apiPayload,
    });
    final json = _decodeResponse(response);

    if (response.statusCode == 200 && json['status'] == true) {
      return TrialStatusModel.fromJson(json);
    }

    throw Exception(json['message'] ?? _l10n.trialStatusCheckFailed);
  }

  Future<String> _getRequiredDeviceUuid() async {
    final deviceUuid = (await _getAndroidId()).trim();
    if (deviceUuid.isEmpty) {
      throw Exception(DeviceInfoService.retrievalErrorMessage);
    }

    developer.log('androidId: $deviceUuid', name: _logName);
    return deviceUuid;
  }

  Future<void> _cacheSuccessfulVerification({
    required DeviceVerificationResponseModel model,
    required Map<String, dynamic> dataJson,
    required Map<String, dynamic> responseJson,
    required String deviceUuid,
    String? verificationCode,
  }) async {
    try {
      await localStorage.writeString(kApiEnv, BaseApi.apiEnv);
      await localStorage.writeBool(kIsVerified, true);
      await localStorage.writeString(kDeviceUuid, deviceUuid);
      if (verificationCode != null && verificationCode.isNotEmpty) {
        await localStorage.writeString(kVerificationCode, verificationCode);
      }
      await localStorage.writeString(
        kDeviceVerificationResponse,
        jsonEncode(responseJson),
      );
      await localStorage.writeString(
        kCodeVerifyResponseJson,
        jsonEncode(responseJson),
      );
      await localStorage.writeString(
        kDeviceVerificationData,
        jsonEncode(dataJson),
      );
      await localStorage.writeString(kAuthUserData, jsonEncode(dataJson));
      await localStorage.writeString(kCompanyId, model.data?.companyId ?? '');
      await localStorage.writeString(kCode, model.data?.code ?? '');
      await localStorage.writeString(kDatachar01, model.data?.datachar01 ?? '');
      await localStorage.writeString(kDatachar02, model.data?.datachar02 ?? '');
      await localStorage.writeString(kAppName, model.data?.datachar01 ?? '');
      await localStorage.writeString(kAppVersion, model.data?.datachar02 ?? '');
      await localStorage.writeString(kAccesscode, model.data?.accesscode ?? '');
      await _cacheTrialEndTime(dataJson);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to cache successful verification.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // TODO: Temporarily disabled with checkDeviceVerification().
  // Future<void> _clearVerificationCache() async {
  //   try {
  //     await localStorage.writeBool(kIsVerified, false);
  //     await localStorage.remove(kVerificationCode);
  //     await localStorage.remove(kDeviceUuid);
  //     await localStorage.remove(kDeviceVerificationResponse);
  //     await localStorage.remove(kDeviceVerificationData);
  //     await localStorage.remove(kAuthUserData);
  //     await localStorage.remove(kCompanyId);
  //     await localStorage.remove(kCode);
  //     await localStorage.remove(kDatachar01);
  //     await localStorage.remove(kDatachar02);
  //     await localStorage.remove(kAppName);
  //     await localStorage.remove(kAppVersion);
  //     await localStorage.remove(kAccesscode);
  //   } catch (error, stackTrace) {
  //     developer.log(
  //       'Failed to clear unverified device cache.',
  //       name: _logName,
  //       error: error,
  //       stackTrace: stackTrace,
  //     );
  //   }
  // }

  /// Parses the code-verify response's `datachar03` field into the
  /// authoritative trial-end timestamp (see [kTrialEndTime]). Returns null
  /// when the field is absent or not a recognizable date/time, so the
  /// caller can leave any previously cached endtime untouched rather than
  /// clobber it with a bad value — TrialService falls back to its local
  /// calculation when nothing valid has ever been cached.
  DateTime? _parseTrialEndTime(String? datachar03) {
    final value = datachar03?.trim();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Persists `data.datachar03` — the absolute moment this device's trial
  /// ends — as the client-side trial window. The server sends it as
  /// `"2026-07-30 13:08:51"`, which [DateTime.tryParse] accepts and which is
  /// normalised to ISO-8601 on the way in so TrialService can read it back
  /// with a plain parse.
  ///
  /// A missing or unparseable value leaves any previously stored end time
  /// alone rather than clearing it: dropping it would silently hand the trial
  /// window back to the [TrialDuration] fallback and could re-open an
  /// already-expired trial.
  Future<void> _cacheTrialEndTime(Map<String, dynamic> dataJson) async {
    final raw = dataJson['datachar03']?.toString();
    final parsed = _parseTrialEndTime(raw);
    if (parsed == null) {
      if (raw != null && raw.trim().isNotEmpty) {
        developer.log(
          'Ignoring unparseable trial end time: $raw',
          name: _logName,
        );
      }
      return;
    }

    final endTime = parsed.subtract(Duration(hours: 3));
    print('-------------trial end time: $endTime (from server value: $raw)');

    await localStorage.writeString(kTrialEndTime, endTime.toIso8601String());
  }

  Map<String, dynamic> _readData(Map<String, dynamic> responseJson) {
    final data = responseJson['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid device verification data.');
    }
    return data;
  }

  // TODO: Temporarily disabled with checkDeviceVerification().
  // String? _readAccesscode(
  //   Map<String, dynamic> responseJson,
  //   Map<String, dynamic> dataJson,
  // ) {
  //   final value = dataJson['accesscode'] ?? responseJson['accesscode'];
  //   final accesscode = value?.toString().trim() ?? '';
  //   return accesscode.isEmpty ? null : accesscode;
  // }

  Future<http.Response> _postRequest(
    Uri uri,
    Map<String, String> payload,
  ) async {
    final requestBody = jsonEncode(payload);
    developer.log('url: $uri', name: _logName);
    developer.log('request body: $requestBody', name: _logName);

    Future<http.Response> sendRequest() => client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        )
        .timeout(_requestTimeout);

    final response = _connectionGuard == null
        ? await sendRequest()
        : await _connectionGuard.run(sendRequest);

    developer.log('response status: ${response.statusCode}', name: _logName);
    developer.log('response body: ${response.body}', name: _logName);
    return response;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decodedResponse = jsonDecode(response.body);
    if (decodedResponse is! Map<String, dynamic>) {
      throw const FormatException('Invalid device verification response.');
    }
    return decodedResponse;
  }
}
