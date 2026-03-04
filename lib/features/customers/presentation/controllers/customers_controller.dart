import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/frappe_api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../state/customers_state.dart';
import '../../domain/entities/customer_entity.dart';

final customersApiClientProvider = Provider<FrappeApiClient>((Ref ref) {
  return FrappeApiClient(
    storageService: ref.watch(secureStorageServiceProvider),
    dioFactory: DioFactory(ref.watch(appLoggerProvider)),
  );
});

final customersControllerProvider =
    StateNotifierProvider<CustomersController, CustomersState>((Ref ref) {
      return CustomersController(ref.watch(customersApiClientProvider));
    });

final customerDetailProvider = FutureProvider.family<CustomerEntity, String>((
  Ref ref,
  String id,
) async {
  return ref.watch(customersControllerProvider.notifier).getCustomerDetail(id);
});

class CustomersController extends StateNotifier<CustomersState> {
  CustomersController(this._apiClient) : super(const CustomersState.initial());

  final FrappeApiClient _apiClient;
  Timer? _searchDebounce;

  Future<void> loadCustomers() async {
    state = state.copyWith(status: CustomersStatus.loading, errorMessage: null);

    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'fields': jsonEncode(ApiConstants.customerFields),
        'order_by': 'modified desc',
        'limit_page_length': 100,
      };

      final String search = state.searchQuery.trim();
      if (search.isNotEmpty) {
        params['or_filters'] = jsonEncode(<List<dynamic>>[
          <dynamic>['name', 'like', '%$search%'],
          <dynamic>['customer_name', 'like', '%$search%'],
          <dynamic>['customer_group', 'like', '%$search%'],
          <dynamic>['territory', 'like', '%$search%'],
        ]);
      }

      final Map<String, dynamic> json = await _apiClient.get(
        ApiConstants.customerPath,
        queryParameters: params,
      );

      final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<CustomerEntity> customers = raw
          .whereType<Map<String, dynamic>>()
          .map(_mapCustomer)
          .toList(growable: false);

      state = state.copyWith(
        status: customers.isEmpty
            ? CustomersStatus.empty
            : CustomersStatus.success,
        customers: customers,
      );
    } catch (error) {
      state = state.copyWith(
        status: CustomersStatus.error,
        errorMessage: _toFailure(error).message,
      );
    }
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final String normalized = value.trim();
      state = state.copyWith(searchQuery: normalized);
      unawaited(loadCustomers());
    });
  }

  Future<CustomerEntity> getCustomerDetail(String id) async {
    final Map<String, dynamic> json = await _apiClient.get(
      '${ApiConstants.customerPath}/${Uri.encodeComponent(id)}',
      queryParameters: <String, dynamic>{
        'fields': jsonEncode(ApiConstants.customerFields),
      },
    );
    final Map<String, dynamic> data =
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return _mapCustomer(data);
  }

  Future<List<String>> fetchCustomerGroups() async {
    return _fetchAllNameOptions(ApiConstants.customerGroupPath);
  }

  Future<List<String>> fetchTerritories() async {
    return _fetchAllNameOptions(ApiConstants.territoryPath);
  }

  Future<Failure?> createCustomer({
    String? customerId,
    required String customerName,
    required String customerType,
    String? customerGroup,
    String? territory,
  }) async {
    try {
      final String id = (customerId ?? '').trim();
      final String normalizedGroup = (customerGroup ?? '').trim();
      final String normalizedTerritory = (territory ?? '').trim();
      final Map<String, dynamic> payload = <String, dynamic>{
        if (id.isNotEmpty) 'name': id,
        'customer_name': customerName.trim(),
        'customer_type': customerType.trim(),
        if (normalizedGroup.isNotEmpty) 'customer_group': normalizedGroup,
        if (normalizedTerritory.isNotEmpty) 'territory': normalizedTerritory,
      };
      await _apiClient.post(ApiConstants.customerPath, data: payload);
      await loadCustomers();
      return null;
    } catch (error) {
      return _toFailure(error);
    }
  }

  Future<Failure?> updateCustomer({
    required String id,
    required String customerName,
    required String customerType,
    String? customerGroup,
    String? territory,
  }) async {
    try {
      final String normalizedGroup = (customerGroup ?? '').trim();
      final String normalizedTerritory = (territory ?? '').trim();
      final Map<String, dynamic> payload = <String, dynamic>{
        'customer_name': customerName.trim(),
        'customer_type': customerType.trim(),
        if (normalizedGroup.isNotEmpty) 'customer_group': normalizedGroup,
        if (normalizedTerritory.isNotEmpty) 'territory': normalizedTerritory,
      };
      await _apiClient.put(
        '${ApiConstants.customerPath}/${Uri.encodeComponent(id)}',
        data: payload,
      );
      await loadCustomers();
      return null;
    } catch (error) {
      return _toFailure(error);
    }
  }

  Future<Failure?> deleteCustomer(String id) async {
    try {
      await _apiClient.delete(
        '${ApiConstants.customerPath}/${Uri.encodeComponent(id)}',
      );
      await loadCustomers();
      return null;
    } catch (error) {
      return _toFailure(error);
    }
  }

  Failure _toFailure(Object error) {
    if (error is Failure) {
      return error;
    }
    return mapExceptionToFailure(error);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
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

      final List<String> batch = _extractNameList(json);
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

List<String> _extractNameList(Map<String, dynamic> json) {
  final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
  final List<String> values = raw
      .whereType<Map<String, dynamic>>()
      .map((Map<String, dynamic> row) => (row['name'] as String? ?? '').trim())
      .where((String value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false);
  values.sort(
    (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
  );
  return values;
}

CustomerEntity _mapCustomer(Map<String, dynamic> data) {
  return CustomerEntity(
    id: (data['name'] as String?) ?? '',
    customerName: (data['customer_name'] as String?) ?? '',
    customerType: (data['customer_type'] as String?) ?? '',
    customerGroup: (data['customer_group'] as String?) ?? '',
    territory: (data['territory'] as String?) ?? '',
    creation: _toDate(data['creation']),
    modified: _toDate(data['modified']),
  );
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
