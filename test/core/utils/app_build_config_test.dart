import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/utils/app_configure.dart';

void main() {
  test('appName defaults to WareTrack Mini', () {
    expect(AppBuildConfig.appName, 'WareTrack Mini');
  });

  test('displayName returns the provided name', () {
    expect(AppBuildConfig.displayName('WareTrack Mini'), 'WareTrack Mini');
  });

  test('displayName forwards custom names unchanged', () {
    expect(AppBuildConfig.displayName('My Custom App'), 'My Custom App');
  });
}
