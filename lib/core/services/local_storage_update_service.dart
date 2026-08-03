import 'package:shared_preferences/shared_preferences.dart';
import 'package:waretrack_mini/core/api_services/base_api.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';

final class LocalStorageUpdateService {
  const LocalStorageUpdateService._();

  /// Every environment APK shares the same applicationId, so SharedPreferences
  /// written by one environment's APK survive when another environment's APK
  /// is installed over it. Data cached for a different API environment must
  /// never be trusted, so clear everything when the stamp does not match this
  /// build's environment (or is missing while other data exists).
  static Future<void> clearOnEnvironmentChange(
    SharedPreferences preferences, {
    String currentApiEnv = BaseApi.apiEnv,
  }) async {
    final storedEnv = preferences.getString(kApiEnv);
    if (storedEnv == currentApiEnv) return;

    final lastUpdateTime = preferences.getString(kLastUpdateTime);
    await preferences.clear();
    if (lastUpdateTime != null) {
      await preferences.setString(kLastUpdateTime, lastUpdateTime);
    }
    await preferences.setString(kApiEnv, currentApiEnv);
  }

  static Future<void> clearAfterAppUpdate(
    SharedPreferences preferences,
  ) async {
    try {
      final Map result = await kPackageInfoChannel.invokeMethod('getInstallTimes');
      final int firstInstallTime = result['firstInstallTime'] as int;
      final int lastUpdateTime = result['lastUpdateTime'] as int;

      if (firstInstallTime == lastUpdateTime) {
        // Fresh install — Android shows "Install" dialog
        await preferences.setString(kLastUpdateTime, lastUpdateTime.toString());
        return;
      }

      // App has been updated at some point — Android showed "Update" dialog
      final String? storedUpdateTime = preferences.getString(kLastUpdateTime);
      final String currentUpdateTime = lastUpdateTime.toString();

      if (storedUpdateTime == currentUpdateTime) {
        // Already cleared for this update — normal relaunch
        return;
      }

      // New update detected — clear SharedPreferences, preserve SQLite
      await preferences.clear();
      await preferences.setString(kLastUpdateTime, currentUpdateTime);
    } catch (_) {
      // Fail silently — never crash the app on this check
    }
  }
}
