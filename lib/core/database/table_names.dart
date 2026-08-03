import 'package:waretrack_mini/core/models/inspection_work_type.dart';

abstract final class AppTables {
  static const receivingCompletedOrders = 'receiving_completed_orders';
  static const shippingCompletedOrders = 'shipping_completed_orders';
  static const stockingCompletedOrders = 'stocking_completed_orders';
  static const inventoryCompletedOrders = 'inventory_completed_orders';

  static const receivingCompletedOrderDetails =
      'receiving_completed_order_details';
  static const shippingCompletedOrderDetails =
      'shipping_completed_order_details';
  static const stockingCompletedOrderDetails = 'stocking_completed_items';
  static const inventoryCompletedOrderDetails =
      'inventory_completed_order_details';

  static String completedOrders(InspectionWorkType workType) {
    return switch (workType) {
      InspectionWorkType.receiving => receivingCompletedOrders,
      InspectionWorkType.shipping => shippingCompletedOrders,
      InspectionWorkType.stocking => stockingCompletedOrders,
      InspectionWorkType.inventory => inventoryCompletedOrders,
    };
  }

  static String completedOrderDetails(InspectionWorkType workType) {
    return switch (workType) {
      InspectionWorkType.receiving => receivingCompletedOrderDetails,
      InspectionWorkType.shipping => shippingCompletedOrderDetails,
      InspectionWorkType.stocking => stockingCompletedOrderDetails,
      InspectionWorkType.inventory => inventoryCompletedOrderDetails,
    };
  }
}
