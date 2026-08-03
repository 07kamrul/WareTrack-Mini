import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/database/app_database.dart';
import 'package:waretrack_mini/core/database/table_names.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/data/local/receiving_repository.dart';
import 'package:waretrack_mini/data/models/receiving_completed_work.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/features/stocking/services/stocking_service.dart';

void main() {
  test(
    'completeSession saves every shelf row with kCode in stocking tables',
    () async {
      final database = _CapturingDatabase();
      final repository = _TrackingRepository();
      final storage = InMemoryLocalStorage();
      await storage.writeString(kCode, 'user-007');
      final service = StockingService(
        repository: repository,
        database: database,
        localStorage: storage,
      );
      final items = [
        _item('row-1', 'abc', '123', 2),
        _item('row-2', 'xyz', '456', 0),
      ];

      final completed = await service.completeSession(items);

      expect(database.workType, InspectionWorkType.stocking);
      expect(database.slipNumber, 'xyz');
      expect(database.userId, 'user-007');
      expect(
        database.items
            ?.map(
              (item) => (item.slipNumber, item.barcode, item.inspectedQuantity),
            )
            .toList(),
        [('abc', '123', 2), ('xyz', '456', 0)],
      );
      expect(
        completed.every(
          (item) => item.status == ReceivingInspectionStatus.completed,
        ),
        isTrue,
      );
      expect(repository.deletedItemIds, ['row-1', 'row-2']);
      expect(AppTables.stockingCompletedOrders, 'stocking_completed_orders');
      expect(
        AppTables.stockingCompletedOrderDetails,
        'stocking_completed_items',
      );
    },
  );
}

ReceivingInspectionItem _item(
  String id,
  String shelfNumber,
  String barcode,
  int quantity,
) {
  return ReceivingInspectionItem(
    id: id,
    slipNumber: shelfNumber,
    barcode: barcode,
    productName: '',
    expectedQuantity: quantity,
    inspectedQuantity: quantity,
    status: ReceivingInspectionStatus.completed,
  );
}

final class _CapturingDatabase implements AppDatabase {
  String? slipNumber;
  List<ReceivingInspectionItem>? items;
  InspectionWorkType? workType;
  String? userId;

  @override
  Future<void> saveCompletedWork({
    required String slipNumber,
    required List<ReceivingInspectionItem> items,
    required InspectionWorkType workType,
    required String userId,
  }) async {
    this.slipNumber = slipNumber;
    this.items = items;
    this.workType = workType;
    this.userId = userId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _TrackingRepository implements ReceivingRepository {
  final List<String> deletedItemIds = [];

  @override
  Future<List<ReceivingInspectionItem>> deleteInspectionItem({
    required String slipNumber,
    required String itemId,
  }) async {
    deletedItemIds.add(itemId);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
