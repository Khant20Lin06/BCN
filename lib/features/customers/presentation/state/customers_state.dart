import '../../domain/entities/customer_entity.dart';

enum CustomersStatus { idle, loading, success, empty, error }

class CustomersState {
  const CustomersState({
    required this.status,
    required this.customers,
    required this.searchQuery,
    this.errorMessage,
  });

  const CustomersState.initial()
    : this(
        status: CustomersStatus.idle,
        customers: const <CustomerEntity>[],
        searchQuery: '',
      );

  final CustomersStatus status;
  final List<CustomerEntity> customers;
  final String searchQuery;
  final String? errorMessage;

  CustomersState copyWith({
    CustomersStatus? status,
    List<CustomerEntity>? customers,
    String? searchQuery,
    String? errorMessage,
  }) {
    return CustomersState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}
