import 'package:waretrack_mini/core/models/completed_work_models.dart';
import 'package:waretrack_mini/core/utils/allowed_input.dart';
import 'package:waretrack_mini/core/utils/base_bloc.dart';
import 'package:waretrack_mini/core/services/scan_feedback_service.dart';
import 'package:waretrack_mini/data/local/receiving_repository_service.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/core/utils/receiving_barcode_value.dart';
import 'package:waretrack_mini/features/receiving/complete_receiving_work_use_case.dart';
import 'package:waretrack_mini/features/receiving/delete_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/load_receiving_completed_work_items_use_case.dart';
import 'package:waretrack_mini/features/receiving/record_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/receiving/reset_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/undo_receiving_scan_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waretrack_mini/features/receiving/bloc/receiving_event.dart';
import 'package:waretrack_mini/features/receiving/bloc/receiving_state.dart';

final class ReceivingBloc extends BaseBloc<ReceivingEvent, ReceivingState> {
  ReceivingBloc({
    required RecordReceivingScanUseCase recordScan,
    required CompleteReceivingWorkUseCase completeWork,
    required LoadReceivingCompletedWorkItemsUseCase loadCompletedWorkItems,
    required ResetReceivingInspectionItemUseCase resetItem,
    required DeleteReceivingInspectionItemUseCase deleteItem,
    required UndoReceivingScanUseCase undoScan,
    required ScanFeedbackService feedbackService,
    required Future<void> Function() discardTemporaryWork,
    required Future<List<CompletedOrderRecord>> Function() readCompletedWorks,
  }) : _recordScan = recordScan,
       _completeWork = completeWork,
       _loadCompletedWorkItems = loadCompletedWorkItems,
       _resetItem = resetItem,
       _deleteItem = deleteItem,
       _undoScan = undoScan,
       _feedbackService = feedbackService,
       _discardTemporaryWork = discardTemporaryWork,
       _readCompletedWorks = readCompletedWorks,
       super(const ReceivingState()) {
    on<ReceivingSlipSubmitted>(_onSlipSubmitted);
    on<ReceivingSessionDiscarded>(_onSessionDiscarded);
    on<ReceivingSavedWorkOpened>(_onSavedWorkOpened);
    on<ReceivingFilterChanged>(_onFilterChanged);
    on<ReceivingItemSelected>(_onItemSelected);
    on<ReceivingItemResetRequested>(_onItemResetRequested);
    on<ReceivingBarcodeSubmitted>(_onBarcodeSubmitted);
    on<ReceivingWorkCompleted>(_onWorkCompleted);
    on<ReceivingLastScanUndoRequested>(_onLastScanUndoRequested);
  }

  final RecordReceivingScanUseCase _recordScan;
  final CompleteReceivingWorkUseCase _completeWork;
  final LoadReceivingCompletedWorkItemsUseCase _loadCompletedWorkItems;
  final ResetReceivingInspectionItemUseCase _resetItem;
  final DeleteReceivingInspectionItemUseCase _deleteItem;
  final UndoReceivingScanUseCase _undoScan;
  final ScanFeedbackService _feedbackService;
  final Future<void> Function() _discardTemporaryWork;
  final Future<List<CompletedOrderRecord>> Function() _readCompletedWorks;
  _ReceivingScanUndoEntry? _latestScanUndo;
  String? _previousScannedProductValue;

  Future<void> _onSlipSubmitted(
    ReceivingSlipSubmitted event,
    Emitter<ReceivingState> emit,
  ) async {
    final normalizedSlip = event.slipNumber.trim();
    _latestScanUndo = null;
    _resetProductSoundPattern();

    await _discardTemporaryWork();

    if (normalizedSlip.isEmpty) {
      emit(
        state.copyWith(
          slipNumber: '',
          items: const [],
          isLoading: false,
          clearSelectedItem: true,
        ),
      );
      await _emitMessage(emit, ReceivingMessage.slipRequired, isError: true);
      return;
    }

    if (!_isValidSlipNumber(normalizedSlip)) {
      emit(
        state.copyWith(
          slipNumber: '',
          items: const [],
          isLoading: false,
          clearSelectedItem: true,
        ),
      );
      await _emitMessage(emit, ReceivingMessage.invalidSlip, isError: true);
      return;
    }

    emit(
      state.copyWith(
        isLoading: false,
        slipNumber: normalizedSlip,
        items: const [],
        clearSelectedItem: true,
        clearMessage: true,
      ),
    );
  }

  Future<void> _onSessionDiscarded(
    ReceivingSessionDiscarded event,
    Emitter<ReceivingState> emit,
  ) async {
    await _discardTemporaryWork();
    _latestScanUndo = null;
    _resetProductSoundPattern();
    emit(
      ReceivingState(
        filter: ReceivingInspectionFilter.all,
        messageToken: state.messageToken,
      ),
    );
  }

  Future<void> _onSavedWorkOpened(
    ReceivingSavedWorkOpened event,
    Emitter<ReceivingState> emit,
  ) async {
    final normalizedSlip = event.slipNumber.trim();
    _latestScanUndo = null;
    _resetProductSoundPattern();

    if (normalizedSlip.isEmpty || !_isValidSlipNumber(normalizedSlip)) {
      emit(
        state.copyWith(
          slipNumber: '',
          items: const [],
          isLoading: false,
          clearSelectedItem: true,
        ),
      );
      await _emitMessage(emit, ReceivingMessage.invalidSlip, isError: true);
      return;
    }

    emit(
      state.copyWith(
        isLoading: true,
        slipNumber: normalizedSlip,
        items: const [],
        clearSelectedItem: true,
        clearMessage: true,
      ),
    );

    try {
      final items = await _loadCompletedWorkItems(normalizedSlip);
      emit(
        state.copyWith(
          slipNumber: normalizedSlip,
          items: items,
          isLoading: false,
          clearSelectedItem: true,
          message: ReceivingMessage.slipLoaded,
          messageToken: state.messageToken + 1,
        ),
      );
    } on ReceivingRepositoryException {
      emit(state.copyWith(isLoading: false));
      await _emitMessage(emit, ReceivingMessage.invalidSlip, isError: true);
    }
  }

  void _onFilterChanged(
    ReceivingFilterChanged event,
    Emitter<ReceivingState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onItemSelected(
    ReceivingItemSelected event,
    Emitter<ReceivingState> emit,
  ) {
    emit(state.copyWith(selectedItemId: event.itemId));
  }

  Future<void> _onItemResetRequested(
    ReceivingItemResetRequested event,
    Emitter<ReceivingState> emit,
  ) async {
    if (!_isValidSlipNumber(state.slipNumber)) {
      await _emitMessage(emit, ReceivingMessage.invalidSlip, isError: true);
      return;
    }

    ReceivingInspectionItem? selectedItem;
    for (final item in state.items) {
      if (item.id == event.itemId) {
        selectedItem = item;
        break;
      }
    }

    if (selectedItem == null) {
      await _emitMessage(emit, ReceivingMessage.invalidBarcode, isError: true);
      return;
    }

    emit(state.copyWith(isLoading: true, clearMessage: true));

    try {
      final items = selectedItem.inspectedQuantity == 0
          ? await _deleteItem(
              slipNumber: state.slipNumber,
              itemId: selectedItem.id,
            )
          : await _resetItem(
              slipNumber: state.slipNumber,
              itemId: selectedItem.id,
            );

      // The row's quantity no longer matches its scan history; drop the
      // stale entry so undo cannot restore a pre-reset quantity.
      if (_latestScanUndo?.barcode == selectedItem.barcode) {
        _latestScanUndo = null;
      }

      emit(
        state.copyWith(
          items: items,
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
            ? ReceivingMessage.invalidSlip
            : ReceivingMessage.invalidBarcode,
        isError: true,
      );
    }
  }

  Future<void> _onBarcodeSubmitted(
    ReceivingBarcodeSubmitted event,
    Emitter<ReceivingState> emit,
  ) async {
    final normalizedBarcode = event.isOcr
        ? ReceivingBarcodeValue.normalizeOcrForInspectionList(event.barcode)
        : ReceivingBarcodeValue.normalizeForInspectionList(event.barcode);
    final quantity = int.tryParse(event.quantityText.trim());

    if (!_isValidSlipNumber(state.slipNumber)) {
      await _emitMessage(emit, ReceivingMessage.invalidSlip, isError: true);
      return;
    }

    if (normalizedBarcode == null) {
      await _emitMessage(emit, ReceivingMessage.barcodeRequired, isError: true);
      return;
    }

    if (quantity == null || quantity <= 0) {
      await _emitMessage(
        emit,
        ReceivingMessage.quantityRequired,
        isError: true,
      );
      return;
    }

    emit(state.copyWith(isLoading: true, clearMessage: true));

    try {
      final items = await _recordScan(
        RecordReceivingScanParams(
          slipNumber: state.slipNumber,
          barcode: normalizedBarcode,
          quantity: quantity,
        ),
      );
      final updatedItem = items.firstWhere(
        (item) => item.barcode == normalizedBarcode,
      );
      final reorderedItems = [
        updatedItem,
        for (final item in items)
          if (item.id != updatedItem.id) item,
      ];
      final productChanged =
          _previousScannedProductValue != null &&
          _previousScannedProductValue != normalizedBarcode;
      final sound = _productSoundFor(normalizedBarcode);
      emit(
        state.copyWith(
          items: reorderedItems,
          selectedItemId: updatedItem.id,
          isLoading: false,
          message: productChanged
              ? ReceivingMessage.productChanged
              : ReceivingMessage.inspectionSaved,
          messageToken: state.messageToken + 1,
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
      _latestScanUndo = _ReceivingScanUndoEntry(
        slipNumber: state.slipNumber,
        barcode: normalizedBarcode,
        previousQuantity: previousQuantity,
        addedQuantity: quantity,
        newQuantity: updatedItem.inspectedQuantity,
      );
      if (sound == _ProductScanSound.differentProduct) {
        await _feedbackService.playDifferentProduct(eventId: event);
      } else {
        await _feedbackService.playProductScanSuccess(eventId: event);
      }
      _previousScannedProductValue = normalizedBarcode;
    } on ReceivingRepositoryException catch (error) {
      emit(state.copyWith(isLoading: false));
      await _emitMessage(
        emit,
        error == ReceivingRepositoryException.invalidSlip
            ? ReceivingMessage.invalidSlip
            : ReceivingMessage.invalidBarcode,
        isError: true,
      );
    }
  }

  Future<void> _onWorkCompleted(
    ReceivingWorkCompleted event,
    Emitter<ReceivingState> emit,
  ) async {
    if (!_isValidSlipNumber(state.slipNumber)) {
      await _emitMessage(emit, ReceivingMessage.invalidSlip, isError: true);
      return;
    }

    emit(state.copyWith(isLoading: true, clearMessage: true));

    try {
      final items = await _completeWork(state.slipNumber);
      emit(
        state.copyWith(
          items: items,
          isLoading: false,
          message: ReceivingMessage.workCompleted,
          messageToken: state.messageToken + 1,
        ),
      );
      _latestScanUndo = null;
      _resetProductSoundPattern();
      await _feedbackService.playDatabaseSuccess(eventId: event);
    } on ReceivingRepositoryException {
      emit(state.copyWith(isLoading: false));
      await _emitMessage(emit, ReceivingMessage.invalidSlip, isError: true);
    }
  }

  Future<void> _onLastScanUndoRequested(
    ReceivingLastScanUndoRequested event,
    Emitter<ReceivingState> emit,
  ) async {
    // Only the most recent scan/insert can be undone, exactly once: the entry
    // is consumed by this press, so pressing again without a new scan asks
    // for a barcode instead of undoing anything further.
    final undoEntry = _latestScanUndo;
    _latestScanUndo = null;
    final targetItem = undoEntry == null
        ? null
        : state.items
              .where((item) => item.barcode == undoEntry.barcode)
              .firstOrNull;
    if (undoEntry == null ||
        targetItem == null ||
        undoEntry.addedQuantity <= 0 ||
        targetItem.inspectedQuantity != undoEntry.newQuantity) {
      await _emitMessage(
        emit,
        ReceivingMessage.barcodeRequired,
        isError: true,
      );
      return;
    }

    emit(state.copyWith(isLoading: true, clearMessage: true));

    try {
      // Restore the pre-scan quantity; the row always stays, even at 0.
      final items = await _undoScan(
        slipNumber: undoEntry.slipNumber,
        barcode: undoEntry.barcode,
        previousQuantity: undoEntry.previousQuantity,
      );
      emit(
        state.copyWith(
          items: items,
          selectedItemId: targetItem.id,
          isLoading: false,
        ),
      );
    } on ReceivingRepositoryException {
      emit(state.copyWith(isLoading: false));
      await _emitMessage(
        emit,
        ReceivingMessage.noScanDataToUndo,
        isError: true,
      );
    }
  }

  _ProductScanSound _productSoundFor(String scannedValue) {
    return _previousScannedProductValue == scannedValue
        ? _ProductScanSound.normal
        : _ProductScanSound.differentProduct;
  }

  void _resetProductSoundPattern() {
    _previousScannedProductValue = null;
  }

  Future<void> _emitMessage(
    Emitter<ReceivingState> emit,
    ReceivingMessage message, {
    required bool isError,
  }) async {
    emit(
      state.copyWith(message: message, messageToken: state.messageToken + 1),
    );

    if (isError) {
      await _feedbackService.playScanError(eventId: Object());
    }
  }

  /// Returns whether a completed work already exists for [slipNumber] in the
  /// saved (SQLite) data. Used to decide between opening an existing order in
  /// edit mode and starting a brand new order.
  Future<bool> savedWorkExists(String slipNumber) async {
    final normalizedSlip = slipNumber.trim();
    if (normalizedSlip.isEmpty || !_isValidSlipNumber(normalizedSlip)) {
      return false;
    }

    final works = await _readCompletedWorks();
    return works.any((work) => work.slipNumber == normalizedSlip);
  }

  static bool _isValidSlipNumber(String slipNumber) {
    return AllowedInput.isValidSlip(slipNumber);
  }

  @override
  Future<void> close() async {
    await _discardTemporaryWork();
    return super.close();
  }
}

enum _ProductScanSound { normal, differentProduct }

final class _ReceivingScanUndoEntry {
  const _ReceivingScanUndoEntry({
    required this.slipNumber,
    required this.barcode,
    required this.previousQuantity,
    required this.addedQuantity,
    required this.newQuantity,
  });

  final String slipNumber;
  final String barcode;
  final int previousQuantity;
  final int addedQuantity;
  final int newQuantity;
}
