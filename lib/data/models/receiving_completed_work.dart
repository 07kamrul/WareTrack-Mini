import 'package:waretrack_mini/core/models/completed_work_models.dart';
import 'package:waretrack_mini/core/models/inspection_work_type.dart';

// Re-export so existing imports of this file continue to resolve
// InspectionWorkType without change.
export 'package:waretrack_mini/core/models/inspection_work_type.dart';

/// Internal DB-layer model for a completed work order.
///
/// Used by [AppDatabase] and [ReceivingRepositoryImpl].  Feature layers should
/// reference [CompletedOrderRecord] (the interface) or their own feature-
/// specific model rather than this concrete class directly.
final class ReceivingCompletedWork implements CompletedOrderRecord {
  const ReceivingCompletedWork({
    required this.slipNumber,
    required this.totalItems,
    required this.totalQuantity,
    required this.completedAt,
    this.workType = InspectionWorkType.receiving,
    this.isSent = false,
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
  final InspectionWorkType workType;
  @override
  final bool isSent;

  @override
  String get menuName => workType.menuName;
}

/// Internal DB-layer model for a single completed work item.
///
/// Used by [AppDatabase] and [ReceivingRepositoryImpl].  Feature layers should
/// reference [CompletedItemRecord] (the interface) or their own feature-
/// specific model rather than this concrete class directly.
final class ReceivingCompletedWorkDetail implements CompletedItemRecord {
  const ReceivingCompletedWorkDetail({
    required this.slipNumber,
    required this.code,
    required this.quantity,
    required this.createdAt,
    required this.userId,
    this.workType = InspectionWorkType.receiving,
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
  final InspectionWorkType workType;

  @override
  ReceivingCompletedWorkDetail copyWith({
    String? slipNumber,
    String? code,
    int? quantity,
    DateTime? createdAt,
    String? userId,
    InspectionWorkType? workType,
  }) {
    return ReceivingCompletedWorkDetail(
      slipNumber: slipNumber ?? this.slipNumber,
      code: code ?? this.code,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      workType: workType ?? this.workType,
    );
  }
}
