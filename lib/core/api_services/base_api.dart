import 'package:waretrack_mini/core/api_services/api_environment.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';

class BaseApi {
  /// Selected at build time: flutter build apk --dart-define=API_ENV=jarocClient
  static const String apiEnv = AppBuildConfig.apiEnv;

  /// The environment this APK was built for. [apiEnv] is the enum member name
  /// verbatim, so no per-environment switch is needed.
  static ApiEnvironment get current => AppBuildConfig.environment;

  /// True on every `<base>Trial` build, false on every base build.
  static bool get isTrial => current.isTrial;

  static Uri endpoint(String path) {
    return Uri.parse('${current.baseUrl}/$path');
  }
}
