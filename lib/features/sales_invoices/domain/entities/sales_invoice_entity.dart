class SalesInvoiceEntity {
  const SalesInvoiceEntity({
    required this.id,
    required this.customer,
    this.postingDate,
    required this.currency,
    required this.priceList,
    required this.sourceWarehouse,
    required this.grandTotal,
    required this.status,
    this.items = const <SalesInvoiceLineEntity>[],
    this.creation,
    this.modified,
  });

  final String id;
  final String customer;
  final DateTime? postingDate;
  final String currency;
  final String priceList;
  final String sourceWarehouse;
  final double grandTotal;
  final String status;
  final List<SalesInvoiceLineEntity> items;
  final DateTime? creation;
  final DateTime? modified;
}

class SalesInvoiceLineEntity {
  const SalesInvoiceLineEntity({
    required this.itemCode,
    required this.qty,
    this.rate,
  });

  final String itemCode;
  final double qty;
  final double? rate;
}
