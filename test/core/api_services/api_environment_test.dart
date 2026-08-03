import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/api_services/api_environment.dart';
import 'package:waretrack_mini/core/api_services/base_api.dart';

/// The trial suffix is a naming contract, not a lookup table: `isTrial`,
/// build.gradle.kts, and the release scripts all derive trial-ness from it.
/// These tests lock that contract down so adding an environment pair can't
/// silently break trial detection for one of them.
void main() {
  final baseEnvironments = ApiEnvironment.values
      .where((env) => !env.isTrial)
      .toList();
  final trialEnvironments = ApiEnvironment.values
      .where((env) => env.isTrial)
      .toList();

  group('ApiEnvironment pairing', () {
    test('every base environment has a "<base>Trial" counterpart', () {
      for (final base in baseEnvironments) {
        expect(
          ApiEnvironment.values.map((env) => env.name),
          contains('${base.name}Trial'),
          reason: '${base.name} has no trial counterpart',
        );
      }
    });

    test('every trial environment is its base URL plus the /test route', () {
      for (final trial in trialEnvironments) {
        final base = ApiEnvironment.fromName(
          trial.name.substring(0, trial.name.length - 'Trial'.length),
        );
        expect(trial.baseUrl, '${base.baseUrl}/test');
      }
    });

    test('base and trial counts match, so no environment is unpaired', () {
      expect(trialEnvironments, hasLength(baseEnvironments.length));
    });
  });

  group('isTrial', () {
    test('is true for exactly the "Trial"-suffixed environments', () {
      for (final env in ApiEnvironment.values) {
        expect(
          env.isTrial,
          env.name.endsWith('Trial'),
          reason: '${env.name} reported the wrong trial status',
        );
      }
    });

    test('is false for every base environment', () {
      expect(
        baseEnvironments.map((env) => env.name),
        containsAll([
          'demo440',
          'demo395',
          'jarocClient',
          'jarocDemo',
          'jarocDev',
        ]),
      );
    });

    test('is true for every paired trial environment', () {
      expect(
        trialEnvironments.map((env) => env.name),
        containsAll([
          'demo440Trial',
          'demo395Trial',
          'jarocClientTrial',
          'jarocDemoTrial',
          'jarocDevTrial',
        ]),
      );
    });
  });

  group('fromName', () {
    test('resolves every --dart-define=API_ENV value the scripts pass', () {
      for (final env in ApiEnvironment.values) {
        expect(ApiEnvironment.fromName(env.name), env);
      }
    });

    test('falls back to demo440 for an unknown value', () {
      // A typo in a build script must not crash the app at startup.
      expect(ApiEnvironment.fromName('nope'), ApiEnvironment.demo440);
      expect(ApiEnvironment.fromName(''), ApiEnvironment.demo440);
      // 'trial' was the old standalone value; it is no longer an environment.
      expect(ApiEnvironment.fromName('trial'), ApiEnvironment.demo440);
    });
  });

  group('BaseApi.endpoint', () {
    test('builds every request URL from the selected environment baseUrl', () {
      // code-verify, device-verify and send-mail all go through this one
      // helper (see auth_service.dart / send_mail_service.dart), so proving it
      // here proves a trial APK hits its own /test route for all of them.
      for (final path in ['code-verify', 'device-verify', 'send-mail']) {
        expect(
          BaseApi.endpoint(path).toString(),
          '${BaseApi.current.baseUrl}/$path',
        );
      }
    });

    test('a trial environment resolves to its own /test endpoint', () {
      expect(
        '${ApiEnvironment.demo395Trial.baseUrl}/code-verify',
        'https://demo395.colgis.jp/api/test/code-verify',
      );
      expect(
        '${ApiEnvironment.jarocDevTrial.baseUrl}/device-verify',
        'https://handy-jaroc.dev.colgis.jp/api/test/device-verify',
      );
      // The matching base environment keeps its unsuffixed endpoint.
      expect(
        '${ApiEnvironment.demo395.baseUrl}/code-verify',
        'https://demo395.colgis.jp/api/code-verify',
      );
    });

    test('BaseApi mirrors the environment resolved from API_ENV', () {
      expect(BaseApi.current, ApiEnvironment.fromName(BaseApi.apiEnv));
      expect(BaseApi.isTrial, BaseApi.current.isTrial);
    });
  });
}
