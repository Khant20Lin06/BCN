import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/frappe_api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/stock_balance_entity.dart';
import '../state/stock_balances_state.dart';

final stockBalancesApiClientProvider = Provider<FrappeApiClient>((Ref ref) {
  return FrappeApiClient(
    storageService: ref.watch(secureStorageServiceProvider),
    dioFactory: DioFactory(ref.watch(appLoggerProvider)),
  );
});

final stockBalancesControllerProvider =
    StateNotifierProvider<StockBalancesController, StockBalancesState>((
      Ref ref,
    ) {
      return StockBalancesController(ref.watch(stockBalancesApiClientProvider));
    });

final stockBalanceDetailProvider =
    FutureProvider.family<StockBalanceEntity, String>((Ref ref, String id) {
      return ref
          .watch(stockBalancesControllerProvider.notifier)
          .getStockBalanceDetail(id);
    });

class StockBalancesController extends StateNotifier<StockBalancesState> {
  StockBalancesController(this._apiClient)
    : super(const StockBalancesState.initial());

  final FrappeApiClient _apiClient;
  Timer? _searchDebounce;

  Future<void> loadStockBalances() async {
    state = state.copyWith(
      status: StockBalancesStatus.loading,
      errorMessage: null,
    );

    try {
      final Map<String, dynamic> json = await _getWithFieldFallback(
        path: ApiConstants.stockBalancePath,
        fields: ApiConstants.stockBalanceFields,
        queryParameters: <String, dynamic>{
          'order_by': 'modified desc',
          'limit_page_length': 100,
          ..._searchParams(state.searchQuery),
        },
      );

      final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<Map<String, dynamic>> rows = raw
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final Map<String, String> itemNameMap = await _fetchItemNameMap(rows);

      final List<StockBalanceEntity> stockBalances = rows
          .map((Map<String, dynamic> row) => _mapStockBalance(row, itemNameMap))
          .toList(growable: false);

      state = state.copyWith(
        status: stockBalances.isEmpty
            ? StockBalancesStatus.empty
            : StockBalancesStatus.success,
        stockBalances: stockBalances,
      );
    } catch (error) {
      state = state.copyWith(
        status: StockBalancesStatus.error,
        errorMessage: _toFailure(error).message,
      );
    }
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(searchQuery: value.trim());
      unawaited(loadStockBalances());
    });
  }

  Future<StockBalanceEntity> getStockBalanceDetail(String id) async {
    final Map<String, dynamic> json = await _getWithFieldFallback(
      path: '${ApiConstants.stockBalancePath}/${Uri.encodeComponent(id)}',
      fields: ApiConstants.stockBalanceFields,
    );

    final Map<String, dynamic> data =
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, String> itemNameMap = await _fetchItemNameMap(
      <Map<String, dynamic>>[data],
    );
    return _mapStockBalance(data, itemNameMap);
  }

  Future<List<StockItemOption>> fetchItemOptions() async {
    const int pageSize = 200;
    int offset = 0;
    final Map<String, StockItemOption> byCode = <String, StockItemOption>{};

    while (true) {
      final Map<String, dynamic> json = await _getWithFieldFallback(
        path: ApiConstants.itemPath,
        fields: const <String>[
          'name',
          'item_code',
          'item_name',
          'stock_uom',
          'valuation_rate',
        ],
        queryParameters: <String, dynamic>{
          'order_by': 'item_name asc',
          'limit_start': offset,
          'limit_page_length': pageSize,
        },
      );

      final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<Map<String, dynamic>> rows = raw
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      for (final Map<String, dynamic> row in rows) {
        final String itemCode = (row['item_code'] as String? ?? '').trim();
        final String fallbackName = (row['name'] as String? ?? '').trim();
        final String itemName = (row['item_name'] as String? ?? '').trim();
        final String uom = (row['stock_uom'] as String? ?? '').trim();
        final double? valuationRate = _toDouble(row['valuation_rate']);
        final String value = itemCode.isNotEmpty ? itemCode : fallbackName;
        if (value.isEmpty) {
          continue;
        }

        final String lead = itemCode.isNotEmpty ? itemCode : fallbackName;
        final String label = itemName.isNotEmpty && itemName != lead
            ? '$lead - $itemName'
            : lead;
        byCode[value] = StockItemOption(
          value: value,
          label: label,
          uom: uom,
          valuationRate: valuationRate,
        );
      }

      if (rows.length < pageSize) {
        break;
      }
      offset += pageSize;
    }

    final List<StockItemOption> options = byCode.values.toList(growable: false);
    options.sort(
      (StockItemOption a, StockItemOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return options;
  }

  Future<List<String>> fetchWarehouseOptions() async {
    try {
      final List<String> leafWarehouses = await _fetchAllNameOptions(
        endpoint: ApiConstants.warehousePath,
        filters: const <List<dynamic>>[
          <dynamic>['Warehouse', 'is_group', '=', 0],
        ],
      );
      if (leafWarehouses.isNotEmpty) {
        return leafWarehouses;
      }

      final List<String> all = await _fetchAllNameOptions(
        endpoint: ApiConstants.warehousePath,
      );
      final List<String> filtered = all
          .where(
            (String name) =>
                !name.trim().toLowerCase().startsWith('all warehouses'),
          )
          .toList(growable: false);

      if (filtered.isNotEmpty) {
        return filtered;
      }

      throw const ValidationFailure(
        message:
            'No selectable warehouse found. Please create a leaf Warehouse (is_group = 0).',
      );
    } catch (error) {
      final Failure failure = _toFailure(error);
      if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
        throw const ForbiddenFailure(
          message:
              'Warehouse dropdown needs Read/Select permission on Warehouse Doctype.',
        );
      }
      throw failure;
    }
  }

  Future<List<String>> fetchUomOptions() async {
    return _fetchAllNameOptions(endpoint: ApiConstants.uomPath);
  }

  Future<Failure?> createStockBalance({
    String? stockBalanceId,
    required String itemCode,
    required String warehouse,
    required double actualQty,
    String? uom,
    double? valuationRate,
  }) async {
    final String normalizedItemCode = itemCode.trim();
    final String normalizedWarehouse = warehouse.trim();
    final String normalizedUom = (uom ?? '').trim();
    final bool isGroupWarehouse = await _isGroupWarehouse(normalizedWarehouse);
    if (isGroupWarehouse) {
      return const ValidationFailure(
        message:
            'Group warehouse is not allowed for transactions. Please choose a leaf warehouse.',
      );
    }
    try {
      final String id = (stockBalanceId ?? '').trim();
      final Map<String, dynamic> payload = <String, dynamic>{
        if (id.isNotEmpty) 'name': id,
        'item_code': normalizedItemCode,
        'warehouse': normalizedWarehouse,
        'actual_qty': actualQty,
        if (normalizedUom.isNotEmpty) 'stock_uom': normalizedUom,
      };

      await _apiClient.post(ApiConstants.stockBalancePath, data: payload);
      await loadStockBalances();
      return null;
    } catch (error) {
      final Failure failure = _toFailure(error);
      if (failure is ForbiddenFailure) {
        try {
          final double? resolvedValuationRate =
              await _resolveValuationRateForFallback(
                itemCode: normalizedItemCode,
                fallbackValuationRate: valuationRate,
              );
          if (resolvedValuationRate == null || resolvedValuationRate <= 0) {
            return const ValidationFailure(
              message: 'Valuation Rate must be greater than 0 for this item.',
            );
          }
          await _setQtyViaStockReconciliation(
            itemCode: normalizedItemCode,
            warehouse: normalizedWarehouse,
            actualQty: actualQty,
            uom: normalizedUom,
            valuationRate: resolvedValuationRate,
          );
          await loadStockBalances();
          return null;
        } catch (fallbackError) {
          return _toFailure(fallbackError);
        }
      }
      return failure;
    }
  }

  Future<Failure?> updateStockBalance({
    required String id,
    required String itemCode,
    required String warehouse,
    required double actualQty,
    String? uom,
    double? valuationRate,
  }) async {
    final String normalizedItemCode = itemCode.trim();
    final String normalizedWarehouse = warehouse.trim();
    final String normalizedUom = (uom ?? '').trim();
    final bool isGroupWarehouse = await _isGroupWarehouse(normalizedWarehouse);
    if (isGroupWarehouse) {
      return const ValidationFailure(
        message:
            'Group warehouse is not allowed for transactions. Please choose a leaf warehouse.',
      );
    }
    try {
      final Map<String, dynamic> payload = <String, dynamic>{
        'actual_qty': actualQty,
        if (normalizedUom.isNotEmpty) 'stock_uom': normalizedUom,
      };

      await _apiClient.put(
        '${ApiConstants.stockBalancePath}/${Uri.encodeComponent(id)}',
        data: payload,
      );
      await loadStockBalances();
      return null;
    } catch (error) {
      final Failure failure = _toFailure(error);
      if (failure is ForbiddenFailure) {
        try {
          final double? resolvedValuationRate =
              await _resolveValuationRateForFallback(
                itemCode: normalizedItemCode,
                fallbackValuationRate: valuationRate,
              );
          if (resolvedValuationRate == null || resolvedValuationRate <= 0) {
            return const ValidationFailure(
              message: 'Valuation Rate must be greater than 0 for this item.',
            );
          }
          await _setQtyViaStockReconciliation(
            itemCode: normalizedItemCode,
            warehouse: normalizedWarehouse,
            actualQty: actualQty,
            uom: normalizedUom,
            valuationRate: resolvedValuationRate,
          );
          await loadStockBalances();
          return null;
        } catch (fallbackError) {
          return _toFailure(fallbackError);
        }
      }
      return failure;
    }
  }

  Future<Failure?> deleteStockBalance({
    required String id,
    required String itemCode,
    required String warehouse,
    String? uom,
    double? valuationRate,
  }) async {
    final String normalizedItemCode = itemCode.trim();
    final String normalizedWarehouse = warehouse.trim();
    final String normalizedUom = (uom ?? '').trim();
    try {
      await _apiClient.delete(
        '${ApiConstants.stockBalancePath}/${Uri.encodeComponent(id)}',
      );
      await loadStockBalances();
      return null;
    } catch (error) {
      final Failure failure = _toFailure(error);
      if (failure is ForbiddenFailure) {
        try {
          final double? resolvedValuationRate =
              await _resolveValuationRateForFallback(
                itemCode: normalizedItemCode,
                fallbackValuationRate: valuationRate,
              );
          if (resolvedValuationRate == null || resolvedValuationRate <= 0) {
            return const ValidationFailure(
              message: 'Valuation Rate must be greater than 0 for this item.',
            );
          }
          await _setQtyViaStockReconciliation(
            itemCode: normalizedItemCode,
            warehouse: normalizedWarehouse,
            actualQty: 0,
            uom: normalizedUom,
            valuationRate: resolvedValuationRate,
          );
          await loadStockBalances();
          return null;
        } catch (fallbackError) {
          return _toFailure(fallbackError);
        }
      }
      return failure;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getWithFieldFallback({
    required String path,
    required List<String> fields,
    Map<String, dynamic>? queryParameters,
  }) async {
    final List<String> activeFields = List<String>.from(fields);
    String? orderBy = (queryParameters?['order_by'] as String?)?.trim();

    while (true) {
      final Map<String, dynamic> params = <String, dynamic>{
        ...?queryParameters,
        'fields': jsonEncode(activeFields),
        if (orderBy != null && orderBy.isNotEmpty) 'order_by': orderBy,
      };
      try {
        return await _apiClient.get(path, queryParameters: params);
      } on DioException catch (error) {
        final String? blockedField = _extractBlockedField(error);
        if (blockedField == null) {
          rethrow;
        }
        if (activeFields.remove(blockedField)) {
          continue;
        }
        if (orderBy != null &&
            orderBy.isNotEmpty &&
            orderBy.toLowerCase().contains(blockedField.toLowerCase())) {
          orderBy = 'modified desc';
          continue;
        }
        rethrow;
      }
    }
  }

  Future<Map<String, String>> _fetchItemNameMap(
    List<Map<String, dynamic>> rows,
  ) async {
    final Set<String> codes = rows
        .map(
          (Map<String, dynamic> row) =>
              (row['item_code'] as String? ?? '').trim(),
        )
        .where((String value) => value.isNotEmpty)
        .toSet();
    if (codes.isEmpty) {
      return const <String, String>{};
    }

    final Map<String, String> names = <String, String>{};
    final List<String> codeList = codes.toList(growable: false);
    const int chunkSize = 50;
    for (int start = 0; start < codeList.length; start += chunkSize) {
      final int end = (start + chunkSize) > codeList.length
          ? codeList.length
          : (start + chunkSize);
      final List<String> chunk = codeList.sublist(start, end);

      try {
        final Map<String, dynamic> byItemCode = await _getWithFieldFallback(
          path: ApiConstants.itemPath,
          fields: const <String>['name', 'item_code', 'item_name'],
          queryParameters: <String, dynamic>{
            'filters': jsonEncode(<List<dynamic>>[
              <dynamic>['Item', 'item_code', 'in', chunk],
            ]),
            'limit_page_length': chunk.length,
          },
        );
        _collectItemNames(
          source: byItemCode,
          target: names,
          preferKey: 'item_code',
        );
      } catch (_) {
        final Map<String, dynamic> byName = await _getWithFieldFallback(
          path: ApiConstants.itemPath,
          fields: const <String>['name', 'item_name'],
          queryParameters: <String, dynamic>{
            'filters': jsonEncode(<List<dynamic>>[
              <dynamic>['Item', 'name', 'in', chunk],
            ]),
            'limit_page_length': chunk.length,
          },
        );
        _collectItemNames(source: byName, target: names, preferKey: 'name');
      }
    }

    return names;
  }

  void _collectItemNames({
    required Map<String, dynamic> source,
    required Map<String, String> target,
    required String preferKey,
  }) {
    final List<dynamic> raw = (source['data'] as List<dynamic>?) ?? <dynamic>[];
    for (final Map<String, dynamic> row
        in raw.whereType<Map<String, dynamic>>()) {
      final String key = (row[preferKey] as String? ?? '').trim();
      final String fallback = (row['name'] as String? ?? '').trim();
      final String itemName = (row['item_name'] as String? ?? '').trim();
      final String mapped = itemName.isNotEmpty ? itemName : fallback;
      if (key.isNotEmpty && mapped.isNotEmpty) {
        target[key] = mapped;
      }
      if (fallback.isNotEmpty && mapped.isNotEmpty) {
        target[fallback] = mapped;
      }
    }
  }

  Future<List<String>> _fetchAllNameOptions({
    required String endpoint,
    String orderBy = 'name asc',
    List<List<dynamic>>? filters,
  }) async {
    const int pageSize = 200;
    int offset = 0;
    final Set<String> values = <String>{};

    while (true) {
      final Map<String, dynamic> json = await _getWithFieldFallback(
        path: endpoint,
        fields: const <String>['name'],
        queryParameters: <String, dynamic>{
          'order_by': orderBy,
          'limit_start': offset,
          'limit_page_length': pageSize,
          if (filters != null && filters.isNotEmpty)
            'filters': jsonEncode(filters),
        },
      );

      final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<String> batch = raw
          .whereType<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> row) => (row['name'] as String? ?? '').trim(),
          )
          .where((String value) => value.isNotEmpty)
          .toList(growable: false);
      values.addAll(batch);

      if (batch.length < pageSize) {
        break;
      }
      offset += pageSize;
    }

    final List<String> result = values.toList(growable: false);
    result.sort(
      (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    return result;
  }

  Future<bool> _isGroupWarehouse(String warehouse) async {
    final String normalized = warehouse.trim();
    if (normalized.isEmpty) {
      return false;
    }
    try {
      final Map<String, dynamic> json = await _getWithFieldFallback(
        path:
            '${ApiConstants.warehousePath}/${Uri.encodeComponent(normalized)}',
        fields: const <String>['name', 'is_group'],
      );
      final Map<String, dynamic> data =
          (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      return _toBool(data['is_group']);
    } catch (_) {
      return normalized.toLowerCase().startsWith('all warehouses');
    }
  }

  Map<String, dynamic> _searchParams(String search) {
    final String value = search.trim();
    if (value.isEmpty) {
      return const <String, dynamic>{};
    }
    return <String, dynamic>{
      'or_filters': jsonEncode(<List<dynamic>>[
        <dynamic>['name', 'like', '%$value%'],
        <dynamic>['item_code', 'like', '%$value%'],
        <dynamic>['warehouse', 'like', '%$value%'],
      ]),
    };
  }

  Future<void> _setQtyViaStockReconciliation({
    required String itemCode,
    required String warehouse,
    required double actualQty,
    required double valuationRate,
    String? uom,
  }) async {
    final String normalizedUom = (uom ?? '').trim();
    final Map<String, dynamic> payload = <String, dynamic>{
      'purpose': 'Stock Reconciliation',
      'posting_date': _todayIsoDate(),
      'set_posting_time': 1,
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'item_code': itemCode,
          'warehouse': warehouse,
          'qty': actualQty,
          'valuation_rate': valuationRate,
          if (normalizedUom.isNotEmpty) 'uom': normalizedUom,
        },
      ],
    };

    final Map<String, dynamic> created = await _apiClient.post(
      ApiConstants.stockReconciliationPath,
      data: payload,
    );

    final Map<String, dynamic> data =
        (created['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final String name = (data['name'] as String? ?? '').trim();
    if (name.isEmpty) {
      return;
    }
    await _submitStockReconciliation(name);
  }

  Future<void> _submitStockReconciliation(String name) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      final Map<String, dynamic> doc = await _fetchReconciliationDoc(name);
      try {
        await _postSubmitDoc(doc);
        return;
      } on DioException catch (error) {
        if (_isStaleDocumentError(error) && attempt < 2) {
          continue;
        }
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> _fetchReconciliationDoc(String name) async {
    final Map<String, dynamic> json = await _apiClient.get(
      '${ApiConstants.stockReconciliationPath}/${Uri.encodeComponent(name)}',
    );
    return (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<void> _postSubmitDoc(Map<String, dynamic> doc) async {
    try {
      await _apiClient.postRaw(
        '/api/method/frappe.client.submit',
        data: <String, dynamic>{'doc': doc},
      );
    } on DioException {
      await _apiClient.postRaw(
        '/api/method/frappe.client.submit',
        data: <String, dynamic>{'doc': jsonEncode(doc)},
      );
    }
  }

  bool _isStaleDocumentError(DioException error) {
    final String payload = <String>[
      error.message ?? '',
      _toText(error.response?.data),
    ].join(' ').toLowerCase();
    return payload.contains(
      'document has been modified after you have opened it',
    );
  }

  String _todayIsoDate() {
    final DateTime now = DateTime.now();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<double?> _resolveValuationRateForFallback({
    required String itemCode,
    double? fallbackValuationRate,
  }) async {
    if (fallbackValuationRate != null && fallbackValuationRate > 0) {
      return fallbackValuationRate;
    }

    try {
      final Map<String, dynamic> json = await _getWithFieldFallback(
        path: ApiConstants.itemPath,
        fields: const <String>['item_code', 'valuation_rate'],
        queryParameters: <String, dynamic>{
          'filters': jsonEncode(<List<dynamic>>[
            <dynamic>['Item', 'item_code', '=', itemCode],
          ]),
          'limit_page_length': 1,
        },
      );
      final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
      if (raw.isEmpty) {
        return _fetchItemPriceRate(itemCode);
      }
      final Map<String, dynamic> row = raw.first as Map<String, dynamic>;
      final double? valuationRate = _toDouble(row['valuation_rate']);
      if (valuationRate != null && valuationRate > 0) {
        return valuationRate;
      }
      return _fetchItemPriceRate(itemCode);
    } catch (_) {
      return _fetchItemPriceRate(itemCode);
    }
  }

  Future<double?> _fetchItemPriceRate(String itemCode) async {
    try {
      final Map<String, dynamic> json = await _getWithFieldFallback(
        path: ApiConstants.itemPricePath,
        fields: const <String>['item_code', 'price_list_rate', 'buying'],
        queryParameters: <String, dynamic>{
          'filters': jsonEncode(<List<dynamic>>[
            <dynamic>['Item Price', 'item_code', '=', itemCode],
            <dynamic>['Item Price', 'buying', '=', 1],
          ]),
          'order_by': 'modified desc',
          'limit_page_length': 1,
        },
      );
      final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
      if (raw.isEmpty) {
        return null;
      }
      final Map<String, dynamic> row = raw.first as Map<String, dynamic>;
      final double? rate = _toDouble(row['price_list_rate']);
      if (rate == null || rate <= 0) {
        return null;
      }
      return rate;
    } catch (_) {
      return null;
    }
  }

  StockBalanceEntity _mapStockBalance(
    Map<String, dynamic> data,
    Map<String, String> itemNameMap,
  ) {
    final String itemCode = (data['item_code'] as String? ?? '').trim();
    final String directItemName = (data['item_name'] as String? ?? '').trim();
    final String itemName = directItemName.isNotEmpty
        ? directItemName
        : (itemNameMap[itemCode] ??
              itemNameMap[(data['name'] as String? ?? '').trim()] ??
              '');

    return StockBalanceEntity(
      id: (data['name'] as String? ?? '').trim(),
      itemCode: itemCode,
      itemName: itemName,
      warehouse: (data['warehouse'] as String? ?? '').trim(),
      actualQty: _toDouble(data['actual_qty']),
      uom: (data['stock_uom'] as String? ?? '').trim(),
      valuationRate: _toDouble(data['valuation_rate']),
      creation: _toDate(data['creation']),
      modified: _toDate(data['modified']),
    );
  }

  Failure _toFailure(Object error) {
    if (error is Failure) {
      return error;
    }
    return mapExceptionToFailure(error);
  }

  String? _extractBlockedField(DioException error) {
    final String payload = <String>[
      error.message ?? '',
      _toText(error.response?.data),
    ].join(' ');
    final RegExpMatch? match = RegExp(
      r'Field not permitted in query:\s*([a-zA-Z0-9_]+)',
      caseSensitive: false,
    ).firstMatch(payload);
    return match?.group(1);
  }

  String _toText(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    if (value is Map) {
      return value.values.map((dynamic e) => e.toString()).join(' ');
    }
    return value.toString();
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true' || normalized == 'yes';
    }
    return false;
  }

  DateTime? _toDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is! String) {
      return null;
    }
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return DateTime.tryParse(normalized) ??
        DateTime.tryParse(normalized.replaceFirst(' ', 'T'));
  }
}

class StockItemOption {
  const StockItemOption({
    required this.value,
    required this.label,
    required this.uom,
    this.valuationRate,
  });

  final String value;
  final String label;
  final String uom;
  final double? valuationRate;
}
