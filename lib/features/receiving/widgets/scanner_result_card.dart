import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_state.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_scan_button.dart';

class ScannerResultCard extends StatelessWidget {
  const ScannerResultCard({
    super.key,
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.onExternalInput,
    required this.sectionGap,
    required this.componentGap,
    required this.cardRadius,
    required this.innerRadius,
    required this.cardPadding,
    required this.inputHorizontalPadding,
    required this.inputVerticalPadding,
    required this.inputMaxLines,
    required this.searchButtonHeight,
  });

  final LiveScannerState state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onExternalInput;
  final double sectionGap;
  final double componentGap;
  final double cardRadius;
  final double innerRadius;
  final double cardPadding;
  final double inputHorizontalPadding;
  final double inputVerticalPadding;
  final int inputMaxLines;
  final double searchButtonHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.scanDetails,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: componentGap),
        _ScannerInfoCard(
          borderRadius: cardRadius,
          padding: cardPadding,
          child: _ScannerInputSection(
            state: state,
            controller: controller,
            focusNode: focusNode,
            onExternalInput: onExternalInput,
            componentGap: componentGap,
            innerRadius: innerRadius,
            inputHorizontalPadding: inputHorizontalPadding,
            inputVerticalPadding: inputVerticalPadding,
            inputMaxLines: inputMaxLines,
          ),
        ),
        SizedBox(height: sectionGap),
        _ScannerInfoCard(
          borderRadius: cardRadius,
          padding: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cardRadius),
            child: ScannerResultTable(merchandiseValue: state.merchandiseValue),
          ),
        ),
        SizedBox(height: sectionGap),
        Align(
          alignment: Alignment.center,
          child: ScannerScanButton(
            label: l10n.productSearch,
            onPressed: () {},
            borderRadius: innerRadius,
            minHeight: searchButtonHeight,
            expandHorizontally: false,
          ),
        ),
      ],
    );
  }
}

class ScannerResultTable extends StatelessWidget {
  const ScannerResultTable({super.key, required this.merchandiseValue});

  final String merchandiseValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final minTableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;

        return Scrollbar(
          thumbVisibility: false,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minTableWidth),
              child: Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: FlexColumnWidth(),
                },
                border: TableBorder.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
                children: [
                  _buildTableRow(context, l10n.shuttleName, ''),
                  _buildTableRow(context, l10n.shuttleGate, ''),
                  _buildTableRow(context, l10n.merchandise, merchandiseValue),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TableRow _buildTableRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return TableRow(
      decoration: BoxDecoration(color: colorScheme.surface),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            softWrap: true,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            value,
            softWrap: true,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}

class _ScannerInputSection extends StatelessWidget {
  const _ScannerInputSection({
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.onExternalInput,
    required this.componentGap,
    required this.innerRadius,
    required this.inputHorizontalPadding,
    required this.inputVerticalPadding,
    required this.inputMaxLines,
  });

  final LiveScannerState state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onExternalInput;
  final double componentGap;
  final double innerRadius;
  final double inputHorizontalPadding;
  final double inputVerticalPadding;
  final int inputMaxLines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${l10n.pleaseScan} ',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
              ),
              TextSpan(
                text: state.isBrQrMode
                    ? l10n.scanBarcodeQr
                    : state.isOcrMode
                    ? l10n.scanOcrText
                    : l10n.scanExternal,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: '.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
        SizedBox(height: componentGap),
        AbsorbPointer(
          absorbing: state.isModeSwitching,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: false,
            readOnly: false,
            showCursor: !state.isExternalScannerMode,
            enableInteractiveSelection: !state.isExternalScannerMode,
            keyboardType: state.isExternalScannerMode
                ? TextInputType.none
                : TextInputType.text,
            textInputAction: TextInputAction.done,
            onChanged: state.isExternalScannerMode ? onExternalInput : null,
            onTapOutside: (_) {
              if (!state.isExternalScannerMode) {
                focusNode.unfocus();
              }
            },
            minLines: 1,
            maxLines: inputMaxLines,
            decoration: InputDecoration(
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(innerRadius),
                borderSide: const BorderSide(color: Color(0xFFDEDFE0)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: inputHorizontalPadding,
                vertical: inputVerticalPadding,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerInfoCard extends StatelessWidget {
  const _ScannerInfoCard({
    required this.child,
    required this.borderRadius,
    required this.padding,
  });

  final Widget child;
  final double borderRadius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}
