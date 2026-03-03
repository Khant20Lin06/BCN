class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://bcn-mobile.s.frappe.cloud';

  static const int defaultPageSize = 20;

  static const String loggedUserPath =
      '/api/method/frappe.auth.get_logged_user';
  static const String itemPath = '/api/resource/Item';
  static const String userPath = '/api/resource/User';
  static const String uploadFilePath = '/api/method/upload_file';
  static const String uploadFileV2Path = '/api/v2/method/upload_file';
  static const String itemGroupPath = '/api/resource/Item Group';
  static const String uomPath = '/api/resource/UOM';

  static const List<String> itemFields = <String>[
    'name',
    'item_code',
    'item_name',
    'item_group',
    'stock_uom',
    'image',
    'description',
    'disabled',
    'has_variants',
    'valuation_rate',
    'modified',
  ];
}
