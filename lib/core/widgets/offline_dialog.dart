import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/validation_error_dialog.dart';

void showOfflineDialog(BuildContext context) {
  showValidationErrorDialog(
    context,
    AppLocalizations.of(context).offlineMessage,
  );
}
