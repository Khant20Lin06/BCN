import '../../domain/entities/item_entity.dart';
import '../../domain/value_objects/item_query.dart';

enum ItemsStatus { idle, loading, success, empty, error, paginating }

enum ItemListViewMode { list, cart }

class ItemsState {
  const ItemsState({
    required this.status,
    required this.items,
    required this.query,
    required this.hasMore,
    required this.itemGroups,
    required this.viewMode,
    this.selectedItemId,
    this.errorMessage,
  });

  const ItemsState.initial()
    : this(
        status: ItemsStatus.idle,
        items: const <ItemEntity>[],
        query: const ItemQuery(),
        hasMore: true,
        itemGroups: const <String>[],
        viewMode: ItemListViewMode.list,
      );

  final ItemsStatus status;
  final List<ItemEntity> items;
  final ItemQuery query;
  final bool hasMore;
  final List<String> itemGroups;
  final ItemListViewMode viewMode;
  final String? selectedItemId;
  final String? errorMessage;

  ItemsState copyWith({
    ItemsStatus? status,
    List<ItemEntity>? items,
    ItemQuery? query,
    bool? hasMore,
    List<String>? itemGroups,
    ItemListViewMode? viewMode,
    String? selectedItemId,
    bool clearSelectedItem = false,
    String? errorMessage,
  }) {
    return ItemsState(
      status: status ?? this.status,
      items: items ?? this.items,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      itemGroups: itemGroups ?? this.itemGroups,
      viewMode: viewMode ?? this.viewMode,
      selectedItemId: clearSelectedItem
          ? null
          : (selectedItemId ?? this.selectedItemId),
      errorMessage: errorMessage,
    );
  }
}
