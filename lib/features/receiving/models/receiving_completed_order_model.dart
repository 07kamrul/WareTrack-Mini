import 'package:waretrack_mini/core/models/completed_work_models.dart';
import 'package:waretrack_mini/core/models/inspection_work_type.dart';

/// Completed work order model for Receiving.
final class ReceivingCompletedOrderModel implements CompletedOrderRecord {
  const ReceivingCompletedOrderModel({
    required this.slipNumber,
    required this.totalItems,
    required this.totalQuantity,
    required this.completedAt,
  });

  @override
  final String slipNumber;
  @override
  final int totalItems;
  @override
  final int totalQuantity;
  @override
  final DateTime completedAt;
  @override
  InspectionWorkType get workType => InspectionWorkType.receiving;
  @override
  String get menuName => workType.menuName;
  @override
  bool get isSent => false;
}
