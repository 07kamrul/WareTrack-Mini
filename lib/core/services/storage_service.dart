import 'package:waretrack_mini/core/services/scan_feedback_service.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LocalStorage {
  Future<bool?> readBool(String key);
  Future<String?> readString(String key);
  Future<void> writeBool(String key, bool value);
  Future<void> writeString(String key, String value);
  Future<void> remove(String key);
}

extension VerificationLocalStorage on LocalStorage {
  Future<void> clearVerificationData() async {
    await remove(kIsVerified);
    await remove(kVerificationCode);
    await remove(kDeviceUuid);
    await remove(kDeviceVerificationResponse);
    await remove(kDeviceVerificationData);
    await remove(kCodeVerifyResponseJson);
    await remove(kAuthUserData);
    await remove(kCompanyId);
    await remove(kCode);
    await remove(kDatachar01);
    await remove(kDatachar02);
    await remove(kAppName);
    await remove(kAppVersion);
    await remove(kAccesscode);
  }
}

final class InMemoryLocalStorage implements LocalStorage {
  InMemoryLocalStorage({ScanFeedbackService? feedbackService})
    : _feedbackService = feedbackService;

  final Map<String, String> _cache = <String, String>{};
  final ScanFeedbackService? _feedbackService;

  @override
  Future<bool?> readBool(String key) async {
    final value = _cache[key];
    return value == null ? null : bool.tryParse(value);
  }

  @override
  Future<String?> readString(String key) async => _cache[key];

  @override
  Future<void> writeBool(String key, bool value) async {
    _cache[key] = value.toString();
    await _feedbackService?.playDatabaseSuccess();
  }

  @override
  Future<void> writeString(String key, String value) async {
    _cache[key] = value;
    await _feedbackService?.playDatabaseSuccess();
  }

  @override
  Future<void> remove(String key) async {
    _cache.remove(key);
  }
}

final class SharedPreferencesLocalStorage implements LocalStorage {
  const SharedPreferencesLocalStorage(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<bool?> readBool(String key) async => _preferences.getBool(key);

  @override
  Future<String?> readString(String key) async => _preferences.getString(key);

  @override
  Future<void> writeBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  @override
  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}
