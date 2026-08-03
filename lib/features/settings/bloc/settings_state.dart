import 'package:waretrack_mini/core/utils/app_settings.dart';

final class SettingsState {
  const SettingsState({required this.settings});

  final AppSettings settings;

  SettingsState copyWith({AppSettings? settings}) {
    return SettingsState(settings: settings ?? this.settings);
  }

  bool get hasValidEmail {
    final value = settings.transfer.emailAddress.trim();
    if (value.isEmpty) {
      return true;
    }

    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  bool get hasValidUploadUrl {
    final value = settings.transfer.uploadUrl.trim();
    if (value.isEmpty) {
      return true;
    }

    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
