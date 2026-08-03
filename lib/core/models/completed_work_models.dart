import 'package:waretrack_mini/core/models/inspection_work_type.dart';

/// Common interface for a completed work order record (one record per
/// slip/session). Each feature implements this with its own concrete class.
abstract interface class CompletedOrderRecord {
  /// The slip number (or shelf identifier for stocking).
  String get slipNumber;

  /// Number of distinct barcodes in this order.
  int get totalItems;

  /// Total scanned quantity across all items.
  int get totalQuantity;

  /// Timestamp when the work session was completed.
  DateTime get completedAt;

  /// Identifies which menu this record belongs to.
  InspectionWorkType get workType;

  /// Human-readable menu label (e.g. '入荷検品').
  String get menuName;

  /// Whether this order has already been sent successfully by email/API.
  /// Persisted in SQLite so the "sent" indicator survives app restarts.
  bool get isSent;
}

/// Common interface for a completed work item record (one record per
/// scanned barcode within a completed session).
/// Each feature implements this with its own concrete class.
abstract interface class CompletedItemRecord {
  /// The slip/session key used as the first export column.
  /// For stocking this holds the shelf number.
  String get slipNumber;

  /// The scanned barcode / product code.
  String get code;

  /// Scanned quantity.
  int get quantity;

  /// Timestamp of the scan (named `createdAt` for interface uniformity).
  DateTime get createdAt;

  /// Operator / user ID at the time of scanning.
  String get userId;

  CompletedItemRecord copyWith({
    String? slipNumber,
    String? code,
    int? quantity,
    DateTime? createdAt,
    String? userId,
  });
}
