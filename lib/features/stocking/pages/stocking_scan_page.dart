import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waretrack_mini/core/utils/allowed_input.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/data/models/scanner_option.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/primary_app_bar.dart';
import 'package:waretrack_mini/core/widgets/scan_confirmation_dialog.dart';
import 'package:waretrack_mini/core/widgets/validation_error_dialog.dart';
import 'package:waretrack_mini/core/widgets/unsaved_file_dialog.dart';
import 'package:waretrack_mini/features/receiving/widgets/live_scanner_section.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_layout_metrics.dart';
import 'package:waretrack_mini/features/stocking/bloc/stocking_bloc.dart';
import 'package:waretrack_mini/features/stocking/bloc/stocking_event.dart';
import 'package:waretrack_mini/features/stocking/bloc/stocking_state.dart';
import 'package:waretrack_mini/features/stocking/widgets/stocking_inspection_table.dart';

/// Shelf Placement (Shelf Storage) scan screen.
///
/// Pure UI layer — dispatches [StockingEvent]s and renders [StockingState].
/// All business logic lives in [StockingBloc].
class StockingScanPage extends StatefulWidget {
  const StockingScanPage({
    super.key,
    this.titleBuilder,
    this.blocFactory,
    this.scannerOption = _stockingScannerOption,
  });

  final String Function(AppLocalizations localizations)? titleBuilder;
  final StockingBloc Function()? blocFactory;
  final ScannerOption scannerOption;

  @override
  State<StockingScanPage> createState() => _StockingScanPageState();
}

class _StockingScanPageState extends State<StockingScanPage> {
  late final TextEditingController _barcodeController;
  late final TextEditingController _quantityController;
  late final FocusNode _barcodeFocusNode;
  late final FocusNode _quantityFocusNode;
  String _lastSyncedBarcode = '';
  String _lastSyncedQuantity = '1';
  int _lastClearInputToken = 0;
  int _lastShownErrorToken = 0;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    _barcodeFocusNode = FocusNode();
    _quantityFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _barcodeFocusNode.unfocus();
    _quantityFocusNode.unfocus();
    _quantityFocusNode.dispose();
    _barcodeFocusNode.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final factory = widget.blocFactory;
        assert(
          factory != null,
          'StockingScanPage: blocFactory must be provided',
        );
        return factory!()..add(const StockingSessionStarted());
      },
      child: BlocConsumer<StockingBloc, StockingState>(
        listenWhen: _shouldHandleSideEffect,
        listener: _handleSideEffect,
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final title = widget.titleBuilder?.call(l10n) ?? l10n.shelfPlacement;

          return PopScope<void>(
            canPop: _allowPop,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                _handleBack(context);
              }
            },
            child: Scaffold(
              appBar: PrimaryAppBar(
                title: title,
                onBackPressed: () => _handleBack(context),
              ),
              resizeToAvoidBottomInset: false,
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final metrics = ScannerLayoutMetrics.fromConstraints(
                      constraints,
                    );

                    return _StockingPageBody(
                      maxWidth: metrics.contentMaxWidth,
                      horizontalPadding: metrics.pagePadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LiveScannerSection(
                            scannerOption: widget.scannerOption,
                            metrics: metrics,
                            inlineNotice: state.showProductChangedNotice
                                ? l10n.scannedProductChanged
                                : null,
                            onScanStarted: () =>
                                context.read<StockingBloc>().add(
                                  const StockingProductChangedNoticeCleared(),
                                ),
                            leadingAction: _ScanSideButton(
                              label: l10n.shelfNumberLabel,
                              height: metrics.buttonHeight + 10,
                              isSelected:
                                  state.selectedMode ==
                                  StockingScanMode.shelfNumber,
                              onPressed: () => context.read<StockingBloc>().add(
                                const StockingScanModeChanged(
                                  StockingScanMode.shelfNumber,
                                ),
                              ),
                            ),
                            trailingAction: _ScanSideButton(
                              label: l10n.merchandise,
                              height: metrics.buttonHeight + 10,
                              isSelected:
                                  state.selectedMode ==
                                  StockingScanMode.product,
                              onPressed: () => context.read<StockingBloc>().add(
                                const StockingScanModeChanged(
                                  StockingScanMode.product,
                                ),
                              ),
                            ),
                            onExternalBufferChanged: (value) {
                              if (value.isNotEmpty) {
                                context.read<StockingBloc>().add(
                                  StockingExternalInputChanged(value),
                                );
                              }
                            },
                            onScanned: (value, {required isOcr}) {
                              _barcodeFocusNode.unfocus();
                              context.read<StockingBloc>().add(
                                StockingScanValueSubmitted(value, isOcr: isOcr),
                              );
                            },
                            ignoredScannerFocusNodes: [_quantityFocusNode],
                            footerBuilder: (context, scannerState) => Column(
                              children: [
                                SizedBox(height: metrics.sectionGap),
                                _StockingProductInput(
                                  barcodeController: _barcodeController,
                                  quantityController: _quantityController,
                                  barcodeFocusNode: _barcodeFocusNode,
                                  quantityFocusNode: _quantityFocusNode,
                                  isExternalScannerMode:
                                      scannerState.isExternalScannerMode,
                                  isModeSwitching: scannerState.isModeSwitching,
                                  isLoading: state.isLoading,
                                  isShelfNumberMode:
                                      state.selectedMode ==
                                      StockingScanMode.shelfNumber,
                                  showQuantity:
                                      state.selectedMode ==
                                      StockingScanMode.product,
                                  showActionButtons: state.hasScannedProducts,
                                  onSubmit: () =>
                                      context.read<StockingBloc>().add(
                                        StockingBarcodeSubmitted(
                                          barcode: _barcodeController.text,
                                          quantityText:
                                              _quantityController.text,
                                        ),
                                      ),
                                  onBarcodeChanged: (value) => context
                                      .read<StockingBloc>()
                                      .add(StockingExternalInputChanged(value)),
                                  onQuantityChanged: (value) => context
                                      .read<StockingBloc>()
                                      .add(StockingQuantityChanged(value)),
                                  onUndo: () => context
                                      .read<StockingBloc>()
                                      .add(const StockingUndoRequested()),
                                  onComplete: () =>
                                      _showCompletionDialog(context),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: metrics.sectionGap),
                          _StockingListCard(
                            state: state,
                            onItemReset: (item) =>
                                _showItemResetDialog(context, item),
                          ),
                          if (state.isLoading) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleBack(BuildContext context) async {
    if (_allowPop) {
      return;
    }

    final navigator = Navigator.of(context);
    final hasUnsaved = context.read<StockingBloc>().state.hasScannedProducts;
    if (hasUnsaved) {
      final confirmed = await showUnsavedFileConfirmationDialog(context);
      if (!confirmed || !mounted) {
        return;
      }
    }

    setState(() => _allowPop = true);
    navigator.pop();
  }

  // ── Side-effect handling ───────────────────────────────────────────────────

  static bool _shouldHandleSideEffect(
    StockingState previous,
    StockingState current,
  ) {
    return previous.messageToken != current.messageToken ||
        previous.barcode != current.barcode ||
        previous.quantity != current.quantity ||
        previous.shelfNumber != current.shelfNumber ||
        previous.selectedMode != current.selectedMode ||
        previous.clearInputToken != current.clearInputToken ||
        previous.shouldPop != current.shouldPop;
  }

  void _handleSideEffect(BuildContext context, StockingState state) {
    // Sync text controllers — BLoC is the source of truth for field values.
    if (state.barcode != _lastSyncedBarcode) {
      _lastSyncedBarcode = state.barcode;
      _barcodeController.text = state.barcode;
    }
    if (state.quantity != _lastSyncedQuantity) {
      _lastSyncedQuantity = state.quantity;
      _quantityController.text = state.quantity;
    }

    // A successful manual input bumps [clearInputToken]. Clear the code field
    // (this also covers shelf-number mode, where the typed value never enters the
    // BLoC state), reset the quantity to its default and restore focus so the
    // next value can be entered without any extra tap. Scans and validation
    // failures never bump this token, so they leave the field untouched.
    if (state.clearInputToken != _lastClearInputToken) {
      _lastClearInputToken = state.clearInputToken;
      _barcodeController.clear();
      _lastSyncedBarcode = '';
      _quantityController.text = '1';
      _lastSyncedQuantity = '1';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _barcodeFocusNode.requestFocus();
      });
    }

    // Navigation signal.
    if (state.shouldPop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }

    // Show error messages (info/success messages are silently ignored).
    // Errors are one-shot events keyed by messageToken: the listener also
    // fires for input syncs (barcode/quantity edits), which must never
    // re-show an already-handled error.
    final message = state.message;
    if (message == null || _isInfoMessage(message)) return;
    if (state.messageToken == _lastShownErrorToken) return;
    _lastShownErrorToken = state.messageToken;
    showValidationErrorDialog(context, _localizedMessage(context, message));
  }

  // ── Dialogs — collect user intent, dispatch confirmed event ───────────────

  Future<void> _showCompletionDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StockingBloc>();
    final confirmed = await showScanConfirmationDialog(
      context,
      message: l10n.saveScannedDataConfirmation,
    );
    if (!mounted || !confirmed) return;
    bloc.add(const StockingWorkCompletionConfirmed());
  }

  Future<void> _showItemResetDialog(
    BuildContext context,
    ReceivingInspectionItem item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StockingBloc>();
    final shouldDelete = item.inspectedQuantity == 0;
    final confirmed = await showScanConfirmationDialog(
      context,
      message: shouldDelete
          ? l10n.deleteInspectionItemConfirmation
          : l10n.resetInspectionItemConfirmation,
      messageStyle: TextStyle(color: shouldDelete ? Colors.red : Colors.blue),
      cancelBackgroundColor: shouldDelete ? const Color(0xFFF1D4B3) : null,
      cancelForegroundColor: shouldDelete ? Colors.black : null,
      confirmBackgroundColor: shouldDelete ? Colors.red : null,
      confirmForegroundColor: shouldDelete ? Colors.white : null,
    );
    if (!mounted || confirmed != true) return;
    bloc.add(StockingItemResetConfirmed(item.id));
  }

  // ── Localization helpers (presentation-layer only) ─────────────────────────

  static bool _isInfoMessage(StockingMessage message) {
    return switch (message) {
      StockingMessage.inspectionSaved ||
      StockingMessage.productChanged ||
      StockingMessage.workCompleted => true,
      _ => false,
    };
  }

  static String _localizedMessage(
    BuildContext context,
    StockingMessage message,
  ) {
    final l10n = AppLocalizations.of(context);
    return switch (message) {
      StockingMessage.shelfNumberRequired => l10n.scanShelfNumberFirst,
      StockingMessage.barcodeRequired => l10n.barcodeRequired,
      StockingMessage.quantityRequired => l10n.quantityRequired,
      StockingMessage.invalidShelfNumber => l10n.invalidShelfNumberEntry,
      StockingMessage.invalidBarcode => l10n.invalidBarcode,
      StockingMessage.noScanDataToUndo => l10n.noScanDataToUndo,
      StockingMessage.noScanData => l10n.noInspectionData,
      StockingMessage.incompleteRow => l10n.incompleteShelfPlacementData,
      StockingMessage.saveFailed => l10n.shelfPlacementSaveFailed,
      _ => '',
    };
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Sub-widgets — pure layout / presentation
// ────────────────────────────────────────────────────────────────────────────

class _StockingProductInput extends StatelessWidget {
  const _StockingProductInput({
    required this.barcodeController,
    required this.quantityController,
    required this.barcodeFocusNode,
    required this.quantityFocusNode,
    required this.isExternalScannerMode,
    required this.isModeSwitching,
    required this.isLoading,
    required this.isShelfNumberMode,
    required this.showQuantity,
    required this.showActionButtons,
    required this.onSubmit,
    required this.onBarcodeChanged,
    required this.onQuantityChanged,
    required this.onUndo,
    required this.onComplete,
  });

  final TextEditingController barcodeController;
  final TextEditingController quantityController;
  final FocusNode barcodeFocusNode;
  final FocusNode quantityFocusNode;
  final bool isExternalScannerMode;
  final bool isModeSwitching;
  final bool isLoading;

  /// Whether the field is in shelf-number mode.
  ///
  /// In this mode the code field is restricted to the shelf-number character
  /// set; in product mode it is left unrestricted so product barcodes
  /// and QR codes (which use `#`, `~`, `*`, …) still scan correctly.
  final bool isShelfNumberMode;

  /// Whether the quantity label and field are shown.
  ///
  /// Hidden in shelf-number mode so the section occupies no space;
  /// shown in product mode.
  final bool showQuantity;
  final bool showActionButtons;
  final VoidCallback onSubmit;
  final ValueChanged<String> onBarcodeChanged;
  final ValueChanged<String> onQuantityChanged;
  final VoidCallback onUndo;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _StockingResponsiveMetrics.fromWidth(
              constraints.maxWidth,
            );
            final codeInput = AbsorbPointer(
              absorbing: isModeSwitching,
              child: TextField(
                controller: barcodeController,
                focusNode: barcodeFocusNode,
                enabled: !isLoading,
                readOnly: isExternalScannerMode,
                autofocus: false,
                showCursor: !isExternalScannerMode,
                enableInteractiveSelection: !isExternalScannerMode,
                keyboardType: isExternalScannerMode
                    ? TextInputType.none
                    : TextInputType.text,
                inputFormatters: isShelfNumberMode
                    ? [AllowedInput.shelfFormatter]
                    : null,
                textInputAction: TextInputAction.done,
                onChanged: onBarcodeChanged,
                onSubmitted: (_) {
                  if (!isExternalScannerMode) onSubmit();
                },
                onTapOutside: (_) {
                  if (!isExternalScannerMode) barcodeFocusNode.unfocus();
                },
                textAlignVertical: TextAlignVertical.center,
                decoration: _stockingInputDecoration(),
              ),
            );
            final quantityInput = TextField(
              controller: quantityController,
              focusNode: quantityFocusNode,
              enabled: !isLoading,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              onChanged: onQuantityChanged,
              onSubmitted: (_) {
                if (isExternalScannerMode) return;
                // Closing the quantity keyboard must not trigger the
                // empty-barcode validation popup; register only when the
                // code field currently holds a value.
                if (barcodeController.text.trim().isEmpty) {
                  quantityFocusNode.unfocus();
                  return;
                }
                onSubmit();
              },
              decoration: _stockingInputDecoration(),
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StockingInputLabel(
                  l10n.barcodeQr,
                  width: metrics.barcodeLabelWidth,
                  height: metrics.inputHeight,
                ),
                SizedBox(width: metrics.fieldGap),
                Expanded(
                  child: SizedBox(
                    height: metrics.inputHeight,
                    child: codeInput,
                  ),
                ),
                if (showQuantity) ...[
                  SizedBox(width: metrics.inlineGap),
                  _StockingInputLabel(
                    l10n.quantity,
                    width: metrics.quantityLabelWidth,
                    height: metrics.inputHeight,
                  ),
                  SizedBox(width: metrics.fieldGap),
                  SizedBox(
                    width: metrics.quantityInputWidth,
                    height: metrics.inputHeight,
                    child: quantityInput,
                  ),
                ],
              ],
            );
          },
        ),
        if (showActionButtons) ...[
          const SizedBox(height: 14),
          _StockingActionButtons(
            isLoading: isLoading,
            onUndo: onUndo,
            onComplete: onComplete,
          ),
        ],
      ],
    );
  }
}

InputDecoration _stockingInputDecoration() {
  return const InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(),
    isDense: true,
  );
}

class _StockingInputLabel extends StatelessWidget {
  const _StockingInputLabel(
    this.label, {
    required this.width,
    required this.height,
  });

  final String label;
  final double width;
  final double height;

  static const _style = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1F2937),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: _style,
        ),
      ),
    );
  }
}

class _StockingActionButtons extends StatelessWidget {
  const _StockingActionButtons({
    required this.isLoading,
    required this.onUndo,
    required this.onComplete,
  });

  final bool isLoading;
  final VoidCallback onUndo;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _StockingResponsiveMetrics.fromWidth(
          constraints.maxWidth,
        );
        final buttonStyle = FilledButton.styleFrom(
          minimumSize: Size(0, metrics.actionButtonHeight),
          padding: EdgeInsets.symmetric(horizontal: metrics.controlPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(metrics.controlRadius),
          ),
        );
        final secondaryStyle = buttonStyle.copyWith(
          backgroundColor: WidgetStatePropertyAll(Colors.grey.shade200),
          foregroundColor: const WidgetStatePropertyAll(Colors.black),
        );

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.min(360 + metrics.inlineGap, constraints.maxWidth),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: metrics.actionButtonHeight,
                    child: FilledButton(
                      onPressed: isLoading ? null : onUndo,
                      style: secondaryStyle,
                      child: _ActionButtonLabel(l10n.undoOneScan),
                    ),
                  ),
                ),
                SizedBox(width: metrics.inlineGap),
                Expanded(
                  child: SizedBox(
                    height: metrics.actionButtonHeight,
                    child: FilledButton(
                      onPressed: isLoading ? null : onComplete,
                      style: buttonStyle,
                      child: _ActionButtonLabel(l10n.completeWork),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionButtonLabel extends StatelessWidget {
  const _ActionButtonLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StockingListCard extends StatelessWidget {
  const _StockingListCard({required this.state, required this.onItemReset});

  final StockingState state;
  final ValueChanged<ReceivingInspectionItem> onItemReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stockingItems = state.visibleItems;
    final latestShelfNumber = state.shelfNumber;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = _StockingResponsiveMetrics.fromWidth(
          constraints.maxWidth,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  color: Colors.indigo.shade700,
                  size: spacing.iconSize,
                ),
                SizedBox(width: spacing.inlineGap),
                Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.inspectionList,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.verticalGap * 0.6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.45),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.inlineGap,
                  vertical: spacing.inlineGap * 0.65,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    latestShelfNumber.isNotEmpty
                        ? '${l10n.shelfMatchLabel} $latestShelfNumber'
                        : l10n.shelfMatchLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
            StockingInspectionTable(
              items: stockingItems,
              selectedItemId: state.selectedItemId,
              showResetColumn: true,
              onReset: onItemReset,
            ),
          ],
        );
      },
    );
  }
}

class _StockingPageBody extends StatelessWidget {
  const _StockingPageBody({
    required this.child,
    this.maxWidth = 980,
    this.horizontalPadding,
  });

  final Widget child;
  final double maxWidth;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsivePadding = (constraints.maxWidth * 0.045).clamp(
          8.0,
          28.0,
        );
        final resolvedHorizontalPadding =
            horizontalPadding?.clamp(8.0, 28.0) ?? responsivePadding;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                resolvedHorizontalPadding,
                20,
                resolvedHorizontalPadding,
                20,
              ),
              children: [child],
            ),
          ),
        );
      },
    );
  }
}

class _StockingResponsiveMetrics {
  const _StockingResponsiveMetrics({
    required this.inlineGap,
    required this.fieldGap,
    required this.verticalGap,
    required this.controlPadding,
    required this.controlRadius,
    required this.inputHeight,
    required this.actionButtonHeight,
    required this.iconSize,
    required this.barcodeLabelWidth,
    required this.quantityLabelWidth,
    required this.quantityInputWidth,
  });

  final double inlineGap;
  final double fieldGap;
  final double verticalGap;
  final double controlPadding;
  final double controlRadius;
  final double inputHeight;
  final double actionButtonHeight;
  final double iconSize;
  final double barcodeLabelWidth;
  final double quantityLabelWidth;
  final double quantityInputWidth;

  factory _StockingResponsiveMetrics.fromWidth(double width) {
    final normalizedWidth = width.isFinite ? width : 420.0;

    if (normalizedWidth < 340) {
      return const _StockingResponsiveMetrics(
        inlineGap: 6,
        fieldGap: 4,
        verticalGap: 8,
        controlPadding: 5,
        controlRadius: 8,
        inputHeight: 42,
        actionButtonHeight: 44,
        iconSize: 22,
        barcodeLabelWidth: 104,
        quantityLabelWidth: 28,
        quantityInputWidth: 76,
      );
    }

    if (normalizedWidth < 420) {
      return const _StockingResponsiveMetrics(
        inlineGap: 8,
        fieldGap: 5,
        verticalGap: 10,
        controlPadding: 6,
        controlRadius: 8,
        inputHeight: 44,
        actionButtonHeight: 46,
        iconSize: 24,
        barcodeLabelWidth: 104,
        quantityLabelWidth: 32,
        quantityInputWidth: 88,
      );
    }

    return const _StockingResponsiveMetrics(
      inlineGap: 12,
      fieldGap: 6,
      verticalGap: 12,
      controlPadding: 10,
      controlRadius: 8,
      inputHeight: 44,
      actionButtonHeight: 48,
      iconSize: 28,
      barcodeLabelWidth: 104,
      quantityLabelWidth: 38,
      quantityInputWidth: 100,
    );
  }
}

class _ScanSideButton extends StatelessWidget {
  const _ScanSideButton({
    required this.label,
    required this.height,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final double height;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(100)),
    );

    if (isSelected) {
      return FilledButton.icon(
        onPressed: onPressed,

        // Preserve the selected button's existing dimensions and label
        // alignment without rendering a selection icon.
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          minimumSize: Size(72, height),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: pill,
        ),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFE5E7EB),
        foregroundColor: const Color(0xFF374151),
        minimumSize: Size(72, height),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: pill,
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

// ── Scanner option for Shelf Placement ────────────────────────────────────

const ScannerOption _stockingScannerOption = ScannerOption(
  key: 'stocking',
  title: 'Shelf Placement',
  subtitle: 'Shelf Placement Barcode Inspection',
  formats: [
    ScannerFormat.qrCode,
    ScannerFormat.code39,
    ScannerFormat.codabar,
    ScannerFormat.code128,
    ScannerFormat.ean13,
    ScannerFormat.itf2of5,
    ScannerFormat.itf14,
  ],
  colorValue: 0xFF005F73,
  playDetectionSuccessSound: false,
);
