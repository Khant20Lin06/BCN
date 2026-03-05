import '../../domain/entities/item_price_entity.dart';

enum ItemPricesStatus { idle, loading, success, empty, error }

class ItemPricesState {
  const ItemPricesState({
    required this.status,
    required this.itemPrices,
    required this.searchQuery,
    this.errorMessage,
  });

  const ItemPricesState.initial()
    : this(
        status: ItemPricesStatus.idle,
        itemPrices: const <ItemPriceEntity>[],
        searchQuery: '',
      );

  final ItemPricesStatus status;
  final List<ItemPriceEntity> itemPrices;
  final String searchQuery;
  final String? errorMessage;

  ItemPricesState copyWith({
    ItemPricesStatus? status,
    List<ItemPriceEntity>? itemPrices,
    String? searchQuery,
    String? errorMessage,
  }) {
    return ItemPricesState(
      status: status ?? this.status,
      itemPrices: itemPrices ?? this.itemPrices,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}
