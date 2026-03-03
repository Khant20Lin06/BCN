class Paginated<T> {
  const Paginated({
    required this.items,
    required this.hasMore,
    required this.nextOffset,
  });

  final List<T> items;
  final bool hasMore;
  final int nextOffset;
}
