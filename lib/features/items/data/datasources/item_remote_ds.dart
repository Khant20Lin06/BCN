import 'dart:convert';

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
    final Map<String, dynamic> params = <String, dynamic>{
      'fields': jsonEncode(ApiConstants.itemFields),
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

    final Map<String, dynamic> json = await _apiClient.get(
      ApiConstants.itemPath,
      queryParameters: params,
    );

    final FrappeListResponseDto response = FrappeListResponseDto.fromJson(json);
    return response.data.map(ItemDto.fromJson).toList(growable: false);
  }

  Future<ItemDto> fetchItemDetail(String id) async {
    final Map<String, dynamic> json = await _apiClient.get(
      '${ApiConstants.itemPath}/$id',
      queryParameters: <String, dynamic>{
        'fields': jsonEncode(ApiConstants.itemFields),
      },
    );

    final Map<String, dynamic> data =
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return ItemDto.fromJson(data);
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
}
