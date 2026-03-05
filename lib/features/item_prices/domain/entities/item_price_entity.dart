class ItemPriceEntity {
  const ItemPriceEntity({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.uom,
    required this.priceList,
    required this.validFrom,
    required this.priceListRate,
    required this.creation,
    required this.modified,
  });

  final String id;
  final String itemCode;
  final String itemName;
  final String uom;
  final String priceList;
  final DateTime? validFrom;
  final double? priceListRate;
  final DateTime? creation;
  final DateTime? modified;

  String get displayName {
    if (itemCode.trim().isNotEmpty) {
      return itemCode.trim();
    }
    if (itemName.trim().isNotEmpty) {
      return itemName.trim();
    }
    return id;
  }
}
