class ItemEntity {
  const ItemEntity({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.itemGroup,
    required this.stockUom,
    this.image,
    required this.description,
    required this.disabled,
    required this.hasVariants,
    required this.valuationRate,
    required this.modified,
  });

  final String id;
  final String? itemCode;
  final String itemName;
  final String itemGroup;
  final String stockUom;
  final String? image;
  final String? description;
  final bool disabled;
  final bool hasVariants;
  final double? valuationRate;
  final DateTime? modified;

  ItemEntity copyWith({
    String? id,
    String? itemCode,
    String? itemName,
    String? itemGroup,
    String? stockUom,
    String? image,
    String? description,
    bool? disabled,
    bool? hasVariants,
    double? valuationRate,
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
      disabled: disabled ?? this.disabled,
      hasVariants: hasVariants ?? this.hasVariants,
      valuationRate: valuationRate ?? this.valuationRate,
      modified: modified ?? this.modified,
    );
  }
}
