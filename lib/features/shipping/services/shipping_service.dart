import 'package:waretrack_mini/core/models/completed_work_models.dart';
import 'package:waretrack_mini/data/local/receiving_repository.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/features/shipping/models/shipping_completed_item_model.dart';
import 'package:waretrack_mini/features/shipping/models/shipping_completed_order_model.dart';

final class ShippingService implements ReceivingRepository {
  const ShippingService({required ReceivingRepository repository})
    : _repository = repository;

  final ReceivingRepository _repository;

  @override
  Future<void> discardTemporaryWork() => _repository.discardTemporaryWork();

  /// Returns completed shipping orders as [ShippingCompletedOrderModel].
  Future<List<ShippingCompletedOrderModel>> loadCompletedOrders() async {
    final records = await _repository.readCompletedWorks();
    return [
      for (final r in records)
        ShippingCompletedOrderModel(
          slipNumber: r.slipNumber,
          totalItems: r.totalItems,
          totalQuantity: r.totalQuantity,
          completedAt: r.completedAt,
        ),
    ];
  }

  /// Returns completed item details for [slipNumber] as
  /// [ShippingCompletedItemModel].
  Future<List<ShippingCompletedItemModel>> loadCompletedItems(
    String slipNumber,
  ) async {
    final records = await _repository.readCompletedWorkDetails(slipNumber);
    return [
      for (final r in records)
        ShippingCompletedItemModel(
          slipNumber: r.slipNumber,
          code: r.code,
          quantity: r.quantity,
          createdAt: r.createdAt,
          userId: r.userId,
        ),
    ];
  }

  Future<List<ReceivingInspectionItem>> loadCurrentWork(String slipNumber) {
    return _repository.readCompletedWorkItems(slipNumber);
  }

  Future<List<ReceivingInspectionItem>> recordScan({
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
  Future<void> deleteCompletedWork(String slipNumber) {
    return _repository.deleteCompletedWork(slipNumber);
  }

  @override
  Future<List<ReceivingInspectionItem>> recordInspection({
    required String slipNumber,
    required String barcode,
    required int quantity,
  }) {
    return recordScan(
      slipNumber: slipNumber,
      barcode: barcode,
      quantity: quantity,
    );
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
  Future<List<ReceivingInspectionItem>> readCompletedWorkItems(
    String slipNumber,
  ) {
    return loadCurrentWork(slipNumber);
  }
}
