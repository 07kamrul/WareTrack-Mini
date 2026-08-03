import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/scan_confirmation_dialog.dart';

/// Shared confirmation popup shown when the user tries to leave a scan/
/// inspection screen with unsaved work (via the app back button or the
/// Android system back gesture).
///
/// Returns `true` when the user chooses はい and `false` for いいえ or if the
/// dialog is dismissed.
Future<bool> showUnsavedFileConfirmationDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  return showScanConfirmationDialog(
    context,
    message: l10n.unsavedFileBackConfirmation,
  );
}
