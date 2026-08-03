import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/data/local/receiving_repository.dart';

final class UndoReceivingScanUseCase {
  const UndoReceivingScanUseCase(this._repository);

  final ReceivingRepository _repository;

  Future<List<ReceivingInspectionItem>> call({
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
}
