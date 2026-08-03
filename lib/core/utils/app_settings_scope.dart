import 'package:flutter/widgets.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
