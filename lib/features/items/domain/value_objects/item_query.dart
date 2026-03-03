class ItemQuery {
  const ItemQuery({
    this.search,
    this.itemGroup,
    this.disabled,
    this.offset = 0,
    this.limit = 20,
    this.orderBy = 'modified desc',
  });

  final String? search;
  final String? itemGroup;
  final bool? disabled;
  final int offset;
  final int limit;
  final String orderBy;

  ItemQuery copyWith({
    String? search,
    String? itemGroup,
    bool? disabled,
    int? offset,
    int? limit,
    String? orderBy,
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
      orderBy: orderBy ?? this.orderBy,
    );
  }
}
