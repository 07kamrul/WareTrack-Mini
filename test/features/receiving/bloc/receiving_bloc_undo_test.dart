import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/services/scan_feedback_service.dart';
import 'package:waretrack_mini/data/models/receiving_completed_work.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/data/local/receiving_repository.dart';
import 'package:waretrack_mini/features/receiving/complete_receiving_work_use_case.dart';
import 'package:waretrack_mini/features/receiving/delete_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/load_receiving_completed_work_items_use_case.dart';
import 'package:waretrack_mini/features/receiving/record_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/receiving/reset_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/undo_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/receiving/bloc/receiving_bloc.dart';
import 'package:waretrack_mini/features/receiving/bloc/receiving_event.dart';
import 'package:waretrack_mini/features/receiving/bloc/receiving_state.dart';

void main() {
  test('undo restores a newly inserted product back to quantity 0', () async {
    final repository = _FakeReceivingRepository();
    final bloc = ReceivingBloc(
      recordScan: RecordReceivingScanUseCase(repository),
      completeWork: CompleteReceivingWorkUseCase(repository),
      loadCompletedWorkItems: LoadReceivingCompletedWorkItemsUseCase(
        repository,
      ),
      resetItem: ResetReceivingInspectionItemUseCase(repository),
      deleteItem: DeleteReceivingInspectionItemUseCase(repository),
      undoScan: UndoReceivingScanUseCase(repository),
      discardTemporaryWork: () async {},
      readCompletedWorks: repository.readCompletedWorks,
      feedbackService: _SilentScanFeedbackService(),
    );
    addTearDown(bloc.close);

    bloc.add(const ReceivingSlipSubmitted('SLIP-1'));
    await bloc.stream.firstWhere((state) => state.slipNumber == 'SLIP-1');

    // The product was not in the list; one scan inserts it with quantity 20.
    bloc.add(const ReceivingBarcodeSubmitted(barcode: 'B', quantityText: '20'));
    await bloc.stream.firstWhere(
      (state) => state.items.any(
        (item) => item.barcode == 'B' && item.inspectedQuantity == 20,
      ),
    );

    // Undo restores the pre-scan quantity 0 but keeps the row.
    bloc.add(const ReceivingLastScanUndoRequested());
    final afterUndo = await bloc.stream.firstWhere(
      (state) => state.items.any(
        (item) => item.barcode == 'B' && item.inspectedQuantity == 0,
      ),
    );

    bloc.add(const ReceivingLastScanUndoRequested());
    final afterSecondUndo = await bloc.stream.firstWhere(
      (state) => state.message == ReceivingMessage.barcodeRequired,
    );

    expect(
      afterUndo.items
          .singleWhere((item) => item.barcode == 'A')
          .inspectedQuantity,
      5,
    );
    expect(
      afterSecondUndo.items
          .singleWhere((item) => item.barcode == 'B')
          .inspectedQuantity,
      0,
    );
    expect(repository.undoCalls, 1);
    expect(repository.deleteCalls, 0);
  });

  test('OCR scan preserves letters while barcode scan strips to digits', () async {
    final repository = _FakeReceivingRepository();
    final bloc = ReceivingBloc(
      recordScan: RecordReceivingScanUseCase(repository),
      completeWork: CompleteReceivingWorkUseCase(repository),
      loadCompletedWorkItems: LoadReceivingCompletedWorkItemsUseCase(
        repository,
      ),
      resetItem: ResetReceivingInspectionItemUseCase(repository),
      deleteItem: DeleteReceivingInspectionItemUseCase(repository),
      undoScan: UndoReceivingScanUseCase(repository),
      discardTemporaryWork: () async {},
      readCompletedWorks: repository.readCompletedWorks,
      feedbackService: _SilentScanFeedbackService(),
    );
    addTearDown(bloc.close);

    bloc.add(const ReceivingSlipSubmitted('SLIP-1'));
    await bloc.stream.firstWhere((state) => state.slipNumber == 'SLIP-1');

    // OCR captures an NW7-shaped value; it must be inserted verbatim.
    bloc.add(
      const ReceivingBarcodeSubmitted(
        barcode: 'A12-345B',
        quantityText: '1',
        isOcr: true,
      ),
    );
    await bloc.stream.firstWhere(
      (state) => state.items.any((item) => item.barcode == 'A12-345B'),
    );

    // The same value scanned as a barcode keeps the existing digit normalization.
    bloc.add(
      const ReceivingBarcodeSubmitted(barcode: 'A12-345B', quantityText: '1'),
    );
    await bloc.stream.firstWhere(
      (state) => state.items.any((item) => item.barcode == '12345'),
    );

    expect(
      bloc.state.items.map((item) => item.barcode),
      containsAll(<String>['A12-345B', '12345']),
    );
  });

  test('undo works once per action and re-arms after a new scan', () async {
    final repository = _FakeReceivingRepository();
    final bloc = ReceivingBloc(
      recordScan: RecordReceivingScanUseCase(repository),
      completeWork: CompleteReceivingWorkUseCase(repository),
      loadCompletedWorkItems: LoadReceivingCompletedWorkItemsUseCase(
        repository,
      ),
      resetItem: ResetReceivingInspectionItemUseCase(repository),
      deleteItem: DeleteReceivingInspectionItemUseCase(repository),
      undoScan: UndoReceivingScanUseCase(repository),
      discardTemporaryWork: () async {},
      readCompletedWorks: repository.readCompletedWorks,
      feedbackService: _SilentScanFeedbackService(),
    );
    addTearDown(bloc.close);

    bloc.add(const ReceivingSlipSubmitted('SLIP-1'));
    await bloc.stream.firstWhere((state) => state.slipNumber == 'SLIP-1');

    // Product A already holds 5 units; two scans raise it to 6, then 8.
    bloc.add(const ReceivingBarcodeSubmitted(barcode: 'A', quantityText: '1'));
    await bloc.stream.firstWhere(
      (state) => state.items.any(
        (item) => item.barcode == 'A' && item.inspectedQuantity == 6,
      ),
    );
    bloc.add(const ReceivingBarcodeSubmitted(barcode: 'A', quantityText: '2'));
    await bloc.stream.firstWhere(
      (state) => state.items.any(
        (item) => item.barcode == 'A' && item.inspectedQuantity == 8,
      ),
    );

    // First press restores the quantity before the last scan (6, not 7).
    final afterFirstUndo = await _undoAndWait(
      bloc,
      (state) =>
          !state.isLoading &&
          state.items.any(
            (item) => item.barcode == 'A' && item.inspectedQuantity == 6,
          ),
    );
    expect(afterFirstUndo.selectedItemId, 'A');
    expect(repository.undoCalls, 1);

    // The entry is consumed: a second press undoes nothing further and asks
    // for a barcode instead.
    final afterSecondUndo = await _undoAndWait(
      bloc,
      (state) => state.message == ReceivingMessage.barcodeRequired,
    );
    expect(
      afterSecondUndo.items
          .singleWhere((item) => item.barcode == 'A')
          .inspectedQuantity,
      6,
    );
    expect(repository.undoCalls, 1);

    // A new scan re-arms the undo for that new action only.
    bloc.add(const ReceivingBarcodeSubmitted(barcode: 'A', quantityText: '1'));
    await bloc.stream.firstWhere(
      (state) => state.items.any(
        (item) => item.barcode == 'A' && item.inspectedQuantity == 7,
      ),
    );
    await _undoAndWait(
      bloc,
      (state) =>
          !state.isLoading &&
          state.items.any(
            (item) => item.barcode == 'A' && item.inspectedQuantity == 6,
          ),
    );
    expect(repository.undoCalls, 2);
    expect(repository.deleteCalls, 0);
  });

  test(
    'compares each accepted product with the last successful scan',
    () async {
      final repository = _FakeReceivingRepository();
      final feedbackService = _RecordingScanFeedbackService();
      final bloc = ReceivingBloc(
        recordScan: RecordReceivingScanUseCase(repository),
        completeWork: CompleteReceivingWorkUseCase(repository),
        loadCompletedWorkItems: LoadReceivingCompletedWorkItemsUseCase(
          repository,
        ),
        resetItem: ResetReceivingInspectionItemUseCase(repository),
        deleteItem: DeleteReceivingInspectionItemUseCase(repository),
        undoScan: UndoReceivingScanUseCase(repository),
        discardTemporaryWork: () async {},
        readCompletedWorks: repository.readCompletedWorks,
        feedbackService: feedbackService,
      );
      addTearDown(bloc.close);

      bloc.add(const ReceivingSlipSubmitted('SLIP-1'));
      await bloc.stream.firstWhere((state) => state.slipNumber == 'SLIP-1');

      final messages = [
        (await _submitAndWait(bloc, '123', 1)).message,
        (await _submitAndWait(bloc, '123', 2)).message,
        (await _submitAndWait(bloc, '123', 3)).message,
        (await _submitAndWait(bloc, '123', 4)).message,
        (await _submitAndWait(bloc, '124', 5)).message,
        (await _submitAndWait(bloc, '124', 6)).message,
        (await _submitAndWait(bloc, '124', 7)).message,
        (await _submitAndWait(bloc, '123', 8)).message,
      ];

      expect(feedbackService.feedback, [
        _RecordedFeedback.differentProduct,
        _RecordedFeedback.success,
        _RecordedFeedback.success,
        _RecordedFeedback.success,
        _RecordedFeedback.differentProduct,
        _RecordedFeedback.success,
        _RecordedFeedback.success,
        _RecordedFeedback.differentProduct,
      ]);
      expect(messages, [
        ReceivingMessage.inspectionSaved,
        ReceivingMessage.inspectionSaved,
        ReceivingMessage.inspectionSaved,
        ReceivingMessage.inspectionSaved,
        ReceivingMessage.productChanged,
        ReceivingMessage.inspectionSaved,
        ReceivingMessage.inspectionSaved,
        ReceivingMessage.productChanged,
      ]);
    },
  );

  test('starts product comparison over when the slip changes', () async {
    final repository = _FakeReceivingRepository();
    final feedbackService = _RecordingScanFeedbackService();
    final bloc = ReceivingBloc(
      recordScan: RecordReceivingScanUseCase(repository),
      completeWork: CompleteReceivingWorkUseCase(repository),
      loadCompletedWorkItems: LoadReceivingCompletedWorkItemsUseCase(
        repository,
      ),
      resetItem: ResetReceivingInspectionItemUseCase(repository),
      deleteItem: DeleteReceivingInspectionItemUseCase(repository),
      undoScan: UndoReceivingScanUseCase(repository),
      discardTemporaryWork: () async {},
      readCompletedWorks: repository.readCompletedWorks,
      feedbackService: feedbackService,
    );
    addTearDown(bloc.close);

    bloc.add(const ReceivingSlipSubmitted('SLIP-1'));
    await bloc.stream.firstWhere((state) => state.slipNumber == 'SLIP-1');
    await _submitAndWait(bloc, 'B', 1);

    bloc.add(const ReceivingSlipSubmitted('SLIP-2'));
    await bloc.stream.firstWhere((state) => state.slipNumber == 'SLIP-2');
    await _submitAndWait(bloc, 'C', 2);

    expect(feedbackService.feedback, [
      _RecordedFeedback.differentProduct,
      _RecordedFeedback.differentProduct,
    ]);
  });
}

Future<ReceivingState> _undoAndWait(
  ReceivingBloc bloc,
  bool Function(ReceivingState) matcher,
) {
  bloc.add(const ReceivingLastScanUndoRequested());
  return bloc.stream.firstWhere(matcher);
}

Future<ReceivingState> _submitAndWait(
  ReceivingBloc bloc,
  String barcode,
  int messageToken,
) async {
  bloc.add(ReceivingBarcodeSubmitted(barcode: barcode, quantityText: '1'));
  final state = await bloc.stream.firstWhere(
    (state) => state.messageToken == messageToken,
  );
  await Future<void>.delayed(Duration.zero);
  return state;
}

final class _SilentScanFeedbackService extends ScanFeedbackService {
  @override
  Future<void> playScanSuccess({Object? eventId}) async {}

  @override
  Future<void> playProductScanSuccess({Object? eventId}) async {}

  @override
  Future<void> playDifferentProduct({Object? eventId}) async {}

  @override
  Future<void> playScanError({Object? eventId}) async {}
}

final class _RecordingScanFeedbackService extends _SilentScanFeedbackService {
  final List<_RecordedFeedback> feedback = [];

  @override
  Future<void> playProductScanSuccess({Object? eventId}) async {
    feedback.add(_RecordedFeedback.success);
  }

  @override
  Future<void> playDifferentProduct({Object? eventId}) async {
    feedback.add(_RecordedFeedback.differentProduct);
  }
}

enum _RecordedFeedback { success, differentProduct }

final class _FakeReceivingRepository implements ReceivingRepository {
  final List<ReceivingInspectionItem> _items = [
    const ReceivingInspectionItem(
      id: 'A',
      slipNumber: 'SLIP-1',
      barcode: 'A',
      productName: '',
      expectedQuantity: 5,
      inspectedQuantity: 5,
      status: ReceivingInspectionStatus.completed,
    ),
  ];

  int undoCalls = 0;
  int deleteCalls = 0;

  @override
  Future<void> discardTemporaryWork() async => _items.clear();

  @override
  Future<List<ReceivingInspectionItem>> recordInspection({
    required String slipNumber,
    required String barcode,
    required int quantity,
  }) async {
    final index = _items.indexWhere(
      (item) => item.slipNumber == slipNumber && item.barcode == barcode,
    );
    if (index == -1) {
      _items.insert(
        0,
        ReceivingInspectionItem(
          id: barcode,
          slipNumber: slipNumber,
          barcode: barcode,
          productName: '',
          expectedQuantity: quantity,
          inspectedQuantity: quantity,
          status: ReceivingInspectionStatus.completed,
        ),
      );
    } else {
      final item = _items[index];
      _items[index] = item.copyWith(
        inspectedQuantity: item.inspectedQuantity + quantity,
      );
    }
    return List.unmodifiable(_items);
  }

  @override
  Future<List<ReceivingInspectionItem>> undoLastScan({
    required String slipNumber,
    required String barcode,
    required int previousQuantity,
  }) async {
    undoCalls++;
    final index = _items.indexWhere((item) => item.barcode == barcode);
    _items[index] = _items[index].copyWith(
      inspectedQuantity: previousQuantity,
      status: ReceivingInspectionStatus.pending,
    );
    return List.unmodifiable(_items);
  }

  @override
  Future<List<ReceivingInspectionItem>> completeWork(String slipNumber) async =>
      List.unmodifiable(_items);

  @override
  Future<List<ReceivingInspectionItem>> deleteInspectionItem({
    required String slipNumber,
    required String itemId,
  }) async {
    deleteCalls++;
    _items.removeWhere((item) => item.id == itemId);
    return List.unmodifiable(_items);
  }

  @override
  Future<void> deleteCompletedWork(String slipNumber) async {}

  @override
  Future<List<ReceivingInspectionItem>> readCompletedWorkItems(
    String slipNumber,
  ) async => List.unmodifiable(_items);

  @override
  Future<List<ReceivingCompletedWorkDetail>> readCompletedWorkDetails(
    String slipNumber,
  ) async => const [];

  @override
  Future<List<ReceivingCompletedWork>> readCompletedWorks() async => const [];

  @override
  Future<List<ReceivingInspectionItem>> resetInspectionItem({
    required String slipNumber,
    required String itemId,
  }) async => List.unmodifiable(_items);
}
