import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/database/app_database.dart';
import 'package:waretrack_mini/core/models/completed_work_models.dart';
import 'package:waretrack_mini/core/models/inspection_work_type.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/data/local/receiving_repository.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/features/stocking/models/stocking_completed_item_model.dart';
import 'package:waretrack_mini/features/stocking/models/stocking_completed_order_model.dart';

/// Stocking service (棚入れ) that delegates to a ReceivingRepository
/// configured with InspectionWorkType.stocking.
/// This mirrors ShippingService to reuse the shared repository infrastructure.
final class StockingService implements ReceivingRepository {
  const StockingService({
    required ReceivingRepository repository,
    required AppDatabase database,
    required LocalStorage localStorage,
  }) : _repository = repository,
       _database = database,
       _localStorage = localStorage;

  final ReceivingRepository _repository;
  final AppDatabase _database;
  final LocalStorage _localStorage;

  @override
  Future<void> discardTemporaryWork() => _repository.discardTemporaryWork();

  Future<List<ReceivingInspectionItem>> completeSession(
    List<ReceivingInspectionItem> items,
  ) async {
    final completedItems = [
      for (final item in items)
        item.copyWith(status: ReceivingInspectionStatus.completed),
    ];
    final workKey = completedItems.last.slipNumber;
    final userId = (await _localStorage.readString(kCode))?.trim() ?? '';

    await _database.saveCompletedWork(
      slipNumber: workKey,
      items: completedItems,
      workType: InspectionWorkType.stocking,
      userId: userId,
    );

    for (final item in completedItems) {
      try {
        await _repository.deleteInspectionItem(
          slipNumber: item.slipNumber,
          itemId: item.id,
        );
      } catch (_) {
        // SQLite is the source of truth after completion.
      }
    }
    return completedItems;
  }

  /// Returns completed stocking orders as [StockingCompletedOrderModel].
  Future<List<StockingCompletedOrderModel>> loadCompletedOrders() async {
    final records = await _repository.readCompletedWorks();
    return [
      for (final r in records)
        StockingCompletedOrderModel(
          slipNumber: r.slipNumber,
          totalItems: r.totalItems,
          totalQuantity: r.totalQuantity,
          completedAt: r.completedAt,
        ),
    ];
  }

  /// Returns completed item details for [slipNumber] as
  /// [StockingCompletedItemModel].  The [slipNumber] field on each item holds
  /// the shelf number, consistent with the export column layout.
  Future<List<StockingCompletedItemModel>> loadCompletedItems(
    String slipNumber,
  ) async {
    final records = await _repository.readCompletedWorkDetails(slipNumber);
    return [
      for (final r in records)
        StockingCompletedItemModel(
          slipNumber: r.slipNumber,
          code: r.code,
          quantity: r.quantity,
          createdAt: r.createdAt,
          userId: r.userId,
        ),
    ];
  }

  @override
  Future<List<ReceivingInspectionItem>> recordInspection({
    required String slipNumber,
    required String barcode,
    required int quantity,
  }) {
    return _repository.recordInspection(
      slipNumber: slipNumber,
      barcode: barcode,
      quantity: quantity,
    );
  }

  @override
  Future<List<ReceivingInspectionItem>> undoLastScan({
    required String slipNumber,
    required String barcode,
    required int previousQuantity,
  }) {
    return _repository.undoLastScan(
      slipNumber: slipNumber,
      barcode: barcode,
      previousQuantity: previousQuantity,
    );
  }

  @override
  Future<List<ReceivingInspectionItem>> completeWork(String slipNumber) {
    return _repository.completeWork(slipNumber);
  }

  @override
  Future<List<CompletedOrderRecord>> readCompletedWorks() {
    return _repository.readCompletedWorks();
  }

  @override
  Future<List<CompletedItemRecord>> readCompletedWorkDetails(
    String slipNumber,
  ) {
    return _repository.readCompletedWorkDetails(slipNumber);
  }

  @override
  Future<void> deleteCompletedWork(String slipNumber) {
    return _repository.deleteCompletedWork(slipNumber);
  }

  @override
  Future<List<ReceivingInspectionItem>> readCompletedWorkItems(
    String slipNumber,
  ) {
    return _repository.readCompletedWorkItems(slipNumber);
  }

  @override
  Future<List<ReceivingInspectionItem>> resetInspectionItem({
    required String slipNumber,
    required String itemId,
  }) {
    return _repository.resetInspectionItem(
      slipNumber: slipNumber,
      itemId: itemId,
    );
  }

  @override
  Future<List<ReceivingInspectionItem>> deleteInspectionItem({
    required String slipNumber,
    required String itemId,
  }) {
    return _repository.deleteInspectionItem(
      slipNumber: slipNumber,
      itemId: itemId,
    );
  }
}
