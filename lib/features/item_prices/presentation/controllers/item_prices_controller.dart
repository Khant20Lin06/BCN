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
import '../../domain/entities/item_price_entity.dart';
import '../state/item_prices_state.dart';

final itemPricesApiClientProvider = Provider<FrappeApiClient>((Ref ref) {
  return FrappeApiClient(
    storageService: ref.watch(secureStorageServiceProvider),
    dioFactory: DioFactory(ref.watch(appLoggerProvider)),
  );
});

final itemPricesControllerProvider =
    StateNotifierProvider<ItemPricesController, ItemPricesState>((Ref ref) {
      return ItemPricesController(ref.watch(itemPricesApiClientProvider));
    });

final itemPriceDetailProvider = FutureProvider.family<ItemPriceEntity, String>((
  Ref ref,
  String id,
) async {
  return ref.watch(itemPricesControllerProvider.notifier).getItemPriceDetail(id);
});

class ItemPricesController extends StateNotifier<ItemPricesState> {
  ItemPricesController(this._apiClient) : super(const ItemPricesState.initial());

  final FrappeApiClient _apiClient;
  Timer? _searchDebounce;

  Future<void> loadItemPrices() async {
    state = state.copyWith(
      status: ItemPricesStatus.loading,
      errorMessage: null,
    );

    try {
      final Map<String, dynamic> json = await _getWithFieldFallback(
        path: ApiConstants.itemPricePath,
        fields: ApiConstants.itemPriceFields,
        queryParameters: <String, dynamic>{
          'order_by': 'modified desc',
          'limit_page_length': 100,
          ..._searchParams(state.searchQuery),
        },
      );

      final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<ItemPriceEntity> itemPrices = raw
          .whereType<Map<String, dynamic>>()
          .map(_mapItemPrice)
          .toList(growable: false);

      state = state.copyWith(
        status: itemPrices.isEmpty
            ? ItemPricesStatus.empty
            : ItemPricesStatus.success,
        itemPrices: itemPrices,
      );
    } catch (error) {
      state = state.copyWith(
        status: ItemPricesStatus.error,
        errorMessage: _toFailure(error).message,
      );
    }
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(searchQuery: value.trim());
      unawaited(loadItemPrices());
    });
  }

  Future<ItemPriceEntity> getItemPriceDetail(String id) async {
    final Map<String, dynamic> json = await _getWithFieldFallback(
      path: '${ApiConstants.itemPricePath}/${Uri.encodeComponent(id)}',
      fields: ApiConstants.itemPriceFields,
    );

    final Map<String, dynamic> data =
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return _mapItemPrice(data);
  }

  Future<List<ItemPriceItemOption>> fetchItemOptions() async {
    const int pageSize = 200;
    int offset = 0;
    final Map<String, ItemPriceItemOption> byCode = <String, ItemPriceItemOption>{};

    while (true) {
      final Map<String, dynamic> json = await _getWithFieldFallback(
        path: ApiConstants.itemPath,
        fields: const <String>['name', 'item_code', 'item_name', 'stock_uom'],
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
        final String itemName = (row['item_name'] as String? ?? '').trim();
        final String stockUom = (row['stock_uom'] as String? ?? '').trim();
        final String fallbackName = (row['name'] as String? ?? '').trim();
        final String value = itemCode.isNotEmpty ? itemCode : fallbackName;
        if (value.isEmpty) {
          continue;
        }

        final String lead = itemCode.isNotEmpty ? itemCode : fallbackName;
        final String label = itemName.isNotEmpty && itemName != lead
            ? '$lead - $itemName'
            : lead;
        byCode[value] = ItemPriceItemOption(
          value: value,
          label: label,
          itemName: itemName.isNotEmpty ? itemName : lead,
          stockUom: stockUom,
        );
      }

      if (rows.length < pageSize) {
        break;
      }
      offset += pageSize;
    }

    final List<ItemPriceItemOption> options = byCode.values.toList(
      growable: false,
    );
    options.sort(
      (ItemPriceItemOption a, ItemPriceItemOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return options;
  }

  Future<List<String>> fetchPriceListOptions() async {
    return _fetchAllNameOptions(
      endpoint: ApiConstants.priceListPath,
      fallbackWhenEmpty: const <String>['Standard Selling'],
    );
  }

  Future<List<String>> fetchUomOptions() async {
    return _fetchAllNameOptions(endpoint: ApiConstants.uomPath);
  }

  Future<Failure?> createItemPrice({
    String? priceId,
    required String itemCode,
    required String itemName,
    required String uom,
    required String priceList,
    required String validFrom,
    required double rate,
  }) async {
    try {
      final String id = (priceId ?? '').trim();
      final Map<String, dynamic> payload = <String, dynamic>{
        if (id.isNotEmpty) 'name': id,
        'item_code': itemCode.trim(),
        if (itemName.trim().isNotEmpty) 'item_name': itemName.trim(),
        if (uom.trim().isNotEmpty) 'uom': uom.trim(),
        'price_list': priceList.trim(),
        'valid_from': validFrom.trim(),
        'price_list_rate': rate,
      };

      await _apiClient.post(ApiConstants.itemPricePath, data: payload);
      await loadItemPrices();
      return null;
    } catch (error) {
      return _toFailure(error);
    }
  }

  Future<Failure?> updateItemPrice({
    required String id,
    required String itemName,
    required String uom,
    required String priceList,
    required String validFrom,
    required double rate,
  }) async {
    try {
      final Map<String, dynamic> payload = <String, dynamic>{
        if (itemName.trim().isNotEmpty) 'item_name': itemName.trim(),
        if (uom.trim().isNotEmpty) 'uom': uom.trim(),
        'price_list': priceList.trim(),
        'valid_from': validFrom.trim(),
        'price_list_rate': rate,
      };

      await _apiClient.put(
        '${ApiConstants.itemPricePath}/${Uri.encodeComponent(id)}',
        data: payload,
      );
      await loadItemPrices();
      return null;
    } catch (error) {
      return _toFailure(error);
    }
  }

  Future<Failure?> deleteItemPrice(String id) async {
    try {
      await _apiClient.delete(
        '${ApiConstants.itemPricePath}/${Uri.encodeComponent(id)}',
      );
      await loadItemPrices();
      return null;
    } catch (error) {
      return _toFailure(error);
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

  Future<List<String>> _fetchAllNameOptions({
    required String endpoint,
    List<String> fallbackWhenEmpty = const <String>[],
  }) async {
    const int pageSize = 200;
    int offset = 0;
    final Set<String> values = <String>{};

    while (true) {
      final Map<String, dynamic> json = await _getWithFieldFallback(
        path: endpoint,
        fields: const <String>['name'],
        queryParameters: <String, dynamic>{
          'order_by': 'name asc',
          'limit_start': offset,
          'limit_page_length': pageSize,
        },
      );

      final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<String> batch = raw
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> row) => (row['name'] as String? ?? '').trim())
          .where((String value) => value.isNotEmpty)
          .toList(growable: false);
      values.addAll(batch);

      if (batch.length < pageSize) {
        break;
      }
      offset += pageSize;
    }

    if (values.isEmpty) {
      values.addAll(fallbackWhenEmpty);
    }

    final List<String> result = values.toList(growable: false);
    result.sort(
      (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    return result;
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
        <dynamic>['item_name', 'like', '%$value%'],
        <dynamic>['price_list', 'like', '%$value%'],
      ]),
    };
  }

  ItemPriceEntity _mapItemPrice(Map<String, dynamic> data) {
    return ItemPriceEntity(
      id: (data['name'] as String? ?? '').trim(),
      itemCode: (data['item_code'] as String? ?? '').trim(),
      itemName: (data['item_name'] as String? ?? '').trim(),
      uom: (data['uom'] as String? ?? '').trim(),
      priceList: (data['price_list'] as String? ?? '').trim(),
      validFrom: _toDate(data['valid_from']),
      priceListRate: _toDouble(data['price_list_rate']),
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

class ItemPriceItemOption {
  const ItemPriceItemOption({
    required this.value,
    required this.label,
    required this.itemName,
    required this.stockUom,
  });

  final String value;
  final String label;
  final String itemName;
  final String stockUom;
}
