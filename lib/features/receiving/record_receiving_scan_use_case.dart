import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/data/local/receiving_repository.dart';

final class RecordReceivingScanParams {
  const RecordReceivingScanParams({
    required this.slipNumber,
    required this.barcode,
    required this.quantity,
  });

  final String slipNumber;
  final String barcode;
  final int quantity;
}

final class RecordReceivingScanUseCase {
  const RecordReceivingScanUseCase(this._repository);

  final ReceivingRepository _repository;

  Future<List<ReceivingInspectionItem>> call(RecordReceivingScanParams params) {
    return _repository.recordInspection(
      slipNumber: params.slipNumber,
      barcode: params.barcode,
      quantity: params.quantity,
    );
  }
}
