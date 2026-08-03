import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/data/local/receiving_repository.dart';

final class ResetReceivingInspectionItemUseCase {
  const ResetReceivingInspectionItemUseCase(this._repository);

  final ReceivingRepository _repository;

  Future<List<ReceivingInspectionItem>> call({
    required String slipNumber,
    required String itemId,
  }) {
    return _repository.resetInspectionItem(
      slipNumber: slipNumber,
      itemId: itemId,
    );
  }
}
