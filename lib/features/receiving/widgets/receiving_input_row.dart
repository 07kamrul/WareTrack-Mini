import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';

class ReceivingInputRow extends StatelessWidget {
  const ReceivingInputRow({
    super.key,
    required this.controller,
    required this.label,
    required this.onSubmitted,
    this.keyboardType,
    this.enabled = true,
    this.trailing,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onSubmitted;
  final TextInputType? keyboardType;
  final bool enabled;
  final Widget? trailing;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        final field = TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmitted(),
          decoration: receivingInputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.document_scanner_outlined),
          ),
        );
        final scanButton = Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: 150,
            height: 56,
            child: FilledButton(
              onPressed: enabled ? onSubmitted : null,
              child: Text(l10n.confirmAction),
            ),
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: field),
              const SizedBox(width: 12),
              scanButton,
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            field,
            const SizedBox(height: 12),
            scanButton,
            if (trailing != null) ...[const SizedBox(height: 12), trailing!],
          ],
        );
      },
    );
  }
}

InputDecoration receivingInputDecoration({
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  bool isDense = false,
  EdgeInsetsGeometry? contentPadding,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    isDense: isDense,
    contentPadding: contentPadding,
  );
}
