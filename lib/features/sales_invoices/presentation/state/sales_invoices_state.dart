import '../../domain/entities/sales_invoice_entity.dart';

enum SalesInvoicesStatus { idle, loading, success, empty, error }

class SalesInvoicesState {
  const SalesInvoicesState({
    required this.status,
    required this.salesInvoices,
    required this.searchQuery,
    this.errorMessage,
  });

  const SalesInvoicesState.initial()
    : this(
        status: SalesInvoicesStatus.idle,
        salesInvoices: const <SalesInvoiceEntity>[],
        searchQuery: '',
      );

  final SalesInvoicesStatus status;
  final List<SalesInvoiceEntity> salesInvoices;
  final String searchQuery;
  final String? errorMessage;

  SalesInvoicesState copyWith({
    SalesInvoicesStatus? status,
    List<SalesInvoiceEntity>? salesInvoices,
    String? searchQuery,
    String? errorMessage,
  }) {
    return SalesInvoicesState(
      status: status ?? this.status,
      salesInvoices: salesInvoices ?? this.salesInvoices,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}
