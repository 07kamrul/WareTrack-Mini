import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
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
import 'package:waretrack_mini/features/receiving/bloc/receiving_bloc.dart';
import 'package:waretrack_mini/features/receiving/bloc/receiving_event.dart';
import 'package:waretrack_mini/features/receiving/bloc/receiving_state.dart';
import 'package:waretrack_mini/features/receiving/widgets/receiving_input_row.dart';
import 'package:waretrack_mini/features/receiving/widgets/receiving_inspection_table.dart';

class ReceivingSelectionPage extends StatefulWidget {
  const ReceivingSelectionPage({
    super.key,
    this.titleBuilder,
    this.blocFactory,
  });

  final String Function(AppLocalizations localizations)? titleBuilder;
  final ReceivingBloc Function()? blocFactory;

  @override
  State<ReceivingSelectionPage> createState() => _ReceivingSelectionPageState();
}

class _ReceivingSelectionPageState extends State<ReceivingSelectionPage> {
  late final TextEditingController _slipController;

  @override
  void initState() {
    super.initState();
    _slipController = TextEditingController();
  }

  @override
  void dispose() {
    _slipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => widget.blocFactory?.call() ?? sl<ReceivingBloc>(),
      child: BlocConsumer<ReceivingBloc, ReceivingState>(
        listenWhen: (previous, current) =>
            previous.messageToken != current.messageToken,
        listener: _showReceivingMessage,
        builder: (context, state) {
          if (_slipController.text != state.slipNumber && state.hasSlip) {
            _slipController.text = state.slipNumber;
          }
          final title = _pageTitle(context);

          return Scaffold(
            appBar: PrimaryAppBar(title: title),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final metrics = ScannerLayoutMetrics.fromConstraints(
                    constraints,
                  );

                  return _ReceivingPageBody(
                    maxWidth: metrics.contentMaxWidth,
                    horizontalPadding: metrics.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LiveScannerSection(
                          scannerOption: _receivingScannerOption,
                          metrics: metrics,
                          instruction: AppLocalizations.of(
                            context,
                          ).scanSlipOrderPrompt,
                          showScannedValue: false,
                          onScanned: (value, {required isOcr}) {
                            _slipController.text = value;
                          },
                        ),
                        SizedBox(height: metrics.sectionGap),
                        ReceivingInputRow(
                          controller: _slipController,
                          label: AppLocalizations.of(context).slipOrderNumber,
                          enabled: !state.isLoading,
                          onSubmitted: () => _openBarcodeInspection(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openBarcodeInspection(BuildContext context) async {
    final slipNumber = _slipController.text.trim();
    final bloc = context.read<ReceivingBloc>();
    final navigator = Navigator.of(context);

    // Keep the existing scan validation: an empty or malformed slip surfaces the
    // same validation message and stops here without opening the inspection page.
    if (!_isValidSlipNumber(slipNumber)) {
      bloc.add(ReceivingSlipSubmitted(slipNumber));
      return;
    }

    // If this slip/order was saved before, reopen it in edit mode and load the
    // previously saved items instead of creating a duplicate new order.
    final isExistingOrder = await bloc.savedWorkExists(slipNumber);
    if (!mounted) {
      return;
    }

    bloc.add(
      isExistingOrder
          ? ReceivingSavedWorkOpened(slipNumber)
          : ReceivingSlipSubmitted(slipNumber),
    );

    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: ReceivingBarcodeInspectionPage(
            slipNumber: slipNumber,
            titleBuilder: widget.titleBuilder,
            applySlipNumber: false,
          ),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    _slipController.clear();
    bloc.add(const ReceivingSessionDiscarded());
  }

  String _pageTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return widget.titleBuilder?.call(l10n) ?? l10n.receiving;
  }
}

class ReceivingBarcodeInspectionPage extends StatefulWidget {
  const ReceivingBarcodeInspectionPage({
    super.key,
    required this.slipNumber,
    this.readOnly = false,
    this.loadSavedWork = false,
    this.applySlipNumber = true,
    this.titleBuilder,
  });

  final String slipNumber;
  final bool readOnly;
  final bool loadSavedWork;
  final bool applySlipNumber;
  final String Function(AppLocalizations localizations)? titleBuilder;

  @override
  State<ReceivingBarcodeInspectionPage> createState() =>
      _ReceivingBarcodeInspectionPageState();
}

class _ReceivingBarcodeInspectionPageState
    extends State<ReceivingBarcodeInspectionPage> {
  /// Quantity every new product entry starts from.
  static const String _defaultQuantity = '1';

  late final TextEditingController _barcodeController;
  late final TextEditingController _quantityController;
  late final FocusNode _barcodeFocusNode;
  late final FocusNode _quantityFocusNode;
  bool _showProductChangedMessage = false;
  bool _didApplySlipNumber = false;
  bool _shouldPopAfterWorkCompleted = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController();
    _quantityController = TextEditingController(text: _defaultQuantity);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplySlipNumber) {
      return;
    }

    _didApplySlipNumber = true;
    if (!widget.applySlipNumber) {
      return;
    }

    context.read<ReceivingBloc>().add(
      widget.loadSavedWork
          ? ReceivingSavedWorkOpened(widget.slipNumber)
          : ReceivingSlipSubmitted(widget.slipNumber),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceivingBloc, ReceivingState>(
      listenWhen: (previous, current) =>
          previous.messageToken != current.messageToken,
      listener: _showMessage,
      builder: (context, receivingState) {
        return PopScope<void>(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _popToPreviousStep();
            }
          },
          child: Scaffold(
            appBar: PrimaryAppBar(
              title: _pageTitle(context),
              onBackPressed: _popToPreviousStep,
            ),
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final metrics = ScannerLayoutMetrics.fromConstraints(
                    constraints,
                  );

                  return _ReceivingPageBody(
                    maxWidth: metrics.contentMaxWidth,
                    horizontalPadding: metrics.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!widget.readOnly) ...[
                          LiveScannerSection(
                            scannerOption: _receivingProductScannerOption,
                            metrics: metrics,
                            inlineNotice: _showProductChangedMessage
                                ? AppLocalizations.of(
                                    context,
                                  ).scannedProductChanged
                                : null,
                            onScanStarted: _hideProductChangedNotice,
                            ignoredScannerFocusNodes: [_quantityFocusNode],
                            onExternalBufferChanged: (value) {
                              if (value.isNotEmpty) {
                                _barcodeController.text = value;
                              }
                            },
                            onScanned: (value, {required isOcr}) {
                              _barcodeController.text = value;
                              _barcodeFocusNode.unfocus();
                              _recordScan(isOcr: isOcr);
                            },
                            footerBuilder: (context, scannerState) => Column(
                              children: [
                                SizedBox(height: metrics.sectionGap),
                                _ReceivingBusinessCard(
                                  barcodeController: _barcodeController,
                                  quantityController: _quantityController,
                                  barcodeFocusNode: _barcodeFocusNode,
                                  quantityFocusNode: _quantityFocusNode,
                                  isExternalScannerMode:
                                      scannerState.isExternalScannerMode,
                                  isModeSwitching: scannerState.isModeSwitching,
                                  isLoading: receivingState.isLoading,
                                  showActionButtons:
                                      receivingState.hasScannedProducts,
                                  onSubmit: _recordScan,
                                  onUndo: () =>
                                      context.read<ReceivingBloc>().add(
                                        const ReceivingLastScanUndoRequested(),
                                      ),
                                  onComplete: () =>
                                      _confirmAndCompleteWork(context),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: metrics.sectionGap),
                        ] else ...[
                          SizedBox(height: metrics.sectionGap * 0.2),
                        ],
                        _InspectionListCard(
                          state: receivingState,
                          slipNumber: widget.slipNumber,
                          readOnly: widget.readOnly,
                          onItemSelected: (item) {
                            if (widget.readOnly) {
                              return;
                            }
                            context.read<ReceivingBloc>().add(
                              ReceivingItemSelected(item.id),
                            );
                            _barcodeController.text = item.barcode;
                          },
                          onItemReset: (item) =>
                              _resetOrConfirmDeleteItem(context, item),
                        ),
                        if (receivingState.isLoading) ...[
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
    );
  }

  String _pageTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return widget.titleBuilder?.call(l10n) ?? l10n.receiving;
  }

  void _recordScan({bool isOcr = false}) {
    if (widget.readOnly) {
      return;
    }

    _hideProductChangedNotice();
    context.read<ReceivingBloc>().add(
      ReceivingBarcodeSubmitted(
        barcode: _barcodeController.text,
        quantityText: _quantityController.text,
        isOcr: isOcr,
      ),
    );
  }

  void _showMessage(BuildContext context, ReceivingState state) {
    final message = state.message;
    if (message == null) {
      return;
    }

    if (message == ReceivingMessage.inspectionSaved ||
        message == ReceivingMessage.productChanged) {
      _resetProductInputs();
    }

    if (message == ReceivingMessage.productChanged) {
      _showProductChangedNotice();
      return;
    }

    if (_shouldPopAfterWorkCompleted &&
        message == ReceivingMessage.workCompleted) {
      _shouldPopAfterWorkCompleted = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _popWithoutForwardHistory();
        }
      });
      return;
    }

    if (_isReceivingSuccessOrInfoMessage(message)) {
      return;
    }

    showValidationErrorDialog(
      context,
      _localizedReceivingMessage(context, message),
    );
  }

  void _showProductChangedNotice() {
    setState(() {
      _showProductChangedMessage = true;
    });
  }

  void _hideProductChangedNotice() {
    if (!_showProductChangedMessage) {
      return;
    }

    setState(() {
      _showProductChangedMessage = false;
    });
  }

  Future<void> _confirmAndCompleteWork(BuildContext context) async {
    if (widget.readOnly) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final receivingBloc = context.read<ReceivingBloc>();
    final confirmed = await showScanConfirmationDialog(
      context,
      message: l10n.saveScannedDataConfirmation,
    );

    if (!mounted || !confirmed) {
      return;
    }

    _shouldPopAfterWorkCompleted = true;
    receivingBloc.add(const ReceivingWorkCompleted());
  }

  Future<void> _resetOrConfirmDeleteItem(
    BuildContext context,
    ReceivingInspectionItem item,
  ) async {
    if (widget.readOnly) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final receivingBloc = context.read<ReceivingBloc>();
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

    if (!mounted || confirmed != true) {
      return;
    }

    receivingBloc.add(ReceivingItemResetRequested(item.id));
  }

  /// Resets the product entry fields after a product has been successfully
  /// added to the inspection list, so the next entry always starts from the
  /// defaults: an empty product code and a quantity of [_defaultQuantity].
  ///
  /// This only touches the input fields — the quantity already saved for the
  /// product just registered is left unchanged.
  void _resetProductInputs() {
    _barcodeController.clear();
    if (_quantityController.text != _defaultQuantity) {
      _quantityController.text = _defaultQuantity;
    }
  }

  Future<void> _popToPreviousStep() async {
    if (!_allowPop && !widget.readOnly && mounted) {
      final state = context.read<ReceivingBloc>().state;
      if (state.hasScannedProducts) {
        final confirmed = await showUnsavedFileConfirmationDialog(context);
        if (!confirmed || !mounted) {
          return;
        }
      }
    }

    _popWithResult();
  }

  void _popWithoutForwardHistory() {
    _popWithResult();
  }

  void _popWithResult() {
    if (_allowPop || !mounted) {
      return;
    }

    setState(() {
      _allowPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}

class _InspectionListCard extends StatelessWidget {
  const _InspectionListCard({
    required this.state,
    required this.slipNumber,
    required this.readOnly,
    required this.onItemSelected,
    required this.onItemReset,
  });

  final ReceivingState state;
  final String slipNumber;
  final bool readOnly;
  final ValueChanged<ReceivingInspectionItem> onItemSelected;
  final ValueChanged<ReceivingInspectionItem> onItemReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = _ReceivingResponsiveMetrics.fromWidth(
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
                  horizontal: spacing.contentPadding,
                  vertical: spacing.contentPadding * 0.65,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.selectedSlip(slipNumber.isEmpty ? '-' : slipNumber),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
            ReceivingInspectionTable(
              items: state.visibleItems,
              selectedItemId: state.selectedItemId,
              showSelectionColumn: false,
              showResetColumn: !readOnly,
              showProductName: false,
              onSelected: onItemSelected,
              onReset: readOnly ? null : onItemReset,
            ),
          ],
        );
      },
    );
  }
}

class _ReceivingBusinessCard extends StatelessWidget {
  const _ReceivingBusinessCard({
    required this.barcodeController,
    required this.quantityController,
    required this.barcodeFocusNode,
    required this.quantityFocusNode,
    required this.isExternalScannerMode,
    required this.isModeSwitching,
    required this.isLoading,
    required this.showActionButtons,
    required this.onSubmit,
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
  final bool showActionButtons;
  final VoidCallback onSubmit;
  final VoidCallback onUndo;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _ReceivingResponsiveMetrics.fromWidth(
              constraints.maxWidth,
            );
            final codeTextField = TextField(
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
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!isExternalScannerMode) {
                  onSubmit();
                }
              },
              onTapOutside: (_) {
                if (!isExternalScannerMode) {
                  barcodeFocusNode.unfocus();
                }
              },
              textAlignVertical: TextAlignVertical.center,
              decoration: receivingInputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            );
            final codeInput = AbsorbPointer(
              absorbing: isModeSwitching,
              child: codeTextField,
            );
            final quantityInput = TextField(
              controller: quantityController,
              focusNode: quantityFocusNode,
              enabled: !isLoading,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              onSubmitted: (_) {
                if (isExternalScannerMode) {
                  return;
                }
                // Closing the quantity keyboard must not trigger the
                // empty-barcode validation popup; register only when the
                // code field currently holds a value.
                if (barcodeController.text.trim().isEmpty) {
                  quantityFocusNode.unfocus();
                  return;
                }
                onSubmit();
              },
              decoration: receivingInputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ReceivingInputLabel(
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
                SizedBox(width: metrics.inlineGap),
                _ReceivingInputLabel(
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
            );
          },
        ),
        if (showActionButtons) ...[
          const SizedBox(height: 14),
          _ReceivingActionButtons(
            isLoading: isLoading,
            onUndo: onUndo,
            onComplete: onComplete,
          ),
        ],
      ],
    );
  }
}

class _ReceivingInputLabel extends StatelessWidget {
  const _ReceivingInputLabel(
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
        child: Text(label, maxLines: 1, style: _style),
      ),
    );
  }
}

class _ReceivingActionButtons extends StatelessWidget {
  const _ReceivingActionButtons({
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
        final metrics = _ReceivingResponsiveMetrics.fromWidth(
          constraints.maxWidth,
        );
        final buttonStyle = FilledButton.styleFrom(
          minimumSize: Size(0, metrics.actionButtonHeight),
          padding: EdgeInsets.symmetric(horizontal: metrics.controlPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(metrics.controlRadius),
          ),
        );
        final finishButtonStyle = buttonStyle.copyWith(
          backgroundColor: WidgetStatePropertyAll(Colors.grey.shade200),
          foregroundColor: const WidgetStatePropertyAll(Colors.black),
        );
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.min(520 + metrics.inlineGap, constraints.maxWidth),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: metrics.actionButtonHeight,
                    child: FilledButton(
                      onPressed: isLoading ? null : onUndo,
                      style: finishButtonStyle,
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

class _ReceivingPageBody extends StatelessWidget {
  const _ReceivingPageBody({
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

class _ReceivingResponsiveMetrics {
  const _ReceivingResponsiveMetrics({
    required this.inlineGap,
    required this.fieldGap,
    required this.verticalGap,
    required this.contentPadding,
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
  final double contentPadding;
  final double controlPadding;
  final double controlRadius;
  final double inputHeight;
  final double actionButtonHeight;
  final double iconSize;
  final double barcodeLabelWidth;
  final double quantityLabelWidth;
  final double quantityInputWidth;

  factory _ReceivingResponsiveMetrics.fromWidth(double width) {
    final normalizedWidth = width.isFinite ? width : 420.0;

    if (normalizedWidth < 340) {
      return const _ReceivingResponsiveMetrics(
        inlineGap: 6,
        fieldGap: 4,
        verticalGap: 8,
        contentPadding: 8,
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
      return const _ReceivingResponsiveMetrics(
        inlineGap: 8,
        fieldGap: 5,
        verticalGap: 10,
        contentPadding: 10,
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

    return const _ReceivingResponsiveMetrics(
      inlineGap: 12,
      fieldGap: 6,
      verticalGap: 12,
      contentPadding: 12,
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

String _localizedReceivingMessage(
  BuildContext context,
  ReceivingMessage message,
) {
  final l10n = AppLocalizations.of(context);

  return switch (message) {
    ReceivingMessage.slipRequired => l10n.slipRequired,
    ReceivingMessage.barcodeRequired => l10n.barcodeRequired,
    ReceivingMessage.quantityRequired => l10n.quantityRequired,
    ReceivingMessage.invalidSlip => l10n.invalidSlip,
    ReceivingMessage.invalidBarcode => l10n.invalidBarcode,
    ReceivingMessage.slipLoaded => l10n.slipLoaded,
    ReceivingMessage.inspectionSaved => l10n.inspectionSaved,
    ReceivingMessage.productChanged => l10n.scannedProductChanged,
    ReceivingMessage.workCompleted => l10n.workCompleted,
    ReceivingMessage.noScanDataToUndo => l10n.noScanDataToUndo,
  };
}

void _showReceivingMessage(BuildContext context, ReceivingState state) {
  final message = state.message;
  if (message == null) {
    return;
  }

  if (_isReceivingSuccessOrInfoMessage(message)) {
    return;
  }

  showValidationErrorDialog(
    context,
    _localizedReceivingMessage(context, message),
  );
}

bool _isReceivingSuccessOrInfoMessage(ReceivingMessage message) {
  return switch (message) {
    ReceivingMessage.slipLoaded ||
    ReceivingMessage.inspectionSaved ||
    ReceivingMessage.productChanged ||
    ReceivingMessage.workCompleted => true,
    ReceivingMessage.slipRequired ||
    ReceivingMessage.barcodeRequired ||
    ReceivingMessage.quantityRequired ||
    ReceivingMessage.invalidSlip ||
    ReceivingMessage.invalidBarcode => false,
    ReceivingMessage.noScanDataToUndo => false,
  };
}

bool _isValidSlipNumber(String slipNumber) {
  return AllowedInput.isValidSlip(slipNumber);
}

const ScannerOption _receivingScannerOption = ScannerOption(
  key: 'receiving',
  title: 'Receiving',
  subtitle: 'Receiving barcode inspection',
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
);

const ScannerOption _receivingProductScannerOption = ScannerOption(
  key: 'receiving',
  title: 'Receiving',
  subtitle: 'Receiving barcode inspection',
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
