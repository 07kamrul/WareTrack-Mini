import 'package:flutter/services.dart';

const String kLastUpdateTime = 'kLastUpdateTime';
const MethodChannel kPackageInfoChannel = MethodChannel(
  'com.anshintech.waretrackmini/package_info',
);

/// API environment (BaseApi.apiEnv) that wrote the cached verification data.
/// All environment APKs share one applicationId, so SharedPreferences survive
/// when one environment's APK replaces another — this stamp detects that.
const String kApiEnv = 'api_env';

const String kIsVerified = 'is_verified';
const String kVerificationCode = 'verification_code';
const String kDeviceUuid = 'device_uuid';
const String kDeviceVerificationResponse = 'device_verification_response';
const String kDeviceVerificationData = 'device_verification_data';
const String kCodeVerifyResponseJson = 'code_verify_response_json';
const String kAuthUserData = 'auth_user_data';
const String kCompanyId = 'company_id';
const String kCode = 'code';
const String kDatachar01 = 'datachar01';
const String kDatachar02 = 'datachar02';
const String kAppName = 'appName';
const String kAppVersion = 'appVersion';
const String kAccesscode = 'accesscode';

/// Last trial expiration date the server reported for this device, cached
/// only as an offline fallback — the server is the authority. ISO-8601 date
/// string. See TrialService.
const String kTrialExpireDate = 'trial_expire_date';

/// Last trial status ('active' / 'expired') the server reported. See
/// TrialService.
const String kTrialStatus = 'trial_status';

/// This device's first-launch timestamp for the trial build, set
/// once and never overwritten. Anchors the client-side [TrialDuration] check
/// so it can enforce the trial window even fully offline. ISO-8601 date
/// string. See TrialService.
const String kTrialFirstLaunchDate = 'trial_first_launch_date';

/// Authoritative trial-end timestamp reported by the server as
/// `datachar03` on a successful code-verify response — the sole source of
/// truth for trial expiration. Only ever written by AuthService after a new
/// successful code verification — never overwritten by a routine trial
/// check, and never overwritten with an unparseable value. ISO-8601 date
/// string (parsed with no timezone conversion — device-local, matching the
/// server). See TrialService.
const String kTrialEndTime = 'trial_end_time';
