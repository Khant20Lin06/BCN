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

  List<StockBalanceEntity> get filteredStockBalances {
    final String normalizedSearch = searchQuery.trim().toLowerCase();

    if (normalizedSearch.isEmpty) {
      return stockBalances;
    }

    return stockBalances.where((StockBalanceEntity item) {
      return item.itemCode.trim().toLowerCase().contains(normalizedSearch) ||
          item.itemName.trim().toLowerCase().contains(normalizedSearch) ||
          item.warehouse.trim().toLowerCase().contains(normalizedSearch);
    }).toList(growable: false);
  }

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
