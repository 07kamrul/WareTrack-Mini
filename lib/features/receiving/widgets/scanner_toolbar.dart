import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_state.dart';

class ScannerToolbar extends StatelessWidget {
  const ScannerToolbar({
    super.key,
    required this.activeMode,
    required this.enableScannerMode,
    required this.onModeChanged,
    required this.gap,
    required this.buttonHeight,
    required this.borderRadius,
  });

  final ScannerMode activeMode;
  final bool enableScannerMode;
  final ValueChanged<ScannerMode> onModeChanged;
  final double gap;
  final double buttonHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final buttons = <Widget>[
      ScannerModeButton(
        label: l10n.brQr,
        isSelected: activeMode == ScannerMode.brQr,
        onPressed: () => onModeChanged(ScannerMode.brQr),
        minHeight: buttonHeight,
        borderRadius: borderRadius,
      ),
      ScannerModeButton(
        label: l10n.ocr,
        isSelected: activeMode == ScannerMode.ocr,
        onPressed: () => onModeChanged(ScannerMode.ocr),
        minHeight: buttonHeight,
        borderRadius: borderRadius,
      ),
      if (enableScannerMode)
        ScannerModeButton(
          label: l10n.scanner,
          isSelected: activeMode == ScannerMode.scanner,
          onPressed: () => onModeChanged(ScannerMode.scanner),
          minHeight: buttonHeight,
          borderRadius: borderRadius,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactGap = constraints.maxWidth < 360
            ? gap.clamp(6.0, 8.0)
            : gap;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (index, button) in buttons.indexed) ...[
              if (index > 0) SizedBox(width: compactGap),
              Expanded(child: button),
            ],
          ],
        );
      },
    );
  }
}

class ScannerModeButton extends StatelessWidget {
  const ScannerModeButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
    required this.minHeight,
    required this.borderRadius,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final double minHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 96;
        final horizontalPadding = isCompact ? 8.0 : 16.0;
        final verticalPadding = isCompact ? 10.0 : 12.0;
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, minHeight),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            backgroundColor: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          onPressed: onPressed,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: textStyle?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontSize: isCompact ? (textStyle.fontSize ?? 14) - 1 : null,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}
