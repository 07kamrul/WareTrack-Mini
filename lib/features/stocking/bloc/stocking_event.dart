enum StockingScanMode { shelfNumber, product }

sealed class StockingEvent {
  const StockingEvent();
}

final class StockingSessionStarted extends StockingEvent {
  const StockingSessionStarted();
}

final class StockingScanModeChanged extends StockingEvent {
  const StockingScanModeChanged(this.mode);

  final StockingScanMode mode;
}

final class StockingScanValueSubmitted extends StockingEvent {
  const StockingScanValueSubmitted(this.value, {this.isOcr = false});

  final String value;

  /// True when [value] came from an OCR capture. OCR values are preserved
  /// verbatim; barcode/QR and manual input keep their existing normalization.
  final bool isOcr;
}

final class StockingExternalInputChanged extends StockingEvent {
  const StockingExternalInputChanged(this.value);

  final String value;
}

final class StockingQuantityChanged extends StockingEvent {
  const StockingQuantityChanged(this.value);

  final String value;
}

final class StockingProductChangedNoticeCleared extends StockingEvent {
  const StockingProductChangedNoticeCleared();
}

final class StockingBarcodeSubmitted extends StockingEvent {
  const StockingBarcodeSubmitted({
    required this.barcode,
    required this.quantityText,
  });

  final String barcode;
  final String quantityText;
}

final class StockingUndoRequested extends StockingEvent {
  const StockingUndoRequested();
}

final class StockingWorkCompletionConfirmed extends StockingEvent {
  const StockingWorkCompletionConfirmed();
}

final class StockingItemResetConfirmed extends StockingEvent {
  const StockingItemResetConfirmed(this.itemId);

  final String itemId;
}
