import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/services/scan_feedback_service.dart';
import 'package:waretrack_mini/data/local/receiving_repository.dart';
import 'package:waretrack_mini/data/models/receiving_completed_work.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/features/receiving/delete_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/record_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/receiving/reset_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/undo_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/stocking/bloc/stocking_bloc.dart';
import 'package:waretrack_mini/features/stocking/bloc/stocking_event.dart';
import 'package:waretrack_mini/features/stocking/bloc/stocking_state.dart';

void main() {
  group('StockingBloc scan mode routing', () {
    late _MemoryReceivingRepository repository;
    late _RecordingScanFeedbackService feedbackService;
    late StockingBloc bloc;
    late List<ReceivingInspectionItem>? completedSession;

    setUp(() {
      repository = _MemoryReceivingRepository();
      feedbackService = _RecordingScanFeedbackService();
      completedSession = null;
      bloc = StockingBloc(
        recordScan: RecordReceivingScanUseCase(repository),
        completeWork: (items) async {
          completedSession = items;
          return items;
        },
        resetItem: ResetReceivingInspectionItemUseCase(repository),
        deleteItem: DeleteReceivingInspectionItemUseCase(repository),
        undoScan: UndoReceivingScanUseCase(repository),
        discardTemporaryWork: repository.discardTemporaryWork,
        feedbackService: feedbackService,
      );
    });

    tearDown(() => bloc.close());

    test('shelf mode updates only the shelf header', () async {
      bloc.add(const StockingScanValueSubmitted('123-123'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == '123-123');
      await pumpEventQueue();

      expect(bloc.state.visibleItems, isEmpty);
      expect(bloc.state.selectedMode, StockingScanMode.product);
      expect(feedbackService.productScanSuccessCount, 1);
      expect(repository.recordCallCount, 0);
    });

    test('manual input in shelf mode updates only the shelf header', () async {
      bloc.add(
        const StockingBarcodeSubmitted(barcode: 'hsisnsbvd', quantityText: '1'),
      );
      await bloc.stream.firstWhere(
        (state) =>
            state.shelfNumber == 'hsisnsbvd' &&
            state.selectedMode == StockingScanMode.product,
      );
      await pumpEventQueue();

      expect(bloc.state.visibleItems, isEmpty);
      expect(bloc.state.message, isNull);
      expect(feedbackService.productScanSuccessCount, 1);
      expect(repository.recordCallCount, 0);
    });

    test('manual product input requires a shelf in product mode', () async {
      bloc.add(const StockingScanModeChanged(StockingScanMode.product));
      await bloc.stream.firstWhere(
        (state) => state.selectedMode == StockingScanMode.product,
      );
      bloc.add(
        const StockingBarcodeSubmitted(
          barcode: '1234563456',
          quantityText: '1',
        ),
      );
      await bloc.stream.firstWhere(
        (state) => state.message == StockingMessage.shelfNumberRequired,
      );

      expect(bloc.state.items, isEmpty);
      expect(repository.recordCallCount, 0);
    });

    test(
      'shelf mode clears missing shelf validation and accepts shelf input',
      () async {
        bloc.add(const StockingScanModeChanged(StockingScanMode.product));
        await bloc.stream.firstWhere(
          (state) => state.selectedMode == StockingScanMode.product,
        );
        bloc.add(
          const StockingBarcodeSubmitted(
            barcode: 'product-before-shelf',
            quantityText: '1',
          ),
        );
        await bloc.stream.firstWhere(
          (state) => state.message == StockingMessage.shelfNumberRequired,
        );

        bloc.add(const StockingScanModeChanged(StockingScanMode.shelfNumber));
        await bloc.stream.firstWhere(
          (state) =>
              state.selectedMode == StockingScanMode.shelfNumber &&
              state.message == null,
        );
        bloc.add(
          const StockingBarcodeSubmitted(
            barcode: 'shelf-001',
            quantityText: '1',
          ),
        );
        await bloc.stream.firstWhere(
          (state) =>
              state.shelfNumber == 'shelf-001' &&
              state.selectedMode == StockingScanMode.product,
        );

        expect(bloc.state.visibleItems, isEmpty);
        expect(bloc.state.message, isNull);
        expect(repository.recordCallCount, 0);
      },
    );

    test(
      'shelf mode accepts text, digits, Japanese, hyphens, and mixed case',
      () async {
        const shelfNumbers = [
          'abc',
          '123',
          '123-12',
          'sdsd32',
          '棚番号-あア123',
          'AbC-xyZ9',
        ];

        for (final shelfNumber in shelfNumbers) {
          bloc.add(const StockingScanModeChanged(StockingScanMode.shelfNumber));
          await bloc.stream.firstWhere(
            (state) => state.selectedMode == StockingScanMode.shelfNumber,
          );
          bloc.add(StockingScanValueSubmitted(shelfNumber));
          await bloc.stream.firstWhere(
            (state) =>
                state.shelfNumber == shelfNumber &&
                state.selectedMode == StockingScanMode.product,
          );

          expect(bloc.state.visibleItems, isEmpty);
        }
      },
    );

    test(
      'product mode cannot change the shelf until shelf mode is selected',
      () async {
        bloc.add(const StockingScanValueSubmitted('abc'));
        await bloc.stream.firstWhere(
          (state) =>
              state.shelfNumber == 'abc' &&
              state.selectedMode == StockingScanMode.product,
        );

        bloc.add(const StockingScanValueSubmitted('123-12'));
        await bloc.stream.firstWhere(
          (state) =>
              state.items.length == 1 && state.items.single.barcode == '123-12',
        );

        expect(bloc.state.items, hasLength(1));
        expect(bloc.state.items.single.slipNumber, 'abc');
        expect(bloc.state.items.single.barcode, '123-12');

        bloc.add(const StockingScanModeChanged(StockingScanMode.shelfNumber));
        await bloc.stream.firstWhere(
          (state) => state.selectedMode == StockingScanMode.shelfNumber,
        );
        bloc.add(const StockingScanValueSubmitted('new-shelf'));
        await bloc.stream.firstWhere(
          (state) => state.shelfNumber == 'new-shelf',
        );

        expect(
          bloc.state.items
              .map((item) => (item.slipNumber, item.barcode))
              .toList(),
          [('abc', '123-12')],
        );
      },
    );

    test(
      'a new shelf scan updates the header without adding a pending row',
      () async {
        bloc.add(const StockingScanValueSubmitted('1234563456'));
        await bloc.stream.firstWhere(
          (state) => state.shelfNumber == '1234563456',
        );
        bloc.add(const StockingScanModeChanged(StockingScanMode.product));
        await bloc.stream.firstWhere(
          (state) => state.selectedMode == StockingScanMode.product,
        );
        bloc.add(const StockingScanValueSubmitted('1234563456'));
        await bloc.stream.firstWhere(
          (state) =>
              state.items.length == 1 &&
              state.items.single.barcode == '1234563456',
        );

        bloc.add(const StockingScanModeChanged(StockingScanMode.shelfNumber));
        await bloc.stream.firstWhere(
          (state) => state.selectedMode == StockingScanMode.shelfNumber,
        );
        bloc.add(const StockingScanValueSubmitted('abc-123'));
        await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc-123');

        expect(
          bloc.state.visibleItems
              .map(
                (item) => (
                  shelfNumber: item.slipNumber,
                  barcode: item.barcode,
                  quantity: item.inspectedQuantity,
                ),
              )
              .toList(),
          [(shelfNumber: '1234563456', barcode: '1234563456', quantity: 1)],
        );
      },
    );

    test('product scan requires an incomplete shelf row', () async {
      bloc.add(const StockingScanModeChanged(StockingScanMode.product));
      await bloc.stream.firstWhere(
        (state) => state.selectedMode == StockingScanMode.product,
      );
      bloc.add(const StockingScanValueSubmitted('1234563456'));
      await bloc.stream.firstWhere(
        (state) => state.message == StockingMessage.shelfNumberRequired,
      );

      expect(bloc.state.items, isEmpty);
      expect(repository.recordCallCount, 0);
    });

    test('OCR shelf scan updates only the shelf header', () async {
      const ocrValue = 'abc 123-12 sdsd32';

      bloc.add(const StockingScanValueSubmitted(ocrValue));
      await bloc.stream.firstWhere((state) => state.shelfNumber == ocrValue);

      expect(bloc.state.visibleItems, isEmpty);
    });

    test(
      'OCR product scan inserts the complete value in the pending row',
      () async {
        const shelfValue = 'abc 123-12 sdsd32';
        const ocrProductValue = '1234567890';

        bloc.add(const StockingScanValueSubmitted(shelfValue));
        await bloc.stream.firstWhere(
          (state) => state.shelfNumber == shelfValue,
        );
        bloc.add(const StockingScanModeChanged(StockingScanMode.product));
        await bloc.stream.firstWhere(
          (state) => state.selectedMode == StockingScanMode.product,
        );
        bloc.add(const StockingScanValueSubmitted(ocrProductValue));
        await bloc.stream.firstWhere(
          (state) => state.items.any((item) => item.barcode == ocrProductValue),
        );

        final row = bloc.state.visibleItems.single;
        expect(row.slipNumber, shelfValue);
        expect(row.barcode, ocrProductValue);
        expect(row.inspectedQuantity, 1);
      },
    );

    test(
      'OCR product scan preserves letters instead of stripping to digits',
      () async {
        // An NW7-shaped value: barcode/manual input would strip it to digits,
        // but an OCR capture must keep the exact scanned characters.
        const ocrProductValue = 'A12-345B';

        bloc.add(const StockingScanValueSubmitted('shelf-1'));
        await bloc.stream.firstWhere((state) => state.shelfNumber == 'shelf-1');
        bloc.add(const StockingScanModeChanged(StockingScanMode.product));
        await bloc.stream.firstWhere(
          (state) => state.selectedMode == StockingScanMode.product,
        );
        bloc.add(
          const StockingScanValueSubmitted(ocrProductValue, isOcr: true),
        );
        await bloc.stream.firstWhere(
          (state) => state.items.any((item) => item.barcode == ocrProductValue),
        );

        expect(bloc.state.visibleItems.single.barcode, ocrProductValue);
      },
    );

    test(
      'non-OCR product scan still normalizes NW7 values to digits',
      () async {
        bloc.add(const StockingScanValueSubmitted('shelf-1'));
        await bloc.stream.firstWhere((state) => state.shelfNumber == 'shelf-1');
        bloc.add(const StockingScanModeChanged(StockingScanMode.product));
        await bloc.stream.firstWhere(
          (state) => state.selectedMode == StockingScanMode.product,
        );
        bloc.add(const StockingScanValueSubmitted('A12-345B'));
        await bloc.stream.firstWhere(
          (state) => state.items.any((item) => item.barcode == '12345'),
        );

        expect(bloc.state.visibleItems.single.barcode, '12345');
      },
    );

    test(
      'product mode inserts the scan into barcode and keeps quantity logic',
      () async {
        bloc.add(const StockingScanValueSubmitted('123-123'));
        await bloc.stream.firstWhere((state) => state.shelfNumber == '123-123');

        bloc.add(const StockingScanModeChanged(StockingScanMode.product));
        await bloc.stream.firstWhere(
          (state) => state.selectedMode == StockingScanMode.product,
        );
        bloc.add(const StockingScanValueSubmitted('1234563456'));
        await bloc.stream.firstWhere(
          (state) =>
              state.items.length == 1 &&
              state.items.single.barcode == '1234563456',
        );

        final row = bloc.state.visibleItems.single;
        expect(row.slipNumber, '123-123');
        expect(row.barcode, '1234563456');
        expect(row.inspectedQuantity, 1);
        expect(repository.recordCallCount, 1);
      },
    );

    test(
      'different product scans insert rows at the top of the list',
      () async {
        bloc.add(const StockingScanValueSubmitted('abc'));
        await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');
        bloc.add(const StockingScanModeChanged(StockingScanMode.product));
        await bloc.stream.firstWhere(
          (state) => state.selectedMode == StockingScanMode.product,
        );

        final expectedBarcodes = <String>[];
        for (final barcode in const ['123', '456', '789']) {
          expectedBarcodes.insert(0, barcode);
          bloc.add(StockingScanValueSubmitted(barcode));
          await bloc.stream.firstWhere(
            (state) =>
                !state.isLoading &&
                state.items.length == expectedBarcodes.length &&
                state.items.first.barcode == barcode,
          );

          expect(
            bloc.state.items.map((item) => item.slipNumber),
            everyElement('abc'),
          );
          expect(
            bloc.state.items.map((item) => item.barcode).toList(),
            expectedBarcodes,
          );
          expect(
            bloc.state.items.map((item) => item.inspectedQuantity),
            everyElement(1),
          );
        }

        expect(repository.items, hasLength(3));
      },
    );

    test('same product barcode increases the current row quantity', () async {
      bloc.add(const StockingScanValueSubmitted('abc'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');
      bloc.add(const StockingScanModeChanged(StockingScanMode.product));
      await bloc.stream.firstWhere(
        (state) => state.selectedMode == StockingScanMode.product,
      );

      bloc.add(const StockingScanValueSubmitted('123'));
      await bloc.stream.firstWhere(
        (state) =>
            state.items.length == 1 &&
            state.items.single.inspectedQuantity == 1,
      );
      bloc.add(const StockingScanValueSubmitted('123'));
      await bloc.stream.firstWhere(
        (state) =>
            state.items.length == 1 &&
            state.items.single.inspectedQuantity == 2,
      );

      expect(bloc.state.items, hasLength(1));
      expect(bloc.state.items.single.barcode, '123');
      expect(repository.items, hasLength(1));
      expect(repository.items.single.inspectedQuantity, 2);
    });

    test('different product barcode inserts on top with the set '
        'quantity', () async {
      bloc.add(const StockingScanValueSubmitted('abc'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');
      bloc.add(const StockingScanModeChanged(StockingScanMode.product));
      await bloc.stream.firstWhere(
        (state) => state.selectedMode == StockingScanMode.product,
      );
      bloc.add(const StockingScanValueSubmitted('123'));
      await bloc.stream.firstWhere(
        (state) =>
            state.items.length == 1 && state.items.single.barcode == '123',
      );

      bloc.add(const StockingQuantityChanged('4'));
      await bloc.stream.firstWhere((state) => state.quantity == '4');
      bloc.add(const StockingScanValueSubmitted('456'));
      await bloc.stream.firstWhere(
        (state) =>
            state.items.length == 2 &&
            state.items.first.barcode == '456' &&
            state.items.first.inspectedQuantity == 4,
      );

      expect(bloc.state.items, hasLength(2));
      expect(bloc.state.items.last.barcode, '123');
      expect(bloc.state.items.last.inspectedQuantity, 1);
      expect(repository.items, hasLength(2));
      final persistedProduct = repository.items.firstWhere(
        (item) => item.barcode == '456',
      );
      expect(persistedProduct.inspectedQuantity, 4);
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

        // After a successful add the inputs reset so the next product starts
        // from the defaults...
        expect(bloc.state.barcode, '');
        expect(bloc.state.quantity, '1');
        // ...but the product just registered keeps the entered quantity.
        expect(repository.items.single.inspectedQuantity, 10);
      },
    );

    test('empty product row uses the current set quantity', () async {
      bloc.add(const StockingScanValueSubmitted('abc'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');
      bloc.add(const StockingScanModeChanged(StockingScanMode.product));
      await bloc.stream.firstWhere(
        (state) => state.selectedMode == StockingScanMode.product,
      );
      bloc.add(const StockingQuantityChanged('3'));
      await bloc.stream.firstWhere((state) => state.quantity == '3');

      bloc.add(const StockingScanValueSubmitted('123'));
      await bloc.stream.firstWhere(
        (state) =>
            state.items.length == 1 &&
            state.items.single.inspectedQuantity == 3,
      );

      expect(bloc.state.items.single.barcode, '123');
      expect(repository.items.single.inspectedQuantity, 3);
    });

    test(
      'different product shows the shared notice while duplicate does not',
      () async {
        bloc.add(const StockingScanValueSubmitted('abc'));
        await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');
        bloc.add(const StockingScanModeChanged(StockingScanMode.product));
        await bloc.stream.firstWhere(
          (state) => state.selectedMode == StockingScanMode.product,
        );

        bloc.add(const StockingScanValueSubmitted('123456'));
        await bloc.stream.firstWhere(
          (state) => state.items.any(
            (item) => item.barcode == '123456' && item.inspectedQuantity == 1,
          ),
        );
        expect(bloc.state.showProductChangedNotice, isFalse);

        bloc.add(const StockingScanValueSubmitted('123456'));
        await bloc.stream.firstWhere(
          (state) => state.items.any(
            (item) => item.barcode == '123456' && item.inspectedQuantity == 2,
          ),
        );
        expect(bloc.state.showProductChangedNotice, isFalse);

        bloc.add(const StockingScanValueSubmitted('999999'));
        await bloc.stream.firstWhere((state) => state.showProductChangedNotice);
        expect(bloc.state.message, StockingMessage.productChanged);

        bloc.add(const StockingProductChangedNoticeCleared());
        await bloc.stream.firstWhere(
          (state) => !state.showProductChangedNotice,
        );
      },
    );

    test('reset after undo does not restore the undone scan quantity', () async {
      bloc.add(const StockingScanValueSubmitted('abc'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');
      bloc.add(const StockingScanValueSubmitted('123'));
      await bloc.stream.firstWhere(
        (state) => state.items.any((item) => item.barcode == '123'),
      );
      bloc.add(const StockingScanValueSubmitted('456'));
      await bloc.stream.firstWhere(
        (state) => state.items.any((item) => item.barcode == '456'),
      );

      // "undo 1 scan" drops the last scanned row to quantity 0 in the session
      // AND in the persisted scan list; the row itself stays.
      bloc.add(const StockingUndoRequested());
      await bloc.stream.firstWhere(
        (state) =>
            !state.isLoading &&
            state.items.any(
              (item) => item.barcode == '456' && item.inspectedQuantity == 0,
            ),
      );
      expect(
        repository.items
            .firstWhere((item) => item.barcode == '456')
            .inspectedQuantity,
        0,
      );

      // ...so resetting another row must not bring the quantity back.
      final resetTarget = bloc.state.items.firstWhere(
        (item) => item.barcode == '123',
      );
      bloc.add(StockingItemResetConfirmed(resetTarget.id));
      await bloc.stream.firstWhere(
        (state) =>
            state.items.length == 2 &&
            state.items.every((item) => item.inspectedQuantity == 0),
      );

      expect(
        repository.items
            .firstWhere((item) => item.barcode == '456')
            .inspectedQuantity,
        0,
      );
    });

    test('undo restores the previous quantity of the last scan only '
        'once', () async {
      bloc.add(const StockingScanValueSubmitted('abc'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');
      bloc.add(const StockingScanValueSubmitted('123'));
      await bloc.stream.firstWhere(
        (state) => state.items.any(
          (item) => item.barcode == '123' && item.inspectedQuantity == 1,
        ),
      );
      bloc.add(const StockingScanValueSubmitted('123'));
      await bloc.stream.firstWhere(
        (state) => state.items.any(
          (item) => item.barcode == '123' && item.inspectedQuantity == 2,
        ),
      );

      // First press restores the quantity before the latest scan.
      bloc.add(const StockingUndoRequested());
      await bloc.stream.firstWhere(
        (state) =>
            !state.isLoading &&
            state.items.any(
              (item) => item.barcode == '123' && item.inspectedQuantity == 1,
            ),
      );
      expect(repository.items.single.inspectedQuantity, 1);

      // The entry is consumed: a second press undoes nothing further and
      // asks for a barcode instead.
      bloc.add(const StockingUndoRequested());
      await bloc.stream.firstWhere(
        (state) => state.message == StockingMessage.barcodeRequired,
      );
      expect(bloc.state.items.single.inspectedQuantity, 1);
      expect(repository.items.single.inspectedQuantity, 1);

      // A new scan re-arms the undo for that new action only.
      bloc.add(const StockingScanValueSubmitted('123'));
      await bloc.stream.firstWhere(
        (state) => state.items.any(
          (item) => item.barcode == '123' && item.inspectedQuantity == 2,
        ),
      );
      bloc.add(const StockingUndoRequested());
      await bloc.stream.firstWhere(
        (state) =>
            !state.isLoading &&
            state.items.any(
              (item) => item.barcode == '123' && item.inspectedQuantity == 1,
            ),
      );
      expect(repository.items.single.inspectedQuantity, 1);
    });

    test('undo restores a manual insert back to the pre-insert '
        'quantity', () async {
      bloc.add(const StockingScanValueSubmitted('abc'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');

      // The product was not in the list; one insert stores quantity 20.
      bloc.add(
        const StockingBarcodeSubmitted(barcode: '123', quantityText: '20'),
      );
      await bloc.stream.firstWhere(
        (state) => state.items.any(
          (item) => item.barcode == '123' && item.inspectedQuantity == 20,
        ),
      );

      // A second insert of 3 raises the quantity to 23.
      bloc.add(
        const StockingBarcodeSubmitted(barcode: '123', quantityText: '3'),
      );
      await bloc.stream.firstWhere(
        (state) => state.items.any(
          (item) => item.barcode == '123' && item.inspectedQuantity == 23,
        ),
      );

      // Undo restores 20 (not 22); only the last insert can be undone.
      bloc.add(const StockingUndoRequested());
      await bloc.stream.firstWhere(
        (state) =>
            !state.isLoading &&
            state.items.any(
              (item) => item.barcode == '123' && item.inspectedQuantity == 20,
            ),
      );
      expect(repository.items.single.inspectedQuantity, 20);

      bloc.add(const StockingUndoRequested());
      await bloc.stream.firstWhere(
        (state) => state.message == StockingMessage.barcodeRequired,
      );
      expect(bloc.state.items.single.inspectedQuantity, 20);
      expect(repository.items.single.inspectedQuantity, 20);
    });

    test('undo targets the last scan even after a shelf change', () async {
      bloc.add(const StockingScanValueSubmitted('abc'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');
      bloc.add(const StockingScanValueSubmitted('123'));
      await bloc.stream.firstWhere(
        (state) => state.items.any(
          (item) => item.barcode == '123' && item.inspectedQuantity == 1,
        ),
      );

      bloc.add(const StockingScanModeChanged(StockingScanMode.shelfNumber));
      await bloc.stream.firstWhere(
        (state) => state.selectedMode == StockingScanMode.shelfNumber,
      );
      bloc.add(const StockingScanValueSubmitted('xyz'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == 'xyz');

      // The pending undo still targets the product scanned on the previous
      // shelf.
      bloc.add(const StockingUndoRequested());
      await bloc.stream.firstWhere(
        (state) =>
            !state.isLoading &&
            state.items.any(
              (item) =>
                  item.slipNumber == 'abc' &&
                  item.barcode == '123' &&
                  item.inspectedQuantity == 0,
            ),
      );
      expect(repository.items.single.inspectedQuantity, 0);

      // The entry is consumed: a second press undoes nothing further.
      bloc.add(const StockingUndoRequested());
      await bloc.stream.firstWhere(
        (state) => state.message == StockingMessage.barcodeRequired,
      );
      expect(repository.items.single.inspectedQuantity, 0);
    });

    test('work completion rejects a shelf header without products', () async {
      bloc.add(const StockingScanValueSubmitted('abc'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');

      bloc.add(const StockingWorkCompletionConfirmed());
      await bloc.stream.firstWhere(
        (state) => state.message == StockingMessage.noScanData,
      );

      expect(completedSession, isNull);
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.shouldPop, isFalse);
    });

    test('work completion saves reset rows with zero quantity', () async {
      bloc.add(const StockingScanValueSubmitted('abc'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');
      bloc.add(const StockingScanValueSubmitted('123'));
      await bloc.stream.firstWhere(
        (state) =>
            state.items.length == 1 &&
            state.items.single.inspectedQuantity == 1,
      );

      bloc.add(StockingItemResetConfirmed(bloc.state.items.single.id));
      await bloc.stream.firstWhere(
        (state) =>
            state.items.length == 1 &&
            state.items.single.inspectedQuantity == 0,
      );

      bloc.add(const StockingWorkCompletionConfirmed());
      await bloc.stream.firstWhere((state) => state.shouldPop);

      expect(completedSession, hasLength(1));
      expect(completedSession!.single.slipNumber, 'abc');
      expect(completedSession!.single.barcode, '123');
      expect(completedSession!.single.inspectedQuantity, 0);
      expect(bloc.state.message, StockingMessage.workCompleted);
    });

    test('work completion saves all rows and clears the session', () async {
      bloc.add(const StockingScanValueSubmitted('abc'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == 'abc');
      bloc.add(const StockingScanModeChanged(StockingScanMode.product));
      await bloc.stream.firstWhere(
        (state) => state.selectedMode == StockingScanMode.product,
      );
      bloc.add(const StockingScanValueSubmitted('123'));
      await bloc.stream.firstWhere(
        (state) =>
            state.items.length == 1 && state.items.single.barcode == '123',
      );

      bloc.add(const StockingWorkCompletionConfirmed());
      await bloc.stream.firstWhere((state) => state.shouldPop);

      expect(completedSession, hasLength(1));
      expect(completedSession!.single.slipNumber, 'abc');
      expect(completedSession!.single.barcode, '123');
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.shelfNumber, isEmpty);
    });

    test('manual shelf input bumps clearInputToken to reset the field', () async {
      bloc.add(
        const StockingBarcodeSubmitted(barcode: 'shelf-1', quantityText: '1'),
      );
      await bloc.stream.firstWhere(
        (state) =>
            state.shelfNumber == 'shelf-1' &&
            state.selectedMode == StockingScanMode.product,
      );

      // The typed shelf value never enters the state, so the token is the only
      // signal the UI has to clear the code field.
      expect(bloc.state.clearInputToken, 1);
      expect(bloc.state.barcode, '');
    });

    test('manual product input bumps clearInputToken and resets inputs', () async {
      bloc.add(
        const StockingBarcodeSubmitted(barcode: 'shelf-1', quantityText: '1'),
      );
      await bloc.stream.firstWhere(
        (state) => state.selectedMode == StockingScanMode.product,
      );
      final tokenAfterShelf = bloc.state.clearInputToken;

      bloc.add(
        const StockingBarcodeSubmitted(barcode: '123456', quantityText: '2'),
      );
      await bloc.stream.firstWhere(
        (state) => state.items.any((item) => item.barcode == '123456'),
      );

      expect(bloc.state.clearInputToken, tokenAfterShelf + 1);
      expect(bloc.state.barcode, '');
      expect(bloc.state.quantity, '1');
    });

    test('scanning never bumps clearInputToken', () async {
      bloc.add(const StockingScanValueSubmitted('shelf-1'));
      await bloc.stream.firstWhere((state) => state.shelfNumber == 'shelf-1');
      bloc.add(const StockingScanValueSubmitted('123456'));
      await bloc.stream.firstWhere(
        (state) => state.items.any((item) => item.barcode == '123456'),
      );
      await pumpEventQueue();

      expect(bloc.state.clearInputToken, 0);
    });

    test('failed manual input leaves clearInputToken untouched', () async {
      bloc.add(const StockingScanModeChanged(StockingScanMode.product));
      await bloc.stream.firstWhere(
        (state) => state.selectedMode == StockingScanMode.product,
      );
      bloc.add(
        const StockingBarcodeSubmitted(barcode: '123456', quantityText: '1'),
      );
      await bloc.stream.firstWhere(
        (state) => state.message == StockingMessage.shelfNumberRequired,
      );

      expect(bloc.state.clearInputToken, 0);
    });
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

final class _RecordingScanFeedbackService extends _SilentScanFeedbackService {
  int productScanSuccessCount = 0;

  @override
  Future<void> playProductScanSuccess({Object? eventId}) async {
    productScanSuccessCount++;
  }
}

final class _MemoryReceivingRepository implements ReceivingRepository {
  final List<ReceivingInspectionItem> _items = [];
  int recordCallCount = 0;

  List<ReceivingInspectionItem> get items => List.unmodifiable(_items);

  @override
  Future<void> discardTemporaryWork() async => _items.clear();

  @override
  Future<List<ReceivingInspectionItem>> recordInspection({
    required String slipNumber,
    required String barcode,
    required int quantity,
  }) async {
    recordCallCount++;
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
  }) async {
    final index = _items.indexWhere(
      (item) => item.slipNumber == slipNumber && item.barcode == barcode,
    );
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        inspectedQuantity: previousQuantity,
      );
    }
    return List.unmodifiable(
      _items.where((item) => item.slipNumber == slipNumber),
    );
  }

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
