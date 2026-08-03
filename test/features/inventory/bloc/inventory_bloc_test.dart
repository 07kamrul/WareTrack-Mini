import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/services/scan_feedback_service.dart';
import 'package:waretrack_mini/data/local/receiving_repository.dart';
import 'package:waretrack_mini/data/models/receiving_completed_work.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/features/inventory/bloc/inventory_bloc.dart';
import 'package:waretrack_mini/features/receiving/delete_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/record_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/receiving/reset_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/undo_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/stocking/bloc/stocking_bloc.dart';
import 'package:waretrack_mini/features/stocking/bloc/stocking_event.dart';

void main() {
  group('InventoryBloc product registration', () {
    late _MemoryReceivingRepository repository;
    late InventoryBloc bloc;

    setUp(() {
      repository = _MemoryReceivingRepository();
      bloc = InventoryBloc(
        recordScan: RecordReceivingScanUseCase(repository),
        completeWork: (items) async => items,
        resetItem: ResetReceivingInspectionItemUseCase(repository),
        deleteItem: DeleteReceivingInspectionItemUseCase(repository),
        undoScan: UndoReceivingScanUseCase(repository),
        discardTemporaryWork: repository.discardTemporaryWork,
        feedbackService: _SilentScanFeedbackService(),
      );
    });

    tearDown(() => bloc.close());

    test('reuses the stocking registration flow', () {
      // Inventory inherits every behaviour — including the input reset — from
      // StockingBloc, so the same guarantees apply to the Stocktaking menu.
      expect(bloc, isA<StockingBloc>());
    });

    test(
      'registering a product resets the inputs while keeping the saved '
      'quantity',
      () async {
        bloc.add(const StockingScanValueSubmitted('abc'));
        await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');
        bloc.add(const StockingScanModeChanged(StockingScanMode.product));
        await bloc.stream.firstWhere(
          (state) => state.selectedMode == StockingScanMode.product,
        );

        // The user bumps the quantity to 10 before registering the product.
        bloc.add(const StockingQuantityChanged('10'));
        await bloc.stream.firstWhere((state) => state.quantity == '10');

        bloc.add(const StockingScanValueSubmitted('123'));
        await bloc.stream.firstWhere(
          (state) =>
              state.items.length == 1 &&
              state.items.single.inspectedQuantity == 10,
        );

        // After a successful add the inputs reset to the defaults...
        expect(bloc.state.barcode, '');
        expect(bloc.state.quantity, '1');
        // ...but the product just registered keeps the entered quantity.
        expect(repository.items.single.inspectedQuantity, 10);
      },
    );
  });
}

final class _SilentScanFeedbackService extends ScanFeedbackService {
  @override
  Future<void> playDatabaseSuccess({Object? eventId}) async {}

  @override
  Future<void> playDifferentProduct({Object? eventId}) async {}

  @override
  Future<void> playProductScanSuccess({Object? eventId}) async {}

  @override
  Future<void> playScanError({Object? eventId}) async {}
}

final class _MemoryReceivingRepository implements ReceivingRepository {
  final List<ReceivingInspectionItem> _items = [];

  List<ReceivingInspectionItem> get items => List.unmodifiable(_items);

  @override
  Future<void> discardTemporaryWork() async => _items.clear();

  @override
  Future<List<ReceivingInspectionItem>> recordInspection({
    required String slipNumber,
    required String barcode,
    required int quantity,
  }) async {
    final existingIndex = _items.indexWhere(
      (item) => item.slipNumber == slipNumber && item.barcode == barcode,
    );
    if (existingIndex == -1) {
      _items.insert(
        0,
        ReceivingInspectionItem(
          id: '$slipNumber-$barcode',
          slipNumber: slipNumber,
          barcode: barcode,
          productName: '',
          expectedQuantity: quantity,
          inspectedQuantity: quantity,
          status: ReceivingInspectionStatus.completed,
        ),
      );
    } else {
      final item = _items[existingIndex];
      _items[existingIndex] = item.copyWith(
        inspectedQuantity: item.inspectedQuantity + quantity,
      );
    }
    return List.unmodifiable(
      _items.where((item) => item.slipNumber == slipNumber),
    );
  }

  @override
  Future<List<ReceivingInspectionItem>> completeWork(String slipNumber) async =>
      List.unmodifiable(_items);

  @override
  Future<List<ReceivingInspectionItem>> deleteInspectionItem({
    required String slipNumber,
    required String itemId,
  }) async {
    _items.removeWhere((item) => item.id == itemId);
    return List.unmodifiable(_items);
  }

  @override
  Future<List<ReceivingInspectionItem>> resetInspectionItem({
    required String slipNumber,
    required String itemId,
  }) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final item = _items[index];
      _items[index] = item.copyWith(inspectedQuantity: 0);
    }
    return List.unmodifiable(
      _items.where((item) => item.slipNumber == slipNumber),
    );
  }

  @override
  Future<List<ReceivingInspectionItem>> undoLastScan({
    required String slipNumber,
    required String barcode,
    required int previousQuantity,
  }) async => List.unmodifiable(_items);

  @override
  Future<void> deleteCompletedWork(String slipNumber) async {}

  @override
  Future<List<ReceivingCompletedWorkDetail>> readCompletedWorkDetails(
    String slipNumber,
  ) async => const [];

  @override
  Future<List<ReceivingInspectionItem>> readCompletedWorkItems(
    String slipNumber,
  ) async => const [];

  @override
  Future<List<ReceivingCompletedWork>> readCompletedWorks() async => const [];
}
