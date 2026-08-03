import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';

final class DeviceInfoService {
  DeviceInfoService._();

  static String get retrievalErrorMessage => _currentLanguage.localizations
      .deviceIdRetrievalFailed;

  static AppLanguage get _currentLanguage => sl.isRegistered<AppSettingsController>()
      ? sl<AppSettingsController>().settings.language
      : AppLanguage.english;

  static String? _deviceUuid;

  static Future<String> getAndroidId() async {
    final deviceUuid = _deviceUuid;
    if (deviceUuid != null) {
      return deviceUuid;
    }

    if (!Platform.isAndroid) {
      throw Exception(retrievalErrorMessage);
    }

    try {
      final androidId = (await const AndroidId().getId())?.trim();
      if (androidId == null || androidId.isEmpty) {
        throw Exception(retrievalErrorMessage);
      }

      _deviceUuid = androidId;
      return androidId;
    } catch (_) {
      throw Exception(retrievalErrorMessage);
    }
  }
}
