import 'package:flutter/material.dart';

class ScannerScanButton extends StatelessWidget {
  const ScannerScanButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.borderRadius,
    required this.minHeight,
    this.expandHorizontally = true,
    this.minWidth,
    this.horizontalPadding = 12,
    this.verticalPadding = 10,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final double borderRadius;
  final double minHeight;
  final bool expandHorizontally;
  final double? minWidth;
  final double horizontalPadding;
  final double verticalPadding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: Size(
          expandHorizontally ? double.infinity : minWidth ?? 0,
          minHeight,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontSize: fontSize,
          height: 1.5,
        ),
      ),
    );
  }
}
