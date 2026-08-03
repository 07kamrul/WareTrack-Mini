import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';

sealed class ReceivingEvent {
  const ReceivingEvent();
}

final class ReceivingSlipSubmitted extends ReceivingEvent {
  const ReceivingSlipSubmitted(this.slipNumber);

  final String slipNumber;
}

final class ReceivingSessionDiscarded extends ReceivingEvent {
  const ReceivingSessionDiscarded();
}

final class ReceivingSavedWorkOpened extends ReceivingEvent {
  const ReceivingSavedWorkOpened(this.slipNumber);

  final String slipNumber;
}

final class ReceivingFilterChanged extends ReceivingEvent {
  const ReceivingFilterChanged(this.filter);

  final ReceivingInspectionFilter filter;
}

final class ReceivingItemSelected extends ReceivingEvent {
  const ReceivingItemSelected(this.itemId);

  final String itemId;
}

final class ReceivingItemResetRequested extends ReceivingEvent {
  const ReceivingItemResetRequested(this.itemId);

  final String itemId;
}

final class ReceivingBarcodeSubmitted extends ReceivingEvent {
  const ReceivingBarcodeSubmitted({
    required this.barcode,
    required this.quantityText,
    this.isOcr = false,
  });

  final String barcode;
  final String quantityText;

  /// True when [barcode] came from an OCR capture. OCR values are preserved
  /// verbatim; barcode/QR and manual input keep their existing normalization.
  final bool isOcr;
}

final class ReceivingWorkCompleted extends ReceivingEvent {
  const ReceivingWorkCompleted();
}

final class ReceivingLastScanUndoRequested extends ReceivingEvent {
  const ReceivingLastScanUndoRequested();
}
