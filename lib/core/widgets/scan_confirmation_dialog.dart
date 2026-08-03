import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/dialog_message_text.dart';

Future<bool> showScanConfirmationDialog(
  BuildContext context, {
  required String message,
  TextStyle? messageStyle,
  Color? cancelBackgroundColor,
  Color? cancelForegroundColor,
  Color? confirmBackgroundColor,
  Color? confirmForegroundColor,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogMessageText(
                message,
                fitOneLine: true,
                style: Theme.of(dialogContext).textTheme.titleMedium
                    ?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    )
                    .merge(messageStyle),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: cancelBackgroundColor == null
                          ? OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: colorScheme.primary,
                                side: BorderSide(color: colorScheme.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: Text(l10n.no),
                            )
                          : FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: cancelBackgroundColor,
                                foregroundColor:
                                    cancelForegroundColor ?? Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: Text(l10n.no),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              confirmBackgroundColor ?? colorScheme.primary,
                          foregroundColor:
                              confirmForegroundColor ?? Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(l10n.yes),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return confirmed == true;
}
