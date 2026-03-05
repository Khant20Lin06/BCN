import '../../domain/entities/stock_balance_entity.dart';

enum StockBalancesStatus { idle, loading, success, empty, error }

class StockBalancesState {
  const StockBalancesState({
    required this.status,
    required this.stockBalances,
    required this.searchQuery,
    this.errorMessage,
  });

  const StockBalancesState.initial()
    : this(
        status: StockBalancesStatus.idle,
        stockBalances: const <StockBalanceEntity>[],
        searchQuery: '',
      );

  final StockBalancesStatus status;
  final List<StockBalanceEntity> stockBalances;
  final String searchQuery;
  final String? errorMessage;

  StockBalancesState copyWith({
    StockBalancesStatus? status,
    List<StockBalanceEntity>? stockBalances,
    String? searchQuery,
    String? errorMessage,
  }) {
    return StockBalancesState(
      status: status ?? this.status,
      stockBalances: stockBalances ?? this.stockBalances,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}
