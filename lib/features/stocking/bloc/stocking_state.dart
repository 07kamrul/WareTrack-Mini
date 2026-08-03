import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/features/stocking/bloc/stocking_event.dart';

enum StockingMessage {
  shelfNumberRequired,
  barcodeRequired,
  quantityRequired,
  invalidShelfNumber,
  invalidBarcode,
  inspectionSaved,
  productChanged,
  workCompleted,
  noScanDataToUndo,
  noScanData,
  incompleteRow,
  saveFailed,
}

final class StockingState {
  const StockingState({
    this.selectedMode = StockingScanMode.shelfNumber,
    this.shelfNumber = '',
    this.items = const [],
    this.selectedItemId,
    this.barcode = '',
    this.quantity = '1',
    this.isLoading = false,
    this.message,
    this.messageToken = 0,
    this.showProductChangedNotice = false,
    this.shouldPop = false,
    this.clearInputToken = 0,
  });

  final StockingScanMode selectedMode;
  final String shelfNumber;
  final List<ReceivingInspectionItem> items;
  final String? selectedItemId;
  final String barcode;
  final String quantity;
  final bool isLoading;
  final StockingMessage? message;
  final int messageToken;
  final bool showProductChangedNotice;
  final bool shouldPop;

  /// Increments whenever a manual input is successfully processed, signalling
  /// the UI to clear the barcode/QR field, reset the quantity to its default
  /// and restore focus for the next entry. Scans do not bump this token.
  final int clearInputToken;

  List<ReceivingInspectionItem> get visibleItems => items;

  bool get hasScannedProducts => items.isNotEmpty;

  StockingState copyWith({
    StockingScanMode? selectedMode,
    String? shelfNumber,
    List<ReceivingInspectionItem>? items,
    String? selectedItemId,
    bool clearSelectedItem = false,
    String? barcode,
    String? quantity,
    bool? isLoading,
    StockingMessage? message,
    bool clearMessage = false,
    int? messageToken,
    bool? showProductChangedNotice,
    bool? shouldPop,
    int? clearInputToken,
  }) {
    return StockingState(
      selectedMode: selectedMode ?? this.selectedMode,
      shelfNumber: shelfNumber ?? this.shelfNumber,
      items: items ?? this.items,
      selectedItemId: clearSelectedItem
          ? null
          : selectedItemId ?? this.selectedItemId,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
      messageToken: messageToken ?? this.messageToken,
      showProductChangedNotice:
          showProductChangedNotice ?? this.showProductChangedNotice,
      shouldPop: shouldPop ?? this.shouldPop,
      clearInputToken: clearInputToken ?? this.clearInputToken,
    );
  }
}
