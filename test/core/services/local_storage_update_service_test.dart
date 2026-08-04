import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/services/local_storage_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void mockInstallTimes({
    required int firstInstallTime,
    required int lastUpdateTime,
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kPackageInfoChannel, (call) async {
          if (call.method == 'getInstallTimes') {
            return <String, int>{
              'firstInstallTime': firstInstallTime,
              'lastUpdateTime': lastUpdateTime,
            };
          }
          return null;
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kPackageInfoChannel, null);
  });

  group('clearAfterAppUpdate', () {
    test('clears local storage once when the app is updated', () async {
      mockInstallTimes(firstInstallTime: 100, lastUpdateTime: 200);
      SharedPreferences.setMockInitialValues({
        kLastUpdateTime: '100',
        'cached_setting': 'value',
      });
      final preferences = await SharedPreferences.getInstance();

      await LocalStorageUpdateService.clearAfterAppUpdate(preferences);

      expect(preferences.getString('cached_setting'), isNull);
      expect(preferences.getString(kLastUpdateTime), '200');
    });

    test('keeps local storage on a normal relaunch', () async {
      mockInstallTimes(firstInstallTime: 100, lastUpdateTime: 200);
      SharedPreferences.setMockInitialValues({
        kLastUpdateTime: '200',
        'cached_setting': 'value',
      });
      final preferences = await SharedPreferences.getInstance();

      await LocalStorageUpdateService.clearAfterAppUpdate(preferences);

      expect(preferences.getString('cached_setting'), 'value');
    });

    test('initializes the update marker on a fresh install', () async {
      mockInstallTimes(firstInstallTime: 100, lastUpdateTime: 100);
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await LocalStorageUpdateService.clearAfterAppUpdate(preferences);

      expect(preferences.getString(kLastUpdateTime), '100');
    });
  });

  group('clearOnEnvironmentChange', () {
    test('clears unstamped data', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await LocalStorageUpdateService.clearOnEnvironmentChange(preferences);

      expect(preferences.getString(kApiEnv), 'default');
    });

    test('keeps data when already stamped', () async {
      SharedPreferences.setMockInitialValues({
        kApiEnv: 'default',
        kLastUpdateTime: '100',
      });
      final preferences = await SharedPreferences.getInstance();

      await LocalStorageUpdateService.clearOnEnvironmentChange(preferences);

      expect(preferences.getString(kLastUpdateTime), '100');
    });
  });
}
