import 'package:waretrack_mini/core/models/completed_work_models.dart';

/// Completed work item model for Shipping.
final class ShippingCompletedItemModel implements CompletedItemRecord {
  const ShippingCompletedItemModel({
    required this.slipNumber,
    required this.code,
    required this.quantity,
    required this.createdAt,
    required this.userId,
  });

  @override
  final String slipNumber;
  @override
  final String code;
  @override
  final int quantity;
  @override
  final DateTime createdAt;
  @override
  final String userId;

  @override
  ShippingCompletedItemModel copyWith({
    String? slipNumber,
    String? code,
    int? quantity,
    DateTime? createdAt,
    String? userId,
  }) {
    return ShippingCompletedItemModel(
      slipNumber: slipNumber ?? this.slipNumber,
      code: code ?? this.code,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}
