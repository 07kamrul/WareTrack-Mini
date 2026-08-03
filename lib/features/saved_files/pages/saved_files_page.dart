import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/services/completed_work_service.dart';
import 'package:waretrack_mini/core/models/completed_work_models.dart';
import 'package:waretrack_mini/core/models/inspection_work_type.dart';
import 'package:waretrack_mini/core/widgets/primary_app_bar.dart';
import 'package:waretrack_mini/core/widgets/scan_confirmation_dialog.dart';
import 'package:waretrack_mini/core/widgets/validation_error_dialog.dart';
import 'package:waretrack_mini/features/main_menu/widgets/menu_item.dart';
import 'package:waretrack_mini/features/receiving/bloc/receiving_bloc.dart';
import 'package:waretrack_mini/features/receiving/pages/receiving_selection_page.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/features/shipping/pages/shipping_selection_page.dart';
import 'package:waretrack_mini/features/shipping/services/shipping_service.dart';

@immutable
final class SavedFilesArguments {
  const SavedFilesArguments({required this.action, this.title});

  final MainMenuAction action;
  final String? title;
}

class SavedFilesPage extends StatefulWidget {
  const SavedFilesPage({super.key, required this.arguments});

  final SavedFilesArguments arguments;

  @override
  State<SavedFilesPage> createState() => _SavedFilesPageState();
}

class _SavedFilesPageState extends State<SavedFilesPage> {
  late final CompletedWorkService _completedWorkService;
  late final ShippingService? _shippingService;
  late Future<List<CompletedOrderRecord>> _worksFuture;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _completedWorkService = sl<CompletedWorkService>();
    _shippingService = sl.isRegistered<ShippingService>()
        ? sl<ShippingService>()
        : null;
    _worksFuture = _loadAllCompletedWorks();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.arguments.action != MainMenuAction.receiving &&
        widget.arguments.action != MainMenuAction.savedFiles) {
      return _SavedFilesScaffold(
        title:
            widget.arguments.title ??
            AppLocalizations.of(context).savedFileList,
        child: const _EmptySavedFilesList(),
      );
    }

    return _SavedFilesScaffold(
      title:
          widget.arguments.title ?? AppLocalizations.of(context).savedFileList,
      child: FutureBuilder<List<CompletedOrderRecord>>(
        future: _worksFuture,
        builder: (context, snapshot) {
          final works = snapshot.data ?? const <CompletedOrderRecord>[];

          return _SavedReceivingFilesList(
            works: works,
            isLoading: snapshot.connectionState != ConnectionState.done,
            onView: (work) => _openReceivingDetail(context, work),
            onDelete: (work) => _confirmAndDelete(context, work),
            onSend: (work) => _send(work),
          );
        },
      ),
    );
  }

  Future<List<CompletedOrderRecord>> _loadAllCompletedWorks() async {
    return _completedWorkService.loadAllCompletedWorks();
  }

  void _openReceivingDetail(BuildContext context, CompletedOrderRecord work) {
    if (_usesShelfStorage(work.workType)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _SavedStockingDetailPage(
            work: work,
            completedWorkService: _completedWorkService,
          ),
        ),
      );
      return;
    }

    final isShipping = work.workType == InspectionWorkType.shipping;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) =>
              isShipping ? createShippingBloc() : sl<ReceivingBloc>(),
          child: ReceivingBarcodeInspectionPage(
            slipNumber: work.slipNumber,
            readOnly: true,
            loadSavedWork: true,
            titleBuilder: isShipping ? shippingTitle : null,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    CompletedOrderRecord work,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showScanConfirmationDialog(
      context,
      message: l10n.deleteSavedFileConfirmation,
      messageStyle: const TextStyle(color: Colors.red),
      cancelBackgroundColor: const Color(0xFFF1D4B3),
      cancelForegroundColor: Colors.black,
      confirmBackgroundColor: Colors.red,
      confirmForegroundColor: Colors.white,
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await _completedWorkService.deleteCompletedWork(
      work.workType,
      work.slipNumber,
    );
    if (!context.mounted) {
      return;
    }
    setState(() {
      _worksFuture = _loadAllCompletedWorks();
    });
  }

  Future<void> _send(CompletedOrderRecord work) async {
    if (_isSending) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final isShipping = work.workType == InspectionWorkType.shipping;

    if (isShipping && _shippingService == null) {
      return;
    }

    setState(() => _isSending = true);
    _showSendingDialog();

    String resultMessage;
    var success = false;
    try {
      final result = await _completedWorkService.exportCompletedWork(
        menuType: work.workType,
        slipNumber: work.slipNumber,
        completedAt: work.completedAt,
      );
      await _completedWorkService.markWorkSent(
        work.workType,
        work.slipNumber,
      );
      resultMessage = '${l10n.sendMailSuccess} (${result.filePath})';
      success = true;
    } catch (error) {
      resultMessage = l10n.workSendFailed;
    } finally {
      _dismissSendingDialog();
      if (mounted) {
        setState(() => _isSending = false);
      }
    }

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        _worksFuture = _loadAllCompletedWorks();
      });
    }

    showValidationErrorDialog(context, resultMessage);
  }

  /// Shows a centered, blocking loading dialog that cannot be dismissed by an
  /// outside tap or the system back button while the Send request runs.
  void _showSendingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _dismissSendingDialog() {
    if (!mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class _SavedStockingDetailPage extends StatefulWidget {
  const _SavedStockingDetailPage({
    required this.work,
    required this.completedWorkService,
  });

  final CompletedOrderRecord work;
  final CompletedWorkService completedWorkService;

  @override
  State<_SavedStockingDetailPage> createState() =>
      _SavedStockingDetailPageState();
}

class _SavedStockingDetailPageState extends State<_SavedStockingDetailPage> {
  late final Future<List<CompletedItemRecord>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = widget.completedWorkService.getCompletedWorkDetails(
      widget.work.workType,
      widget.work.slipNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar title = last shelf number (slipNumber of the work record)
      appBar: PrimaryAppBar(title: widget.work.slipNumber),
      body: SafeArea(
        child: FutureBuilder<List<CompletedItemRecord>>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final details = snapshot.data ?? const [];
            if (details.isEmpty) {
              return const _EmptySavedFilesList();
            }

            return _StockingDetailBody(details: details);
          },
        ),
      ),
    );
  }
}

class _StockingDetailBody extends StatelessWidget {
  const _StockingDetailBody({required this.details});

  final List<CompletedItemRecord> details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.outlineVariant;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                color: Colors.indigo.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.inspectionList,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: borderColor),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(1.05),
              1: FlexColumnWidth(2.6),
              2: FlexColumnWidth(1.0),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: colorScheme.primary),
                children: [
                  _SavedTableHeaderCell(l10n.shelfNumberLabel),
                  _SavedTableHeaderCell(l10n.barcodeQr),
                  _SavedTableHeaderCell(l10n.inspectionQuantity),
                ],
              ),
              for (final detail in details)
                TableRow(
                  decoration: BoxDecoration(color: colorScheme.surface),
                  children: [
                    _SavedTableBodyCell(detail.slipNumber),
                    _SavedTableBodyCell(detail.code),
                    _SavedTableBodyCell('${detail.quantity}'),
                  ],
                ),
            ],
          ),
          if (details.isEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  left: BorderSide(color: borderColor),
                  right: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              child: const _EmptySavedFilesList(),
            ),
        ],
      ),
    );
  }
}

class _SavedTableHeaderCell extends StatelessWidget {
  const _SavedTableHeaderCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SavedTableBodyCell extends StatelessWidget {
  const _SavedTableBodyCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.15,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SavedFilesScaffold extends StatelessWidget {
  const _SavedFilesScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(title: title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedReceivingFilesList extends StatelessWidget {
  const _SavedReceivingFilesList({
    required this.works,
    required this.isLoading,
    required this.onView,
    required this.onDelete,
    required this.onSend,
  });

  final List<CompletedOrderRecord> works;
  final bool isLoading;
  final ValueChanged<CompletedOrderRecord> onView;
  final ValueChanged<CompletedOrderRecord> onDelete;
  final ValueChanged<CompletedOrderRecord> onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.assignment_turned_in_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.savedWorkList,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading) const LinearProgressIndicator(),
        if (isLoading) const SizedBox(height: 12),
        for (final work in works) ...[
          _SavedWorkCard(
            fileName: _usesShelfStorage(work.workType)
                ? work.slipNumber
                : '${work.menuName}${work.slipNumber}',
            savedDate: _formatSavedDate(work.completedAt),
            isSent: work.isSent,
            onView: () => onView(work),
            onSend: () => onSend(work),
            onDelete: () => onDelete(work),
          ),
          const SizedBox(height: 10),
        ],
        if (!isLoading && works.isEmpty)
          Card(
            child: _EmptySavedFilesList(
              padding: const EdgeInsets.symmetric(vertical: 32),
            ),
          ),
      ],
    );
  }
}

class _SavedWorkCard extends StatelessWidget {
  const _SavedWorkCard({
    required this.fileName,
    required this.savedDate,
    required this.isSent,
    required this.onView,
    required this.onSend,
    required this.onDelete,
  });

  final String fileName;
  final String savedDate;
  final bool isSent;
  final VoidCallback onView;
  final VoidCallback onSend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    fileName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (isSent) ...[
                  const SizedBox(width: 8),
                  const _SentStatusIcon(),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              savedDate,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: onView,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(l10n.view),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                      ),
                      onPressed: onDelete,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(l10n.deleteAction),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FilledButton(
                      onPressed: onSend,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(l10n.send),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small "sent" status indicator shown above the Send button once an order has
/// been successfully sent. Uses a green check circle rather than any text.
class _SentStatusIcon extends StatelessWidget {
  const _SentStatusIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.check_circle,
      color: Color(0xFF2E7D32),
      size: 20,
    );
  }
}

String _formatSavedDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}:'
      '${local.second.toString().padLeft(2, '0')}';
}

bool _usesShelfStorage(InspectionWorkType workType) {
  return workType == InspectionWorkType.stocking ||
      workType == InspectionWorkType.inventory;
}

class _EmptySavedFilesList extends StatelessWidget {
  const _EmptySavedFilesList({this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          AppLocalizations.of(context).noInspectionData,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
