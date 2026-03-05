class UpdateItemInput {
  const UpdateItemInput({
    required this.itemName,
    required this.itemGroup,
    required this.stockUom,
    this.image,
    this.description,
    this.disabled = false,
    this.hasVariants = false,
    this.maintainStock = true,
    this.openingStock,
    this.valuationRate,
    this.standardRate,
    this.isFixedAsset = false,
  });

  final String itemName;
  final String itemGroup;
  final String stockUom;
  final String? image;
  final String? description;
  final bool disabled;
  final bool hasVariants;
  final bool maintainStock;
  final double? openingStock;
  final double? valuationRate;
  final double? standardRate;
  final bool isFixedAsset;
}
