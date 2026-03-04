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
import '../../domain/entities/sales_invoice_entity.dart';
import '../state/sales_invoices_state.dart';

final salesInvoicesApiClientProvider = Provider<FrappeApiClient>((Ref ref) {
  return FrappeApiClient(
    storageService: ref.watch(secureStorageServiceProvider),
    dioFactory: DioFactory(ref.watch(appLoggerProvider)),
  );
});

final salesInvoicesControllerProvider =
    StateNotifierProvider<SalesInvoicesController, SalesInvoicesState>((
      Ref ref,
    ) {
      return SalesInvoicesController(ref.watch(salesInvoicesApiClientProvider));
    });

final salesInvoiceDetailProvider =
    FutureProvider.family<SalesInvoiceEntity, String>((Ref ref, String id) {
      return ref
          .watch(salesInvoicesControllerProvider.notifier)
          .getSalesInvoiceDetail(id);
    });

class SalesInvoicesController extends StateNotifier<SalesInvoicesState> {
  SalesInvoicesController(this._apiClient)
    : super(const SalesInvoicesState.initial());

  static const List<String> _defaultStatusOptions = <String>[
    'Draft',
    'Submitted',
    'Paid',
    'Unpaid',
    'Overdue',
    'Cancelled',
  ];

  final FrappeApiClient _apiClient;
  Timer? _searchDebounce;

  Future<void> loadSalesInvoices() async {
    state = state.copyWith(
      status: SalesInvoicesStatus.loading,
      errorMessage: null,
    );

    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'fields': jsonEncode(ApiConstants.salesInvoiceFields),
        'order_by': 'modified desc',
        'limit_page_length': 100,
      };

      final String search = state.searchQuery.trim();
      if (search.isNotEmpty) {
        params['or_filters'] = jsonEncode(<List<dynamic>>[
          <dynamic>['name', 'like', '%$search%'],
          <dynamic>['customer', 'like', '%$search%'],
          <dynamic>['status', 'like', '%$search%'],
        ]);
      }

      final Map<String, dynamic> json = await _apiClient.get(
        ApiConstants.salesInvoicePath,
        queryParameters: params,
      );

      final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<SalesInvoiceEntity> salesInvoices = raw
          .whereType<Map<String, dynamic>>()
          .map(_mapSalesInvoice)
          .toList(growable: false);

      state = state.copyWith(
        status: salesInvoices.isEmpty
            ? SalesInvoicesStatus.empty
            : SalesInvoicesStatus.success,
        salesInvoices: salesInvoices,
      );
    } catch (error) {
      state = state.copyWith(
        status: SalesInvoicesStatus.error,
        errorMessage: _toFailure(error).message,
      );
    }
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final String normalized = value.trim();
      state = state.copyWith(searchQuery: normalized);
      unawaited(loadSalesInvoices());
    });
  }

  Future<SalesInvoiceEntity> getSalesInvoiceDetail(String id) async {
    final Map<String, dynamic> json = await _apiClient.get(
      '${ApiConstants.salesInvoicePath}/${Uri.encodeComponent(id)}',
      queryParameters: <String, dynamic>{
        'fields': jsonEncode(<String>[
          ...ApiConstants.salesInvoiceFields,
          'items',
        ]),
      },
    );
    final Map<String, dynamic> data =
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return _mapSalesInvoice(data);
  }

  Future<List<String>> fetchCustomerOptions() async {
    return _fetchAllFieldOptions(
      endpoint: ApiConstants.customerPath,
      fieldName: 'name',
      orderBy: 'name asc',
    );
  }

  Future<List<SalesInvoiceItemOption>> fetchItemOptions() async {
    try {
      return _fetchAllItemOptions(
        fields: <String>['name', 'item_code', 'item_name'],
        orderBy: 'item_name asc',
      );
    } catch (_) {
      // Fallback for sites where item_name/item_code field access is restricted.
      final List<String> names = await _fetchAllFieldOptions(
        endpoint: ApiConstants.itemPath,
        fieldName: 'name',
        orderBy: 'name asc',
      );
      return names
          .map(
            (String name) => SalesInvoiceItemOption(value: name, label: name),
          )
          .toList(growable: false);
    }
  }

  Future<List<String>> fetchStatusOptions() async {
    final Set<String> values = <String>{..._defaultStatusOptions};
    try {
      final List<String> dynamicStatuses = await _fetchAllFieldOptions(
        endpoint: ApiConstants.salesInvoicePath,
        fieldName: 'status',
        orderBy: 'status asc',
      );
      values.addAll(dynamicStatuses);
    } catch (_) {
      // Keep default list when dynamic status fetch fails.
    }

    final List<String> result = values.toList(growable: false);
    result.sort(
      (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    return result;
  }

  Future<Failure?> createSalesInvoice({
    String? salesInvoiceId,
    required String customer,
    required String postingDate,
    required List<SalesInvoiceLineInput> lines,
  }) async {
    try {
      final String id = (salesInvoiceId ?? '').trim();
      final List<Map<String, dynamic>> linePayload = lines
          .map((SalesInvoiceLineInput line) => line.toPayload())
          .toList(growable: false);

      final Map<String, dynamic> payload = <String, dynamic>{
        if (id.isNotEmpty) 'name': id,
        'customer': customer.trim(),
        'posting_date': postingDate.trim(),
        'due_date': postingDate.trim(),
        'items': linePayload,
      };

      await _apiClient.post(ApiConstants.salesInvoicePath, data: payload);
      await loadSalesInvoices();
      return null;
    } catch (error) {
      return _toFailure(error);
    }
  }

  Future<Failure?> updateSalesInvoice({
    required String id,
    required String customer,
    required String postingDate,
    required List<SalesInvoiceLineInput> lines,
  }) async {
    try {
      final List<Map<String, dynamic>> linePayload = lines
          .map((SalesInvoiceLineInput line) => line.toPayload())
          .toList(growable: false);

      final Map<String, dynamic> payload = <String, dynamic>{
        'customer': customer.trim(),
        'posting_date': postingDate.trim(),
        'due_date': postingDate.trim(),
        'items': linePayload,
      };

      await _apiClient.put(
        '${ApiConstants.salesInvoicePath}/${Uri.encodeComponent(id)}',
        data: payload,
      );
      await loadSalesInvoices();
      return null;
    } catch (error) {
      return _toFailure(error);
    }
  }

  Future<Failure?> deleteSalesInvoice(String id) async {
    try {
      await _apiClient.delete(
        '${ApiConstants.salesInvoicePath}/${Uri.encodeComponent(id)}',
      );
      await loadSalesInvoices();
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

  Future<List<String>> _fetchAllFieldOptions({
    required String endpoint,
    required String fieldName,
    required String orderBy,
  }) async {
    const int pageSize = 200;
    int offset = 0;
    final Set<String> values = <String>{};

    while (true) {
      final Map<String, dynamic> json = await _apiClient.get(
        endpoint,
        queryParameters: <String, dynamic>{
          'fields': jsonEncode(<String>[fieldName]),
          'order_by': orderBy,
          'limit_start': offset,
          'limit_page_length': pageSize,
        },
      );

      final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<String> batch = raw
          .whereType<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> row) =>
                (row[fieldName] as String? ?? '').trim(),
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

  Future<List<SalesInvoiceItemOption>> _fetchAllItemOptions({
    required List<String> fields,
    required String orderBy,
  }) async {
    const int pageSize = 200;
    int offset = 0;
    final Map<String, SalesInvoiceItemOption> byValue =
        <String, SalesInvoiceItemOption>{};

    while (true) {
      final Map<String, dynamic> json = await _apiClient.get(
        ApiConstants.itemPath,
        queryParameters: <String, dynamic>{
          'fields': jsonEncode(fields),
          'order_by': orderBy,
          'limit_start': offset,
          'limit_page_length': pageSize,
        },
      );

      final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<Map<String, dynamic>> rows = raw
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      for (final Map<String, dynamic> row in rows) {
        final String value = (row['name'] as String? ?? '').trim();
        if (value.isEmpty) {
          continue;
        }

        final String itemCode = (row['item_code'] as String? ?? '').trim();
        final String itemName = (row['item_name'] as String? ?? '').trim();
        final String lead = itemCode.isNotEmpty ? itemCode : value;
        final String label = itemName.isNotEmpty && itemName != lead
            ? '$lead - $itemName'
            : lead;

        byValue[value] = SalesInvoiceItemOption(value: value, label: label);
      }

      if (rows.length < pageSize) {
        break;
      }
      offset += pageSize;
    }

    final List<SalesInvoiceItemOption> result = byValue.values.toList(
      growable: false,
    );
    result.sort(
      (SalesInvoiceItemOption a, SalesInvoiceItemOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return result;
  }
}

class SalesInvoiceItemOption {
  const SalesInvoiceItemOption({required this.value, required this.label});

  final String value;
  final String label;
}

class SalesInvoiceLineInput {
  const SalesInvoiceLineInput({
    required this.itemCode,
    required this.qty,
    this.rate,
  });

  final String itemCode;
  final double qty;
  final double? rate;

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'item_code': itemCode.trim(),
      'qty': qty,
      if (rate case final double lineRate) 'rate': lineRate,
    };
  }
}

SalesInvoiceEntity _mapSalesInvoice(Map<String, dynamic> data) {
  final List<dynamic> rawItems =
      (data['items'] as List<dynamic>?) ?? <dynamic>[];
  final List<SalesInvoiceLineEntity> items = rawItems
      .whereType<Map<String, dynamic>>()
      .map(
        (Map<String, dynamic> row) => SalesInvoiceLineEntity(
          itemCode: (row['item_code'] as String? ?? '').trim(),
          qty: _toDouble(row['qty']) ?? 1,
          rate: _toDouble(row['rate']),
        ),
      )
      .where((SalesInvoiceLineEntity line) => line.itemCode.isNotEmpty)
      .toList(growable: false);

  return SalesInvoiceEntity(
    id: (data['name'] as String?) ?? '',
    customer: (data['customer'] as String?) ?? '',
    postingDate: _toDate(data['posting_date']),
    grandTotal: _toDouble(data['grand_total']) ?? 0,
    status: (data['status'] as String?) ?? '',
    items: items,
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

double? _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}
