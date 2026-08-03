import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/constants/verification_storage_keys.dart';
import 'package:waretrack_mini/core/database/app_database.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/data/local/receiving_repository_service.dart';
import 'package:waretrack_mini/data/models/receiving_completed_work.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';

void main() {
  group('ReceivingRepositoryImpl', () {
    test(
      'discarded temporary scans are not merged into a new session',
      () async {
        final repository = _createRepository();

        await repository.recordInspection(
          slipNumber: 'SLIP-9001',
          barcode: 'OLD',
          quantity: 1,
        );
        await repository.discardTemporaryWork();

        final items = await repository.recordInspection(
          slipNumber: 'SLIP-9001',
          barcode: 'NEW',
          quantity: 1,
        );

        expect(items.map((item) => item.barcode), ['NEW']);
      },
    );

    test('preserves slip text case for a new slip and code', () async {
      final repository = _createRepository();

      final items = await repository.recordInspection(
        slipNumber: 'slip-9001',
        barcode: 'code-001',
        quantity: 3,
      );

      expect(items, hasLength(1));
      expect(items.single.slipNumber, 'slip-9001');
      expect(items.single.barcode, 'code-001');
      expect(items.single.inspectedQuantity, 3);
    });

    test(
      'preserves scanned text case and symbols in inspection rows',
      () async {
        final repository = _createRepository();

        final items = await repository.recordInspection(
          slipNumber: 'SLIP-9001',
          barcode: 'ab12-3456ab~xY',
          quantity: 1,
        );

        expect(items.single.barcode, 'ab12-3456ab~xY');
      },
    );

    test(
      'increases quantity when the same code exists for the same slip',
      () async {
        final repository = _createRepository();

        await repository.recordInspection(
          slipNumber: 'SLIP-9001',
          barcode: 'CODE-001',
          quantity: 3,
        );
        final items = await repository.recordInspection(
          slipNumber: 'SLIP-9001',
          barcode: 'CODE-001',
          quantity: 2,
        );

        expect(items, hasLength(1));
        expect(items.single.slipNumber, 'SLIP-9001');
        expect(items.single.barcode, 'CODE-001');
        expect(items.single.inspectedQuantity, 5);
      },
    );

    test('keeps same code in a different slip as a separate row', () async {
      final repository = _createRepository();

      await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'CODE-001',
        quantity: 3,
      );
      final items = await repository.recordInspection(
        slipNumber: 'SLIP-9002',
        barcode: 'CODE-001',
        quantity: 2,
      );

      expect(items, hasLength(1));
      expect(items.single.slipNumber, 'SLIP-9002');
      expect(items.single.barcode, 'CODE-001');
      expect(items.single.inspectedQuantity, 2);
    });

    test('returns inspection rows in newest scan first order', () async {
      final repository = _createRepository();

      await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'CODE-001',
        quantity: 1,
      );
      await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'CODE-002',
        quantity: 1,
      );
      final items = await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'CODE-003',
        quantity: 1,
      );

      expect(
        items.map((item) => item.barcode),
        orderedEquals(<String>['CODE-003', 'CODE-002', 'CODE-001']),
      );
    });

    test('moves an existing row to the top when it is scanned again', () async {
      final repository = _createRepository();

      await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'CODE-001',
        quantity: 1,
      );
      await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'CODE-002',
        quantity: 1,
      );
      final items = await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'CODE-001',
        quantity: 2,
      );

      expect(
        items.map((item) => item.barcode),
        orderedEquals(<String>['CODE-001', 'CODE-002']),
      );
      expect(items.first.inspectedQuantity, 3);
    });

    test('resets an inspection row quantity to zero', () async {
      final repository = _createRepository();

      final initialItems = await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'CODE-001',
        quantity: 3,
      );
      final items = await repository.resetInspectionItem(
        slipNumber: 'SLIP-9001',
        itemId: initialItems.single.id,
      );

      expect(items, hasLength(1));
      expect(items.single.inspectedQuantity, 0);
      expect(items.single.status, ReceivingInspectionStatus.pending);
    });

    test(
      'undo last scan restores the quantity before the scan action',
      () async {
        final repository = _createRepository();

        await repository.recordInspection(
          slipNumber: 'SLIP-9001',
          barcode: 'CODE-001',
          quantity: 3,
        );
        await repository.recordInspection(
          slipNumber: 'SLIP-9001',
          barcode: 'CODE-001',
          quantity: 2,
        );
        final items = await repository.undoLastScan(
          slipNumber: 'SLIP-9001',
          barcode: 'CODE-001',
          previousQuantity: 3,
        );

        expect(items.single.inspectedQuantity, 3);
      },
    );

    test('undo latest inserted value without changing older values', () async {
      final repository = _createRepository();

      await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'A',
        quantity: 5,
      );
      await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'B',
        quantity: 1,
      );
      final items = await repository.undoLastScan(
        slipNumber: 'SLIP-9001',
        barcode: 'B',
        previousQuantity: 0,
      );

      expect(
        items.singleWhere((item) => item.barcode == 'A').inspectedQuantity,
        5,
      );
      expect(
        items.singleWhere((item) => item.barcode == 'B').inspectedQuantity,
        0,
      );
    });

    test('reset keeps remaining rows in their current scan order', () async {
      final repository = _createRepository();

      await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'CODE-001',
        quantity: 1,
      );
      final latestItems = await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'CODE-002',
        quantity: 1,
      );
      final olderItem = latestItems.singleWhere(
        (item) => item.barcode == 'CODE-001',
      );

      final items = await repository.resetInspectionItem(
        slipNumber: 'SLIP-9001',
        itemId: olderItem.id,
      );

      expect(
        items.map((item) => item.barcode),
        orderedEquals(<String>['CODE-002', 'CODE-001']),
      );
      expect(items.first.inspectedQuantity, 1);
    });

    test('deletes a selected inspection row', () async {
      final repository = _createRepository();

      final initialItems = await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'CODE-001',
        quantity: 3,
      );
      final items = await repository.deleteInspectionItem(
        slipNumber: 'SLIP-9001',
        itemId: initialItems.single.id,
      );

      expect(items, isEmpty);
    });

    test(
      'updates completed work total item count from inspection rows',
      () async {
        final database = _FakeAppDatabase();
        final repository = _createRepository(database: database);

        final firstItems = await repository.recordInspection(
          slipNumber: 'SLIP-9001',
          barcode: 'CODE-001',
          quantity: 3,
        );
        final secondItems = await repository.recordInspection(
          slipNumber: 'SLIP-9001',
          barcode: 'CODE-002',
          quantity: 2,
        );
        await repository.completeWork('SLIP-9001');

        var completedWorks = await repository.readCompletedWorks();
        expect(completedWorks.single.totalItems, 2);
        expect(completedWorks.single.totalQuantity, 5);

        await repository.resetInspectionItem(
          slipNumber: 'SLIP-9001',
          itemId: firstItems.single.id,
        );
        await repository.completeWork('SLIP-9001');

        completedWorks = await repository.readCompletedWorks();
        expect(completedWorks.single.totalItems, 1);
        expect(completedWorks.single.totalQuantity, 2);

        final secondItem = secondItems.singleWhere(
          (item) => item.barcode == 'CODE-002',
        );
        await repository.deleteInspectionItem(
          slipNumber: 'SLIP-9001',
          itemId: secondItem.id,
        );
        await repository.completeWork('SLIP-9001');

        completedWorks = await repository.readCompletedWorks();
        expect(completedWorks.single.totalItems, 0);
        expect(completedWorks.single.totalQuantity, 0);
      },
    );

    test('stores verified user code when completing work', () async {
      final database = _FakeAppDatabase();
      final repository = _createRepository(database: database);

      await repository.recordInspection(
        slipNumber: 'SLIP-9001',
        barcode: 'CODE-001',
        quantity: 3,
      );
      await repository.completeWork('SLIP-9001');

      final details = await repository.readCompletedWorkDetails('SLIP-9001');
      expect(details.single.userId, 'USER-007');
    });
  });
}

ReceivingRepositoryImpl _createRepository({_FakeAppDatabase? database}) {
  return ReceivingRepositoryImpl(
    localStorage: _FakeLocalStorage(),
    database: database ?? _FakeAppDatabase(),
  );
}

final class _FakeLocalStorage implements LocalStorage {
  final Map<String, String> values = <String, String>{
    kCode: 'USER-007',
    'receiving_inspections': jsonEncode(<Map<String, Object?>>[
      _itemToJson(
        const ReceivingInspectionItem(
          id: 'RCV-OTHER-001',
          slipNumber: 'OTHER',
          barcode: 'EXISTING',
          productName: '',
          expectedQuantity: 1,
          inspectedQuantity: 1,
          status: ReceivingInspectionStatus.completed,
        ),
      ),
    ]),
  };

  @override
  Future<bool?> readBool(String key) async {
    final value = values[key];
    return value == null ? null : bool.tryParse(value);
  }

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    values[key] = value.toString();
  }

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }

  static Map<String, Object?> _itemToJson(ReceivingInspectionItem item) {
    return {
      'id': item.id,
      'slipNumber': item.slipNumber,
      'barcode': item.barcode,
      'productName': item.productName,
      'expectedQuantity': item.expectedQuantity,
      'inspectedQuantity': item.inspectedQuantity,
      'status': item.status.name,
    };
  }
}

final class _FakeAppDatabase implements AppDatabase {
  final List<ReceivingCompletedWork> works = <ReceivingCompletedWork>[];
  final Map<String, List<ReceivingCompletedWorkDetail>> details =
      <String, List<ReceivingCompletedWorkDetail>>{};

  @override
  Future<List<ReceivingCompletedWork>> readCompletedWorks({
    required InspectionWorkType workType,
  }) async {
    return works.where((work) => work.workType == workType).toList();
  }

  @override
  Future<List<ReceivingCompletedWorkDetail>> readCompletedWorkDetails(
    String slipNumber, {
    required InspectionWorkType workType,
  }) async {
    return details['${workType.name}:${slipNumber.trim()}'] ?? const [];
  }

  @override
  Future<void> deleteCompletedWork(
    String slipNumber, {
    required InspectionWorkType workType,
  }) async {
    final normalizedSlip = slipNumber.trim();
    works.removeWhere(
      (work) => work.slipNumber == normalizedSlip && work.workType == workType,
    );
    details.remove('${workType.name}:$normalizedSlip');
  }

  @override
  Future<void> saveCompletedWork({
    required String slipNumber,
    required List<ReceivingInspectionItem> items,
    required InspectionWorkType workType,
    required String userId,
  }) async {
    final completedItems = items
        .where((item) => item.inspectedQuantity > 0)
        .toList(growable: false);
    final totalQuantity = completedItems.fold<int>(
      0,
      (total, item) => total + item.inspectedQuantity,
    );

    works
      ..removeWhere(
        (work) => work.slipNumber == slipNumber && work.workType == workType,
      )
      ..add(
        ReceivingCompletedWork(
          slipNumber: slipNumber,
          totalItems: completedItems.length,
          totalQuantity: totalQuantity,
          completedAt: DateTime.now(),
          workType: workType,
        ),
      );

    details['${workType.name}:$slipNumber'] = [
      for (final item in completedItems)
        ReceivingCompletedWorkDetail(
          slipNumber: item.slipNumber,
          code: item.barcode,
          quantity: item.inspectedQuantity,
          createdAt: DateTime.now(),
          userId: userId,
          workType: workType,
        ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
