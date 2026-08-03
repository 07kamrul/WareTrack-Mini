import 'package:waretrack_mini/features/stocking/bloc/stocking_bloc.dart';

final class InventoryBloc extends StockingBloc {
  InventoryBloc({
    required super.recordScan,
    required super.completeWork,
    required super.resetItem,
    required super.deleteItem,
    required super.undoScan,
    required super.feedbackService,
    required super.discardTemporaryWork,
  }) : super();
}
