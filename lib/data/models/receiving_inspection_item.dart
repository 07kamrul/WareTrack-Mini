enum ReceivingInspectionStatus { pending, completed }

enum ReceivingInspectionFilter { hide, slipOnly, all }

final class ReceivingInspectionItem {
  const ReceivingInspectionItem({
    required this.id,
    required this.slipNumber,
    required this.barcode,
    required this.productName,
    required this.expectedQuantity,
    required this.inspectedQuantity,
    required this.status,
  });

  final String id;
  final String slipNumber;
  final String barcode;
  final String productName;
  final int expectedQuantity;
  final int inspectedQuantity;
  final ReceivingInspectionStatus status;

  bool get isCompleted => status == ReceivingInspectionStatus.completed;

  ReceivingInspectionItem copyWith({
    String? id,
    String? slipNumber,
    String? barcode,
    String? productName,
    int? expectedQuantity,
    int? inspectedQuantity,
    ReceivingInspectionStatus? status,
  }) {
    return ReceivingInspectionItem(
      id: id ?? this.id,
      slipNumber: slipNumber ?? this.slipNumber,
      barcode: barcode ?? this.barcode,
      productName: productName ?? this.productName,
      expectedQuantity: expectedQuantity ?? this.expectedQuantity,
      inspectedQuantity: inspectedQuantity ?? this.inspectedQuantity,
      status: status ?? this.status,
    );
  }
}
