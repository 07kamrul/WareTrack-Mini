import 'package:waretrack_mini/core/api_services/api_environment.dart';

class AppBuildConfig {
  /// Selected at build time via --dart-define. The value is an
  /// [ApiEnvironment] member name verbatim (`demo440`, `demo440Trial`, ...).
  /// Defaults are the 標準 build against demo440. Single source of truth —
  /// BaseApi.apiEnv reads this.
  static const String apiEnv = String.fromEnvironment(
    'API_ENV',
    defaultValue: 'demo440',
  );

  /// [apiEnv] resolved to the environment whose baseUrl every API call uses.
  static ApiEnvironment get environment => ApiEnvironment.fromName(apiEnv);

  /// True on every Trial build — that is, on every `<base>Trial` environment,
  /// each of which points at its own base URL plus the server's `/test` route.
  /// This is the single test for "is this a trial build"; never compare
  /// [apiEnv] against a literal environment name.
  static bool get isTrial => environment.isTrial;

  /// Sent to the code-verify API and must match the version registered
  /// server-side ('Ver 1.0', with a space — the value used before the
  /// per-environment build split).
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'Ver 1.0',
  );

  /// 標準 or カスタマイズ1 — selected per build via --dart-define=APP_NAME=...
  /// Always a bare (non-Trial-prefixed) value: the release scripts pass this
  /// explicitly even for the trial build (see build_apk.sh /
  /// build_all_apks.sh), so it can never encode trial-ness itself. Use
  /// [apiPayloadName] wherever the trial build must be distinguished.
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: '標準',
  );

  /// [appName] prefixed with "Trial" on a trial build, unchanged otherwise.
  /// Mirrors appBuildApkDisplayName in android/app/build.gradle.kts so the
  /// server receives 'Trial標準'/'Trialカスタマイズ1' instead of the bare
  /// build-script APP_NAME on every trial environment.
  static String get apiPayloadName => isTrial ? 'Trial$appName' : appName;

  static Map<String, String> get apiPayload => {
    'name': apiPayloadName,
    'version': appVersion,
    'server_name': environment.baseUrl,
  };

  /// Appends " Trial" to [baseName] on a trial build, unchanged otherwise.
  ///
  /// Mirrors the native launcher name split in
  /// android/app/build.gradle.kts ("WareTrack Mini Trial" vs "WareTrack Mini") so
  /// every in-app display of the app name — splash title, app bar,
  /// approval-code screen — stays consistent with what the OS shows for
  /// this build.
  static String displayName(String baseName) =>
      isTrial ? '$baseName Trial' : baseName;

  static String get today {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year$month$day';
  }

  /// Mirrors appBuildApkFileName in android/app/build.gradle.kts, which is what
  /// actually names the release APK. The name portion carries the same "Trial"
  /// prefix as [apiPayloadName] so a trial APK is distinguishable from its base
  /// counterpart in a file listing.
  static String get apkFileName =>
      '${today}_${apiEnv}_${apiPayloadName}_$appVersion.apk';
}
