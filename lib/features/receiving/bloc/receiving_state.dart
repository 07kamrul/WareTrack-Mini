import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';

enum ReceivingMessage {
  slipRequired,
  barcodeRequired,
  quantityRequired,
  invalidSlip,
  invalidBarcode,
  slipLoaded,
  inspectionSaved,
  productChanged,
  workCompleted,
  noScanDataToUndo,
}

final class ReceivingState {
  const ReceivingState({
    this.slipNumber = '',
    this.items = const [],
    this.filter = ReceivingInspectionFilter.all,
    this.selectedItemId,
    this.isLoading = false,
    this.message,
    this.messageToken = 0,
  });

  final String slipNumber;
  final List<ReceivingInspectionItem> items;
  final ReceivingInspectionFilter filter;
  final String? selectedItemId;
  final bool isLoading;
  final ReceivingMessage? message;
  final int messageToken;

  List<ReceivingInspectionItem> get visibleItems {
    return switch (filter) {
      ReceivingInspectionFilter.hide =>
        items.where((item) => !item.isCompleted).toList(growable: false),
      ReceivingInspectionFilter.slipOnly => items,
      ReceivingInspectionFilter.all => items,
    };
  }

  ReceivingInspectionItem? get selectedItem {
    for (final item in items) {
      if (item.id == selectedItemId) {
        return item;
      }
    }
    return null;
  }

  bool get hasSlip => slipNumber.isNotEmpty;

  bool get hasScannedProducts =>
      items.any((item) => item.inspectedQuantity > 0);

  ReceivingState copyWith({
    String? slipNumber,
    List<ReceivingInspectionItem>? items,
    ReceivingInspectionFilter? filter,
    String? selectedItemId,
    bool? clearSelectedItem = false,
    bool? isLoading,
    ReceivingMessage? message,
    bool clearMessage = false,
    int? messageToken,
  }) {
    return ReceivingState(
      slipNumber: slipNumber ?? this.slipNumber,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      selectedItemId: clearSelectedItem == true
          ? null
          : selectedItemId ?? this.selectedItemId,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
      messageToken: messageToken ?? this.messageToken,
    );
  }
}
