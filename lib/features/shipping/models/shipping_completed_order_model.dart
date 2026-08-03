import 'package:waretrack_mini/core/models/completed_work_models.dart';
import 'package:waretrack_mini/core/models/inspection_work_type.dart';

/// Completed work order model for 出荷検品 (Shipping).
final class ShippingCompletedOrderModel implements CompletedOrderRecord {
  const ShippingCompletedOrderModel({
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
  InspectionWorkType get workType => InspectionWorkType.shipping;
  @override
  String get menuName => workType.menuName;
  @override
  bool get isSent => false;
}
