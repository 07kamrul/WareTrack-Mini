import 'package:flutter/material.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';

class ReceivingFilterControl extends StatelessWidget {
  const ReceivingFilterControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ReceivingInspectionFilter value;
  final ValueChanged<ReceivingInspectionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        _FilterRadio(
          label: l10n.hide,
          value: ReceivingInspectionFilter.hide,
          groupValue: value,
          onChanged: onChanged,
        ),
        _FilterRadio(
          label: l10n.slipOnly,
          value: ReceivingInspectionFilter.slipOnly,
          groupValue: value,
          onChanged: onChanged,
        ),
        _FilterRadio(
          label: l10n.all,
          value: ReceivingInspectionFilter.all,
          groupValue: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FilterRadio extends StatelessWidget {
  const _FilterRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final ReceivingInspectionFilter value;
  final ReceivingInspectionFilter groupValue;
  final ValueChanged<ReceivingInspectionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = value == groupValue;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
