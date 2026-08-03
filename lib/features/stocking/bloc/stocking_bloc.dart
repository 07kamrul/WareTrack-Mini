import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waretrack_mini/core/services/scan_feedback_service.dart';
import 'package:waretrack_mini/core/utils/allowed_input.dart';
import 'package:waretrack_mini/core/utils/base_bloc.dart';
import 'package:waretrack_mini/core/utils/receiving_barcode_value.dart';
import 'package:waretrack_mini/data/local/receiving_repository_service.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/features/receiving/delete_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/record_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/receiving/reset_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/undo_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/stocking/bloc/stocking_event.dart';
import 'package:waretrack_mini/features/stocking/bloc/stocking_state.dart';

typedef CompleteStockingSession =
    Future<List<ReceivingInspectionItem>> Function(
      List<ReceivingInspectionItem> items,
    );

class StockingBloc extends BaseBloc<StockingEvent, StockingState> {
  StockingBloc({
    required RecordReceivingScanUseCase recordScan,
    required CompleteStockingSession completeWork,
    required ResetReceivingInspectionItemUseCase resetItem,
    required DeleteReceivingInspectionItemUseCase deleteItem,
    required UndoReceivingScanUseCase undoScan,
    required ScanFeedbackService feedbackService,
    required Future<void> Function() discardTemporaryWork,
  }) : _recordScan = recordScan,
       _completeWork = completeWork,
       _resetItem = resetItem,
       _deleteItem = deleteItem,
       _undoScan = undoScan,
       _feedbackService = feedbackService,
       _discardTemporaryWork = discardTemporaryWork,
       super(const StockingState()) {
    on<StockingSessionStarted>(_onSessionStarted);
    on<StockingScanModeChanged>(_onScanModeChanged);
    on<StockingScanValueSubmitted>(_onScanValueSubmitted);
    on<StockingExternalInputChanged>(_onExternalInputChanged);
    on<StockingQuantityChanged>(_onQuantityChanged);
    on<StockingProductChangedNoticeCleared>(_onProductChangedNoticeCleared);
    on<StockingBarcodeSubmitted>(_onBarcodeSubmitted);
    on<StockingUndoRequested>(_onUndoRequested);
    on<StockingWorkCompletionConfirmed>(_onWorkCompletionConfirmed);
    on<StockingItemResetConfirmed>(_onItemResetConfirmed);
  }

  final RecordReceivingScanUseCase _recordScan;
  final CompleteStockingSession _completeWork;
  final ResetReceivingInspectionItemUseCase _resetItem;
  final DeleteReceivingInspectionItemUseCase _deleteItem;
  final UndoReceivingScanUseCase _undoScan;
  final ScanFeedbackService _feedbackService;
  final Future<void> Function() _discardTemporaryWork;
  _StockingScanUndoEntry? _latestScanUndo;
  String? _previousScannedProductValue;

  Future<void> _onSessionStarted(
    StockingSessionStarted event,
    Emitter<StockingState> emit,
  ) async {
    await _discardTemporaryWork();
    _latestScanUndo = null;
    _resetProductSoundPattern();
    emit(const StockingState());
  }

  void _onScanModeChanged(
    StockingScanModeChanged event,
    Emitter<StockingState> emit,
  ) {
    emit(state.copyWith(selectedMode: event.mode, clearMessage: true));
  }

  Future<void> _onScanValueSubmitted(
    StockingScanValueSubmitted event,
    Emitter<StockingState> emit,
  ) async {
    final scannedValue = event.value;
    if (scannedValue.isEmpty) return;

    if (state.selectedMode == StockingScanMode.shelfNumber) {
      await _submitShelfNumber(scannedValue, event, emit);
    } else {
      emit(
        state.copyWith(barcode: scannedValue, showProductChangedNotice: false),
      );
      await _submitBarcode(
        scannedValue,
        state.quantity,
        event,
        emit,
        fromOcr: event.isOcr,
      );
    }
  }

  void _onExternalInputChanged(
    StockingExternalInputChanged event,
    Emitter<StockingState> emit,
  ) {
    if (state.selectedMode == StockingScanMode.product) {
      // Editing the code invalidates any pending validation error — the next
      // submit re-validates against the new value.
      emit(state.copyWith(barcode: event.value, clearMessage: true));
    }
  }

  void _onQuantityChanged(
    StockingQuantityChanged event,
    Emitter<StockingState> emit,
  ) {
    emit(state.copyWith(quantity: event.value, clearMessage: true));
  }

  void _onProductChangedNoticeCleared(
    StockingProductChangedNoticeCleared event,
    Emitter<StockingState> emit,
  ) {
    emit(state.copyWith(showProductChangedNotice: false));
  }

  Future<void> _onBarcodeSubmitted(
    StockingBarcodeSubmitted event,
    Emitter<StockingState> emit,
  ) async {
    emit(state.copyWith(showProductChangedNotice: false));
    if (state.selectedMode == StockingScanMode.shelfNumber) {
      await _submitShelfNumber(
        event.barcode.trim(),
        event,
        emit,
        fromManualInput: true,
      );
      return;
    }
    await _submitBarcode(
      event.barcode,
      event.quantityText,
      event,
      emit,
      fromManualInput: true,
    );
  }

  Future<void> _submitShelfNumber(
    String value,
    Object eventId,
    Emitter<StockingState> emit, {
    bool fromManualInput = false,
  }) async {
    // Changing the shelf keeps the pending undo entry: it carries its own
    // shelf number, so "undo 1 scan" still targets the last scanned product.
    _resetProductSoundPattern();

    if (!_isValidShelfNumber(value)) {
      await _emitMessage(
        emit,
        StockingMessage.invalidShelfNumber,
        isError: true,
      );
      return;
    }

    emit(
      state.copyWith(
        selectedMode: StockingScanMode.product,
        shelfNumber: value,
        // On the manual path the code field is force-cleared and its synced
        // marker reset to ''; keep the state in step so a later rebuild does
        // not re-inject the typed value. Scans leave the state untouched.
        barcode: fromManualInput ? '' : null,
        clearSelectedItem: true,
        clearMessage: true,
        clearInputToken: fromManualInput
            ? state.clearInputToken + 1
            : null,
      ),
    );
    await _feedbackService.playProductScanSuccess(eventId: eventId);
  }

  Future<void> _submitBarcode(
    String barcode,
    String quantityText,
    Object eventId,
    Emitter<StockingState> emit, {
    bool fromManualInput = false,
    bool fromOcr = false,
  }) async {
    if (state.selectedMode == StockingScanMode.shelfNumber) {
      await _submitShelfNumber(
        barcode.trim(),
        eventId,
        emit,
        fromManualInput: fromManualInput,
      );
      return;
    }

    final normalizedBarcode = fromOcr
        ? ReceivingBarcodeValue.normalizeOcrForInspectionList(barcode)
        : ReceivingBarcodeValue.normalizeForInspectionList(barcode);
    final quantity = int.tryParse(quantityText.trim());
    final shelfNumber = state.shelfNumber.trim();

    if (shelfNumber.isEmpty) {
      await _emitMessage(
        emit,
        StockingMessage.shelfNumberRequired,
        isError: true,
      );
      return;
    }
    if (normalizedBarcode == null) {
      await _emitMessage(emit, StockingMessage.barcodeRequired, isError: true);
      return;
    }
    if (quantity == null || quantity <= 0) {
      await _emitMessage(emit, StockingMessage.quantityRequired, isError: true);
      return;
    }

    final previousSessionItems = state.items;
    emit(state.copyWith(isLoading: true, clearMessage: true));
    try {
      final persistedShelfItems = await _recordScan(
        RecordReceivingScanParams(
          slipNumber: shelfNumber,
          barcode: normalizedBarcode,
          quantity: quantity,
        ),
      );
      final updatedItem = persistedShelfItems.firstWhere(
        (item) =>
            item.slipNumber == shelfNumber && item.barcode == normalizedBarcode,
      );
      final mergedSessionItems = _mergePersistedShelfRows(
        previousSessionItems,
        shelfNumber,
        persistedShelfItems,
      );
      // Latest scan always shows at the top of the list, same as receiving/shipping.
      final updatedSessionItems = [
        updatedItem,
        for (final item in mergedSessionItems)
          if (item.id != updatedItem.id) item,
      ];
      final productChanged =
          _previousScannedProductValue != null &&
          _previousScannedProductValue != normalizedBarcode;
      final sound = _productSoundFor(normalizedBarcode);
      emit(
        state.copyWith(
          shelfNumber: shelfNumber,
          items: updatedSessionItems,
          selectedItemId: updatedItem.id,
          barcode: '',
          quantity: '1',
          isLoading: false,
          message: productChanged
              ? StockingMessage.productChanged
              : StockingMessage.inspectionSaved,
          messageToken: state.messageToken + 1,
          showProductChangedNotice: productChanged,
          clearInputToken: fromManualInput
              ? state.clearInputToken + 1
              : null,
        ),
      );
      // Remember the quantity this product had before the scan so "undo 1 scan"
      // can restore it exactly (0 when the product was not in the list yet).
      // Only the most recent action is undoable: each new scan replaces the
      // previous undo entry.
      final previousQuantity =
          updatedItem.inspectedQuantity > quantity
          ? updatedItem.inspectedQuantity - quantity
          : 0;
      _latestScanUndo = _StockingScanUndoEntry(
        shelfNumber: shelfNumber,
        barcode: normalizedBarcode,
        previousQuantity: previousQuantity,
        addedQuantity: quantity,
        newQuantity: updatedItem.inspectedQuantity,
      );
      if (sound == _ProductScanSound.differentProduct) {
        await _feedbackService.playDifferentProduct(eventId: eventId);
      } else {
        await _feedbackService.playProductScanSuccess(eventId: eventId);
      }
      _previousScannedProductValue = normalizedBarcode;
    } on ReceivingRepositoryException catch (error) {
      emit(state.copyWith(isLoading: false));
      await _emitMessage(
        emit,
        error == ReceivingRepositoryException.invalidSlip
            ? StockingMessage.invalidShelfNumber
            : StockingMessage.invalidBarcode,
        isError: true,
      );
    }
  }

  Future<void> _onUndoRequested(
    StockingUndoRequested event,
    Emitter<StockingState> emit,
  ) async {
    // Only the most recent scan/insert can be undone, exactly once: the entry
    // is consumed by this press, so pressing again without a new scan asks
    // for a barcode instead of undoing anything further.
    final undoEntry = _latestScanUndo;
    _latestScanUndo = null;
    final targetItem = undoEntry == null
        ? null
        : state.items
              .where(
                (item) =>
                    item.slipNumber == undoEntry.shelfNumber &&
                    item.barcode == undoEntry.barcode,
              )
              .firstOrNull;
    if (undoEntry == null ||
        targetItem == null ||
        undoEntry.addedQuantity <= 0 ||
        targetItem.inspectedQuantity != undoEntry.newQuantity) {
      await _emitMessage(emit, StockingMessage.barcodeRequired, isError: true);
      return;
    }

    emit(state.copyWith(isLoading: true, clearMessage: true));
    try {
      // Restore the pre-scan quantity; the row always stays, even at 0.
      final shelfItems = await _undoScan(
        slipNumber: undoEntry.shelfNumber,
        barcode: undoEntry.barcode,
        previousQuantity: undoEntry.previousQuantity,
      );
      emit(
        state.copyWith(
          items: _mergePersistedShelfRows(
            state.items,
            undoEntry.shelfNumber,
            shelfItems,
          ),
          selectedItemId: targetItem.id,
          isLoading: false,
        ),
      );
    } on ReceivingRepositoryException {
      emit(state.copyWith(isLoading: false));
      await _emitMessage(emit, StockingMessage.noScanDataToUndo, isError: true);
    }
  }

  Future<void> _onWorkCompletionConfirmed(
    StockingWorkCompletionConfirmed event,
    Emitter<StockingState> emit,
  ) async {
    if (state.items.isEmpty) {
      await _emitMessage(emit, StockingMessage.noScanData, isError: true);
      return;
    }
    if (state.items.any(
      (item) =>
          item.slipNumber.isEmpty ||
          item.barcode.isEmpty ||
          item.inspectedQuantity < 0,
    )) {
      await _emitMessage(emit, StockingMessage.incompleteRow, isError: true);
      return;
    }

    emit(state.copyWith(isLoading: true, clearMessage: true));
    try {
      await _completeWork(state.items);
    } catch (_) {
      emit(state.copyWith(isLoading: false));
      await _emitMessage(emit, StockingMessage.saveFailed, isError: true);
      return;
    }

    emit(
      state.copyWith(
        items: const [],
        shelfNumber: '',
        clearSelectedItem: true,
        isLoading: false,
        message: StockingMessage.workCompleted,
        messageToken: state.messageToken + 1,
        shouldPop: true,
      ),
    );
    _latestScanUndo = null;
    _resetProductSoundPattern();
    await _feedbackService.playDatabaseSuccess(eventId: event);
  }

  Future<void> _onItemResetConfirmed(
    StockingItemResetConfirmed event,
    Emitter<StockingState> emit,
  ) async {
    ReceivingInspectionItem? selectedItem;
    for (final item in state.items) {
      if (item.id == event.itemId) {
        selectedItem = item;
        break;
      }
    }
    if (selectedItem == null) {
      await _emitMessage(emit, StockingMessage.invalidBarcode, isError: true);
      return;
    }

    if (selectedItem.barcode.isEmpty) {
      emit(
        state.copyWith(
          items: [
            for (final item in state.items)
              if (item.id != selectedItem.id) item,
          ],
          clearSelectedItem: true,
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, clearMessage: true));
    try {
      final shelfItems = selectedItem.inspectedQuantity == 0
          ? await _deleteItem(
              slipNumber: selectedItem.slipNumber,
              itemId: selectedItem.id,
            )
          : await _resetItem(
              slipNumber: selectedItem.slipNumber,
              itemId: selectedItem.id,
            );
      // The row's quantity no longer matches its scan history; drop the
      // stale entry so undo cannot restore a pre-reset quantity.
      if (_latestScanUndo?.shelfNumber == selectedItem.slipNumber &&
          _latestScanUndo?.barcode == selectedItem.barcode) {
        _latestScanUndo = null;
      }
      emit(
        state.copyWith(
          items: _replaceShelfRows(
            state.items,
            selectedItem.slipNumber,
            shelfItems,
          ),
          selectedItemId: selectedItem.inspectedQuantity == 0
              ? null
              : selectedItem.id,
          clearSelectedItem: selectedItem.inspectedQuantity == 0,
          isLoading: false,
        ),
      );
    } on ReceivingRepositoryException catch (error) {
      emit(state.copyWith(isLoading: false));
      await _emitMessage(
        emit,
        error == ReceivingRepositoryException.invalidSlip
            ? StockingMessage.invalidShelfNumber
            : StockingMessage.invalidBarcode,
        isError: true,
      );
    }
  }

  _ProductScanSound _productSoundFor(String value) {
    return _previousScannedProductValue == value
        ? _ProductScanSound.normal
        : _ProductScanSound.differentProduct;
  }

  void _resetProductSoundPattern() {
    _previousScannedProductValue = null;
  }

  @override
  Future<void> close() async {
    await _discardTemporaryWork();
    return super.close();
  }

  static List<ReceivingInspectionItem> _replaceShelfRows(
    List<ReceivingInspectionItem> sessionItems,
    String shelfNumber,
    List<ReceivingInspectionItem> replacementItems,
  ) {
    final firstShelfIndex = sessionItems.indexWhere(
      (item) => item.slipNumber == shelfNumber,
    );
    final otherRows = sessionItems
        .where((item) => item.slipNumber != shelfNumber)
        .toList();
    final insertionIndex = firstShelfIndex < 0
        ? otherRows.length
        : firstShelfIndex.clamp(0, otherRows.length);
    otherRows.insertAll(insertionIndex, replacementItems);
    return otherRows;
  }

  static List<ReceivingInspectionItem> _mergePersistedShelfRows(
    List<ReceivingInspectionItem> sessionItems,
    String shelfNumber,
    List<ReceivingInspectionItem> persistedShelfItems,
  ) {
    final remainingItems = [...persistedShelfItems];
    final orderedItems = <ReceivingInspectionItem>[];

    for (final existingItem in sessionItems.where(
      (item) => item.slipNumber == shelfNumber,
    )) {
      final persistedIndex = remainingItems.indexWhere(
        (item) => item.barcode == existingItem.barcode,
      );
      if (persistedIndex >= 0) {
        orderedItems.add(remainingItems.removeAt(persistedIndex));
      }
    }

    orderedItems.addAll(remainingItems);
    return _replaceShelfRows(sessionItems, shelfNumber, orderedItems);
  }

  Future<void> _emitMessage(
    Emitter<StockingState> emit,
    StockingMessage message, {
    required bool isError,
  }) async {
    emit(
      state.copyWith(message: message, messageToken: state.messageToken + 1),
    );
    if (isError) {
      await _feedbackService.playScanError(eventId: Object());
    }
  }

  static bool _isValidShelfNumber(String value) {
    return AllowedInput.isValidShelf(value);
  }
}

enum _ProductScanSound { normal, differentProduct }

final class _StockingScanUndoEntry {
  const _StockingScanUndoEntry({
    required this.shelfNumber,
    required this.barcode,
    required this.previousQuantity,
    required this.addedQuantity,
    required this.newQuantity,
  });

  final String shelfNumber;
  final String barcode;
  final int previousQuantity;
  final int addedQuantity;
  final int newQuantity;
}
