import 'package:shared_preferences/shared_preferences.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';

final class LocalStorageUpdateService {
  const LocalStorageUpdateService._();

  static Future<void> clearOnEnvironmentChange(
    SharedPreferences preferences,
  ) async {
    const currentApiEnv = 'default';
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
        await preferences.setString(kLastUpdateTime, lastUpdateTime.toString());
        return;
      }

      final String? storedUpdateTime = preferences.getString(kLastUpdateTime);
      final String currentUpdateTime = lastUpdateTime.toString();

      if (storedUpdateTime == currentUpdateTime) {
        return;
      }

      await preferences.clear();
      await preferences.setString(kLastUpdateTime, currentUpdateTime);
    } catch (_) {
      // Fail silently — never crash the app on this check
    }
  }
}
