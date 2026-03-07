class ApiConstants {
  ApiConstants._();

  static const int defaultPageSize = 20;

  static const String loggedUserPath =
      '/api/method/frappe.auth.get_logged_user';
  static const String forgotPasswordPath =
      '/api/method/frappe.core.doctype.user.user.reset_password';
  static const String itemPath = '/api/resource/Item';
  static const String itemPricePath = '/api/resource/Item Price';
  static const String stockBalancePath = '/api/resource/Bin';
  static const String stockReconciliationPath =
      '/api/resource/Stock Reconciliation';
  static const String userPath = '/api/resource/User';
  static const String customerPath = '/api/resource/Customer';
  static const String salesInvoicePath = '/api/resource/Sales Invoice';
  static const String priceListPath = '/api/resource/Price List';
  static const String currencyPath = '/api/resource/Currency';
  static const String warehousePath = '/api/resource/Warehouse';
  static const String modeOfPaymentPath = '/api/resource/Mode of Payment';
  static const String customerGroupPath = '/api/resource/Customer Group';
  static const String territoryPath = '/api/resource/Territory';
  static const String uploadFilePath = '/api/method/upload_file';
  static const String uploadFileV2Path = '/api/v2/method/upload_file';
  static const String itemGroupPath = '/api/resource/Item Group';
  static const String uomPath = '/api/resource/UOM';
  static const String hasRolePath = '/api/resource/Has Role';
  static const String docPermPath = '/api/resource/DocPerm';

  static const List<String> docPermFields = <String>[
    'name',
    'parent',
    'role',
    'permlevel',
    'select',
    'read',
    'write',
    'create',
    'delete',
    'report',
    'print',
    'email',
    'export',
    'import',
    'share',
  ];

  static const List<String> itemFields = <String>[
    'name',
    'item_code',
    'item_name',
    'item_group',
    'stock_uom',
    'image',
    'description',
    'opening_stock',
    'is_stock_item',
    'is_fixed_asset',
    'disabled',
    'has_variants',
    'valuation_rate',
    'standard_rate',
    'modified',
  ];

  static const List<String> customerFields = <String>[
    'name',
    'customer_name',
    'customer_type',
    'customer_group',
    'territory',
    'creation',
    'modified',
  ];

  static const List<String> salesInvoiceFields = <String>[
    'name',
    'customer',
    'posting_date',
    'currency',
    'selling_price_list',
    'set_warehouse',
    'is_pos',
    'grand_total',
    'status',
    'creation',
    'modified',
  ];

  static const List<String> itemPriceFields = <String>[
    'name',
    'item_code',
    'item_name',
    'uom',
    'price_list',
    'valid_from',
    'price_list_rate',
    'creation',
    'modified',
  ];

  static const List<String> stockBalanceFields = <String>[
    'name',
    'item_code',
    'warehouse',
    'actual_qty',
    'stock_uom',
    'valuation_rate',
    'creation',
    'modified',
  ];
}
