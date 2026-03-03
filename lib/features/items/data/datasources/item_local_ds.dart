import 'package:drift/drift.dart';

import '../../../../core/storage/local_database.dart';
import '../../domain/value_objects/item_query.dart';
import '../dtos/item_dto.dart';
import '../mappers/item_mapper.dart';

class ItemLocalDataSource {
  const ItemLocalDataSource({
    required LocalDatabase database,
    required ItemMapper mapper,
  }) : _database = database,
       _mapper = mapper;

  final LocalDatabase _database;
  final ItemMapper _mapper;

  Future<void> cacheItems(List<ItemDto> items) async {
    final companions = items.map(_mapper.toCompanion).toList(growable: false);
    await _database.upsertItems(companions);
  }

  Future<void> cacheItem(ItemDto item) {
    return _database.upsertItem(_mapper.toCompanion(item));
  }

  Future<List<ItemDto>> getItems(ItemQuery query) async {
    final rows = await _database.getItems(
      limit: query.limit,
      offset: query.offset,
      search: query.search,
      itemGroup: query.itemGroup,
      disabled: query.disabled,
    );
    return rows.map(_mapper.fromCachedItem).toList(growable: false);
  }

  Future<ItemDto?> getItemById(String id) async {
    final row = await _database.getItemById(id);
    if (row == null) {
      return null;
    }
    return _mapper.fromCachedItem(row);
  }

  Future<void> removeItem(String id) => _database.deleteById(id);

  Future<void> setItemDisabled(String id, bool disabled) async {
    final current = await _database.getItemById(id);
    if (current == null) {
      return;
    }
    await _database.upsertItem(
      CachedItemsCompanion(
        id: Value<String>(current.id),
        itemCode: Value<String?>(current.itemCode),
        itemName: Value<String>(current.itemName),
        itemGroup: Value<String>(current.itemGroup),
        stockUom: Value<String>(current.stockUom),
        description: Value<String?>(current.description),
        disabled: Value<bool>(disabled),
        hasVariants: Value<bool>(current.hasVariants),
        valuationRate: Value<double?>(current.valuationRate),
        modified: Value<DateTime?>(current.modified),
        updatedAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }
}
