import 'package:waretrack_mini/core/models/completed_work_models.dart';
import 'package:waretrack_mini/core/utils/base_repository.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';

abstract interface class ReceivingRepository implements BaseRepository {
  Future<List<ReceivingInspectionItem>> recordInspection({
    required String slipNumber,
    required String barcode,
    required int quantity,
  });

  Future<List<ReceivingInspectionItem>> undoLastScan({
    required String slipNumber,
    required String barcode,
    required int previousQuantity,
  });

  /// Clears scan rows that have not been committed as completed work.
  Future<void> discardTemporaryWork();

  Future<List<ReceivingInspectionItem>> completeWork(String slipNumber);

  Future<List<CompletedOrderRecord>> readCompletedWorks();

  Future<List<CompletedItemRecord>> readCompletedWorkDetails(String slipNumber);

  Future<void> deleteCompletedWork(String slipNumber);

  Future<List<ReceivingInspectionItem>> readCompletedWorkItems(
    String slipNumber,
  );

  Future<List<ReceivingInspectionItem>> resetInspectionItem({
    required String slipNumber,
    required String itemId,
  });

  Future<List<ReceivingInspectionItem>> deleteInspectionItem({
    required String slipNumber,
    required String itemId,
  });
}
