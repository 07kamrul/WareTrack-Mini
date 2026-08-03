import 'package:waretrack_mini/core/models/completed_work_models.dart';

/// Completed work item model for 入荷検品 (Receiving).
final class ReceivingCompletedItemModel implements CompletedItemRecord {
  const ReceivingCompletedItemModel({
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
  ReceivingCompletedItemModel copyWith({
    String? slipNumber,
    String? code,
    int? quantity,
    DateTime? createdAt,
    String? userId,
  }) {
    return ReceivingCompletedItemModel(
      slipNumber: slipNumber ?? this.slipNumber,
      code: code ?? this.code,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}
