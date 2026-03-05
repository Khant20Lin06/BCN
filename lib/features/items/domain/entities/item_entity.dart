class ItemEntity {
  const ItemEntity({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.itemGroup,
    required this.stockUom,
    this.image,
    required this.description,
    required this.stockQty,
    required this.disabled,
    required this.hasVariants,
    required this.maintainStock,
    this.isFixedAsset = false,
    required this.valuationRate,
    required this.standardRate,
    required this.modified,
  });

  final String id;
  final String? itemCode;
  final String itemName;
  final String itemGroup;
  final String stockUom;
  final String? image;
  final String? description;
  final double? stockQty;
  final bool disabled;
  final bool hasVariants;
  final bool maintainStock;
  final bool isFixedAsset;
  final double? valuationRate;
  final double? standardRate;
  final DateTime? modified;

  ItemEntity copyWith({
    String? id,
    String? itemCode,
    String? itemName,
    String? itemGroup,
    String? stockUom,
    String? image,
    String? description,
    double? stockQty,
    bool? disabled,
    bool? hasVariants,
    bool? maintainStock,
    bool? isFixedAsset,
    double? valuationRate,
    double? standardRate,
    DateTime? modified,
  }) {
    return ItemEntity(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      itemGroup: itemGroup ?? this.itemGroup,
      stockUom: stockUom ?? this.stockUom,
      image: image ?? this.image,
      description: description ?? this.description,
      stockQty: stockQty ?? this.stockQty,
      disabled: disabled ?? this.disabled,
      hasVariants: hasVariants ?? this.hasVariants,
      maintainStock: maintainStock ?? this.maintainStock,
      isFixedAsset: isFixedAsset ?? this.isFixedAsset,
      valuationRate: valuationRate ?? this.valuationRate,
      standardRate: standardRate ?? this.standardRate,
      modified: modified ?? this.modified,
    );
  }
}
