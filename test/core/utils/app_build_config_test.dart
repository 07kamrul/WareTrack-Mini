import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';

void main() {
  test('sends the server-registered app name and version to the API', () {
    expect(AppBuildConfig.apiPayload, {
      'name': AppBuildConfig.apiPayloadName,
      'version': AppBuildConfig.appVersion,
      // The server identifies which environment the request came from, and a
      // trial build must report its own /test base URL — never the base
      // environment's. Derived straight from ApiEnvironment.baseUrl.
      'server_name': AppBuildConfig.environment.baseUrl,
    });
    // The API matches the version string exactly; the registered value
    // contains a space ('Ver 1.0').
    expect(AppBuildConfig.appVersion, 'Ver 1.0');
  });

  test('resolves API_ENV to an environment whose trial status agrees', () {
    // apiEnv is the ApiEnvironment member name verbatim, so the two must
    // never disagree — isTrial is the only sanctioned trial test.
    expect(AppBuildConfig.environment.name, AppBuildConfig.apiEnv);
    expect(AppBuildConfig.isTrial, AppBuildConfig.apiEnv.endsWith('Trial'));
  });

  // Regression guard: the release scripts always pass a non-empty APP_NAME
  // (標準 or カスタマイズ1) even for a trial API_ENV (see build_apk.sh /
  // build_all_apks.sh), so apiPayloadName can't just forward appName as-is —
  // it must prefix "Trial" itself on every trial build, regardless of which
  // APP_NAME this test run was compiled with.
  test(
    'apiPayloadName prefixes "Trial" onto appName only on a trial build',
    () {
      if (AppBuildConfig.isTrial) {
        expect(AppBuildConfig.apiPayloadName, 'Trial${AppBuildConfig.appName}');
      } else {
        expect(AppBuildConfig.apiPayloadName, AppBuildConfig.appName);
      }
    },
  );

  test('generates dated APK file name from app configuration', () {
    final now = DateTime.now();
    final expectedToday =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    expect(AppBuildConfig.today, expectedToday);
    // The name portion carries the "Trial" prefix on a trial build, matching
    // appBuildApkFileName in android/app/build.gradle.kts — which is what
    // actually names the file — so a trial APK never collides with its base
    // counterpart in a file listing.
    expect(
      AppBuildConfig.apkFileName,
      '${expectedToday}_${AppBuildConfig.apiEnv}_${AppBuildConfig.apiPayloadName}_${AppBuildConfig.appVersion}.apk',
    );
  });

  // Regression guard for the release-build bug where the "WareTrack Mini Trial"
  // label never appeared: displayName() must key off the environment alone.
  // The release script always passes a non-empty APP_NAME (標準 or
  // カスタマイズ1) even for a trial API_ENV, so if APP_NAME ever took priority
  // over isTrial here, every trial release APK would silently show plain
  // "WareTrack Mini" — exactly the bug this test locks out.
  //
  // apiEnv/appName are compile-time consts, so the trial branch only
  // exercises when run as:
  //   flutter test --dart-define=API_ENV=demo440Trial --dart-define=APP_NAME=標準
  //   flutter test --dart-define=API_ENV=demo395Trial --dart-define=APP_NAME=カスタマイズ1
  // A plain `flutter test` (non-trial default) still asserts the non-trial
  // branch below, so this file stays green either way.
  test('displayName appends " Trial" only on a trial build, regardless of '
      'APP_NAME', () {
    if (AppBuildConfig.isTrial) {
      expect(AppBuildConfig.displayName('WareTrack Mini'), 'WareTrack Mini Trial');
    } else {
      expect(AppBuildConfig.displayName('WareTrack Mini'), 'WareTrack Mini');
    }
    // appName is always non-empty in the real release-build matrix
    // (build_all_apks.sh always passes 標準 or カスタマイズ1) — assert that
    // fact holds here too, so this test would fail loudly if a future
    // change ever made appName empty and masked the regression it guards.
    expect(AppBuildConfig.appName, isNotEmpty);
  });
}
