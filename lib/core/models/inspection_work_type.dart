/// Menu/work-type discriminator shared across all features.
///
/// This enum drives table routing, menu labels, and export column headings.
/// It is intentionally placed in `core/` so every feature can reference it
/// without creating cross-feature dependencies.
enum InspectionWorkType {
  receiving(menuName: '入荷検品'),
  shipping(menuName: '出荷検品'),
  stocking(menuName: '棚入れ'),
  inventory(menuName: '棚卸');

  const InspectionWorkType({required this.menuName});

  final String menuName;

  static InspectionWorkType fromStorage(String value) {
    return switch (value) {
      'shipping' => shipping,
      'stocking' || 'shelfPlacement' || 'shelf_placement' => stocking,
      'inventory' || 'stocktaking' => inventory,
      _ => receiving,
    };
  }
}
