class StockBalanceEntity {
  const StockBalanceEntity({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.warehouse,
    required this.actualQty,
    required this.uom,
    required this.valuationRate,
    required this.creation,
    required this.modified,
  });

  final String id;
  final String itemCode;
  final String itemName;
  final String warehouse;
  final double? actualQty;
  final String uom;
  final double? valuationRate;
  final DateTime? creation;
  final DateTime? modified;

  String get displayName {
    final String code = itemCode.trim();
    final String name = itemName.trim();
    if (code.isNotEmpty && name.isNotEmpty && code != name) {
      return '$code - $name';
    }
    if (code.isNotEmpty) {
      return code;
    }
    if (name.isNotEmpty) {
      return name;
    }
    return id;
  }
}
