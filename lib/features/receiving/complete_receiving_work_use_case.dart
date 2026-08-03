import 'package:waretrack_mini/data/models/receiving_inspection_item.dart';
import 'package:waretrack_mini/data/local/receiving_repository.dart';

final class CompleteReceivingWorkUseCase {
  const CompleteReceivingWorkUseCase(this._repository);

  final ReceivingRepository _repository;

  Future<List<ReceivingInspectionItem>> call(String slipNumber) {
    return _repository.completeWork(slipNumber);
  }
}
