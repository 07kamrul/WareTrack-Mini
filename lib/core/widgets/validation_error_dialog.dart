import 'dart:async';

import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/dialog_message_text.dart';

bool _isValidationErrorDialogVisible = false;

void showValidationErrorDialog(
  BuildContext context,
  String message, {
  String? title,
}) {
  if (_isValidationErrorDialogVisible) {
    return;
  }

  _isValidationErrorDialogVisible = true;
  unawaited(
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          // Widen the dialog so clauses have room to stay on one line instead
          // of being forced to wrap awkwardly.
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          title: title == null ? null : DialogMessageText(title),
          content: DialogMessageText(message),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(dialogContext).closeAction),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _isValidationErrorDialogVisible = false;
    }),
  );
}
