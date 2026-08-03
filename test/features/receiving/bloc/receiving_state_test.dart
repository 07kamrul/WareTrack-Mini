import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/features/receiving/bloc/receiving_state.dart';

void main() {
  group('ReceivingState.hasScannedProducts', () {
    test('is false when the product list is empty', () {
      expect(const ReceivingState().hasScannedProducts, isFalse);
    });

    test('is false when all scanned quantities are zero', () {
      const state = ReceivingState(
        items: [
          ReceivingInspectionItem(
            id: 'A',
            slipNumber: 'SLIP-1',
            barcode: 'A',
            productName: '',
            expectedQuantity: 1,
            inspectedQuantity: 0,
            status: ReceivingInspectionStatus.pending,
          ),
        ],
      );

      expect(state.hasScannedProducts, isFalse);
    });

    test('is true when at least one scanned quantity is greater than zero', () {
      const state = ReceivingState(
        items: [
          ReceivingInspectionItem(
            id: 'A',
            slipNumber: 'SLIP-1',
            barcode: 'A',
            productName: '',
            expectedQuantity: 1,
            inspectedQuantity: 0,
            status: ReceivingInspectionStatus.pending,
          ),
          ReceivingInspectionItem(
            id: 'B',
            slipNumber: 'SLIP-1',
            barcode: 'B',
            productName: '',
            expectedQuantity: 1,
            inspectedQuantity: 1,
            status: ReceivingInspectionStatus.completed,
          ),
        ],
      );

      expect(state.hasScannedProducts, isTrue);
    });
  });
}
