import 'dart:io';

import 'package:android_id/android_id.dart';

final class DeviceInfoService {
  DeviceInfoService._();

  static const String retrievalErrorMessage = '端末IDの取得に失敗しました。\nもう一度お試しください。';

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
