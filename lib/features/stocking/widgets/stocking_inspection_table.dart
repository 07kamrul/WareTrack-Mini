import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';

/// Inspection table for Shelf Placement (Shelf Storage).
///
/// Shows columns: Correct | Shelf Number | Barcode/QR | Inspection Quantity
/// The "slip number" field in [ReceivingInspectionItem] holds the shelf number.
class StockingInspectionTable extends StatelessWidget {
  const StockingInspectionTable({
    super.key,
    required this.items,
    required this.selectedItemId,
    this.onReset,
    this.showResetColumn = false,
  });

  final List<ReceivingInspectionItem> items;
  final String? selectedItemId;
  final ValueChanged<ReceivingInspectionItem>? onReset;
  final bool showResetColumn;

  static const _columnWidthsWithReset = <int, TableColumnWidth>{
    0: FlexColumnWidth(0.9),
    1: FlexColumnWidth(1.05),
    2: FlexColumnWidth(2.6),
    3: FlexColumnWidth(1.0),
  };

  static const _columnWidthsWithoutReset = <int, TableColumnWidth>{
    0: FlexColumnWidth(1.05),
    1: FlexColumnWidth(2.6),
    2: FlexColumnWidth(1.0),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant;
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _ResponsiveTableMetrics.fromWidth(constraints.maxWidth);

        return Column(
          children: [
            Table(
              border: TableBorder.all(color: borderColor),
              columnWidths: showResetColumn
                  ? _columnWidthsWithReset
                  : _columnWidthsWithoutReset,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(color: theme.colorScheme.primary),
                  children: [
                    if (showResetColumn)
                      _HeaderCell(label: l10n.inspectionReset, metrics: metrics),
                    _HeaderCell(label: l10n.shelfNumberLabel, metrics: metrics),
                    _HeaderCell(label: l10n.barcodeQr, metrics: metrics),
                    _HeaderCell(label: l10n.inspectionQuantity, metrics: metrics),
                  ],
                ),
                for (final item in items)
                  TableRow(
                    decoration: BoxDecoration(
                      color: item.id == selectedItemId
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.35,
                            )
                          : theme.colorScheme.surface,
                    ),
                    children: [
                      if (showResetColumn)
                        _ActionCell(
                          selected: false,
                          onPressed: () => onReset?.call(item),
                          label: l10n.select,
                          metrics: metrics,
                          backgroundColor: const Color(0xFF006D77),
                        ),
                      // slipNumber stores the shelf number in stocking context
                      _BodyCell(label: item.slipNumber, metrics: metrics),
                      _BodyCell(label: item.barcode, metrics: metrics),
                      _BodyCell(
                        label: item.barcode.isEmpty
                            ? ''
                            : '${item.inspectedQuantity}',
                        metrics: metrics,
                      ),
                    ],
                  ),
              ],
            ),
            if (items.isEmpty)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    left: BorderSide(color: borderColor),
                    right: BorderSide(color: borderColor),
                    bottom: BorderSide(color: borderColor),
                  ),
                ),
                child: _EmptyCell(label: l10n.noInspectionData),
              ),
          ],
        );
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, required this.metrics});

  final String label;
  final _ResponsiveTableMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: metrics.headerHeight),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: metrics.cellPadding,
        vertical: metrics.cellPadding,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        softWrap: true,
        overflow: TextOverflow.visible,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: metrics.fontSize,
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({required this.label, required this.metrics});

  final String label;
  final _ResponsiveTableMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: metrics.rowHeight),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: metrics.cellPadding,
        vertical: metrics.cellPadding,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        softWrap: true,
        overflow: TextOverflow.visible,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: metrics.fontSize,
          height: 1.15,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({
    required this.selected,
    required this.onPressed,
    required this.label,
    required this.metrics,
    this.backgroundColor,
  });

  final bool selected;
  final VoidCallback onPressed;
  final String label;
  final _ResponsiveTableMetrics metrics;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: metrics.rowHeight),
      alignment: Alignment.center,
      padding: EdgeInsets.all(metrics.cellPadding),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(0, metrics.actionHeight),
          padding: EdgeInsets.symmetric(horizontal: metrics.cellPadding),
          backgroundColor:
              backgroundColor ?? Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          side: selected
              ? BorderSide(color: Theme.of(context).colorScheme.secondary)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontSize: metrics.fontSize,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ResponsiveTableMetrics {
  const _ResponsiveTableMetrics({
    required this.headerHeight,
    required this.rowHeight,
    required this.actionHeight,
    required this.cellPadding,
    required this.fontSize,
  });

  final double headerHeight;
  final double rowHeight;
  final double actionHeight;
  final double cellPadding;
  final double fontSize;

  factory _ResponsiveTableMetrics.fromWidth(double width) {
    final normalizedWidth = width.isFinite ? width : 420.0;

    if (normalizedWidth < 340) {
      return const _ResponsiveTableMetrics(
        headerHeight: 42,
        rowHeight: 44,
        actionHeight: 32,
        cellPadding: 2,
        fontSize: 11,
      );
    }

    if (normalizedWidth < 420) {
      return const _ResponsiveTableMetrics(
        headerHeight: 44,
        rowHeight: 46,
        actionHeight: 34,
        cellPadding: 3,
        fontSize: 12,
      );
    }

    return const _ResponsiveTableMetrics(
      headerHeight: 48,
      rowHeight: 50,
      actionHeight: 36,
      cellPadding: 4,
      fontSize: 13,
    );
  }
}
