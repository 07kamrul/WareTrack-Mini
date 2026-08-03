import 'package:waretrack_mini/core/models/completed_work_models.dart';

/// Completed work item model for 棚入れ (Stocking).
///
/// The [slipNumber] field stores the **shelf number** — consistent with how the
/// SQLite `stocking_completed_items` table maps `shelf_number` into the first
/// export column.  The [code] field holds the scanned barcode/QR value and
/// [createdAt] corresponds to the `scanned_at` database column.
final class StockingCompletedItemModel implements CompletedItemRecord {
  const StockingCompletedItemModel({
    required this.slipNumber,
    required this.code,
    required this.quantity,
    required this.createdAt,
    required this.userId,
  });

  /// Shelf number (棚番号). Stored in [slipNumber] to align with the
  /// [CompletedItemRecord] interface and the export column layout.
  @override
  final String slipNumber;
  @override
  final String code;
  @override
  final int quantity;
  @override
  final DateTime createdAt;
  @override
  final String userId;

  @override
  StockingCompletedItemModel copyWith({
    String? slipNumber,
    String? code,
    int? quantity,
    DateTime? createdAt,
    String? userId,
  }) {
    return StockingCompletedItemModel(
      slipNumber: slipNumber ?? this.slipNumber,
      code: code ?? this.code,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}
