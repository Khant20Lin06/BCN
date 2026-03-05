enum ItemSortField { modified, itemCode, itemName, price, qty }

class ItemQuery {
  const ItemQuery({
    this.search,
    this.itemGroup,
    this.disabled,
    this.offset = 0,
    this.limit = 20,
    this.sortField = ItemSortField.modified,
    this.sortAscending = false,
  });

  final String? search;
  final String? itemGroup;
  final bool? disabled;
  final int offset;
  final int limit;
  final ItemSortField sortField;
  final bool sortAscending;

  String get orderBy {
    final String direction = sortAscending ? 'asc' : 'desc';
    switch (sortField) {
      case ItemSortField.itemCode:
        return 'item_code $direction';
      case ItemSortField.itemName:
        return 'item_name $direction';
      case ItemSortField.price:
        return 'item_name asc';
      case ItemSortField.qty:
        return 'item_name asc';
      case ItemSortField.modified:
        return 'modified $direction';
    }
  }

  ItemQuery copyWith({
    String? search,
    String? itemGroup,
    bool? disabled,
    int? offset,
    int? limit,
    ItemSortField? sortField,
    bool? sortAscending,
    bool clearSearch = false,
    bool clearItemGroup = false,
    bool clearDisabled = false,
  }) {
    return ItemQuery(
      search: clearSearch ? null : (search ?? this.search),
      itemGroup: clearItemGroup ? null : (itemGroup ?? this.itemGroup),
      disabled: clearDisabled ? null : (disabled ?? this.disabled),
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}
