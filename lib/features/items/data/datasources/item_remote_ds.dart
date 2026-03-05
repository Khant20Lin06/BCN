import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/frappe_api_client.dart';
import '../../domain/entities/create_item_input.dart';
import '../../domain/entities/update_item_input.dart';
import '../../domain/value_objects/item_query.dart';
import '../dtos/frappe_list_response_dto.dart';
import '../dtos/item_dto.dart';
import '../mappers/item_mapper.dart';

class ItemRemoteDataSource {
  const ItemRemoteDataSource({
    required FrappeApiClient apiClient,
    required ItemMapper mapper,
  }) : _apiClient = apiClient,
       _mapper = mapper;

  final FrappeApiClient _apiClient;
  final ItemMapper _mapper;

  Future<List<ItemDto>> fetchItems(ItemQuery query) async {
    final List<String> fields = List<String>.from(ApiConstants.itemFields);
    while (true) {
      try {
        final Map<String, dynamic> json = await _apiClient.get(
          ApiConstants.itemPath,
          queryParameters: _buildListQueryParams(query, fields),
        );
        final FrappeListResponseDto response = FrappeListResponseDto.fromJson(
          json,
        );
        final List<ItemDto> items = response.data
            .map(ItemDto.fromJson)
            .toList(growable: false);
        final Map<String, double> priceByCode = await _fetchItemPriceMap(items);
        final List<ItemDto> merged = _mergeItemPrices(items, priceByCode);
        if (query.sortField == ItemSortField.price) {
          merged.sort(
            (ItemDto a, ItemDto b) => _compareNullableDouble(
              a.standardRate,
              b.standardRate,
              ascending: query.sortAscending,
            ),
          );
        } else if (query.sortField == ItemSortField.qty) {
          merged.sort(
            (ItemDto a, ItemDto b) => _compareNullableDouble(
              a.openingStock,
              b.openingStock,
              ascending: query.sortAscending,
            ),
          );
        }
        return merged;
      } on DioException catch (error) {
        final String? blockedField = _extractBlockedField(error);
        if (blockedField == null || !fields.remove(blockedField)) {
          rethrow;
        }
      }
    }
  }

  Future<ItemDto> fetchItemDetail(String id) async {
    final List<String> fields = List<String>.from(ApiConstants.itemFields);
    while (true) {
      try {
        final Map<String, dynamic> json = await _apiClient.get(
          '${ApiConstants.itemPath}/$id',
          queryParameters: <String, dynamic>{'fields': jsonEncode(fields)},
        );

        final Map<String, dynamic> data =
            (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final ItemDto dto = ItemDto.fromJson(data);
        final Map<String, double> priceByCode = await _fetchItemPriceMap(
          <ItemDto>[dto],
        );
        return _mergeItemPrices(<ItemDto>[dto], priceByCode).first;
      } on DioException catch (error) {
        final String? blockedField = _extractBlockedField(error);
        if (blockedField == null || !fields.remove(blockedField)) {
          rethrow;
        }
      }
    }
  }

  Future<ItemDto> createItem(CreateItemInput input) async {
    final Map<String, dynamic> json = await _apiClient.post(
      ApiConstants.itemPath,
      data: _mapper.createInputToPayload(input),
    );
    final Map<String, dynamic> data =
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return ItemDto.fromJson(data);
  }

  Future<ItemDto> updateItem(String id, UpdateItemInput input) async {
    final Map<String, dynamic> json = await _apiClient.put(
      '${ApiConstants.itemPath}/$id',
      data: _mapper.updateInputToPayload(input),
    );
    final Map<String, dynamic> data =
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return ItemDto.fromJson(data);
  }

  Future<void> softDeleteItem(String id) async {
    await _apiClient.put(
      '${ApiConstants.itemPath}/$id',
      data: <String, dynamic>{'disabled': 1},
    );
  }

  Future<void> hardDeleteItem(String id) async {
    await _apiClient.delete('${ApiConstants.itemPath}/$id');
  }

  Future<List<String>> fetchItemGroups() async {
    return _fetchAllNameOptions(ApiConstants.itemGroupPath);
  }

  Future<List<String>> fetchUoms() async {
    return _fetchAllNameOptions(ApiConstants.uomPath);
  }

  Future<List<String>> _fetchAllNameOptions(String endpoint) async {
    const int pageSize = 200;
    int offset = 0;
    final Set<String> values = <String>{};

    while (true) {
      final Map<String, dynamic> json = await _apiClient.get(
        endpoint,
        queryParameters: <String, dynamic>{
          'fields': jsonEncode(<String>['name']),
          'order_by': 'name asc',
          'limit_start': offset,
          'limit_page_length': pageSize,
        },
      );

      final FrappeListResponseDto response = FrappeListResponseDto.fromJson(
        json,
      );
      final List<String> batch = response.data
          .map(
            (Map<String, dynamic> row) => (row['name'] as String? ?? '').trim(),
          )
          .where((String name) => name.isNotEmpty)
          .toList(growable: false);
      values.addAll(batch);

      if (batch.length < pageSize) {
        break;
      }
      offset += pageSize;
    }

    final List<String> sorted = values.toList(growable: false);
    sorted.sort(
      (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    return sorted;
  }

  Map<String, dynamic> _buildListQueryParams(
    ItemQuery query,
    List<String> fields,
  ) {
    final Map<String, dynamic> params = <String, dynamic>{
      'fields': jsonEncode(fields),
      'limit_start': query.offset,
      'limit_page_length': query.limit,
      'order_by': query.orderBy,
    };

    final List<List<dynamic>> filters = <List<dynamic>>[];
    if (query.itemGroup != null && query.itemGroup!.isNotEmpty) {
      filters.add(<dynamic>['Item', 'item_group', '=', query.itemGroup]);
    }

    if (query.disabled != null) {
      filters.add(<dynamic>['Item', 'disabled', '=', query.disabled! ? 1 : 0]);
    }

    if (filters.isNotEmpty) {
      params['filters'] = jsonEncode(filters);
    }

    final String? search = query.search?.trim();
    if (search != null && search.isNotEmpty) {
      params['or_filters'] = jsonEncode(<List<dynamic>>[
        <dynamic>['Item', 'item_name', 'like', '%$search%'],
        <dynamic>['Item', 'item_code', 'like', '%$search%'],
      ]);
    }
    return params;
  }

  String? _extractBlockedField(DioException error) {
    final String combined = <String>[
      error.message ?? '',
      _asText(error.response?.data),
    ].join(' ');
    final RegExpMatch? match = RegExp(
      r'Field not permitted in query:\s*([a-zA-Z0-9_]+)',
      caseSensitive: false,
    ).firstMatch(combined);
    return match?.group(1);
  }

  String _asText(dynamic raw) {
    if (raw == null) {
      return '';
    }
    if (raw is String) {
      return raw;
    }
    if (raw is Map<String, dynamic>) {
      return raw.values.map((dynamic value) => value.toString()).join(' ');
    }
    if (raw is Map) {
      return raw.values.map((dynamic value) => value.toString()).join(' ');
    }
    return raw.toString();
  }

  Future<Map<String, double>> _fetchItemPriceMap(List<ItemDto> items) async {
    final Set<String> codes = items
        .map((ItemDto item) {
          final String code = (item.itemCode ?? '').trim();
          return code.isEmpty ? item.id.trim() : code;
        })
        .where((String value) => value.isNotEmpty)
        .toSet();
    if (codes.isEmpty) {
      return const <String, double>{};
    }

    final List<String> fields = <String>[
      'item_code',
      'price_list_rate',
      'selling',
      'modified',
    ];
    bool includeSellingFilter = true;

    while (true) {
      try {
        final List<List<dynamic>> filters = <List<dynamic>>[
          <dynamic>[
            'Item Price',
            'item_code',
            'in',
            codes.toList(growable: false),
          ],
        ];
        if (includeSellingFilter) {
          filters.add(<dynamic>['Item Price', 'selling', '=', 1]);
        }

        final Map<String, dynamic> json = await _apiClient.get(
          ApiConstants.itemPricePath,
          queryParameters: <String, dynamic>{
            'fields': jsonEncode(fields),
            'filters': jsonEncode(filters),
            'order_by': 'modified desc',
            'limit_page_length': 500,
          },
        );

        final List<dynamic> raw =
            (json['data'] as List<dynamic>?) ?? <dynamic>[];
        final Map<String, double> result = <String, double>{};
        for (final Map<String, dynamic> row
            in raw.whereType<Map<String, dynamic>>()) {
          final String code = (row['item_code'] as String? ?? '').trim();
          if (code.isEmpty || result.containsKey(code)) {
            continue;
          }
          final dynamic rateRaw = row['price_list_rate'];
          final double? rate = rateRaw is num
              ? rateRaw.toDouble()
              : double.tryParse((rateRaw ?? '').toString().trim());
          if (rate == null) {
            continue;
          }
          result[code] = rate;
        }
        return result;
      } on DioException catch (error) {
        final String? blockedField = _extractBlockedField(error);
        if (blockedField == null) {
          return const <String, double>{};
        }
        if (fields.remove(blockedField)) {
          continue;
        }
        if (blockedField.toLowerCase() == 'selling' && includeSellingFilter) {
          includeSellingFilter = false;
          continue;
        }
        return const <String, double>{};
      } catch (_) {
        return const <String, double>{};
      }
    }
  }

  List<ItemDto> _mergeItemPrices(
    List<ItemDto> items,
    Map<String, double> priceByCode,
  ) {
    if (priceByCode.isEmpty) {
      return items;
    }
    return items
        .map((ItemDto item) {
          final String itemCode = (item.itemCode ?? '').trim();
          final String code = itemCode.isEmpty ? item.id.trim() : itemCode;
          final double? overrideRate = code.isEmpty ? null : priceByCode[code];
          if (overrideRate == null) {
            return item;
          }
          return ItemDto(
            id: item.id,
            itemCode: item.itemCode,
            itemName: item.itemName,
            itemGroup: item.itemGroup,
            stockUom: item.stockUom,
            image: item.image,
            description: item.description,
            openingStock: item.openingStock,
            disabled: item.disabled,
            hasVariants: item.hasVariants,
            maintainStock: item.maintainStock,
            isFixedAsset: item.isFixedAsset,
            valuationRate: item.valuationRate,
            standardRate: overrideRate,
            modified: item.modified,
          );
        })
        .toList(growable: false);
  }

  int _compareNullableDouble(num? a, num? b, {required bool ascending}) {
    final double left = a?.toDouble() ?? double.negativeInfinity;
    final double right = b?.toDouble() ?? double.negativeInfinity;
    final int base = left.compareTo(right);
    return ascending ? base : -base;
  }
}
