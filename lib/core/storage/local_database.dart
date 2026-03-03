import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'local_database.g.dart';

class CachedItems extends Table {
  TextColumn get id => text()();

  TextColumn get itemCode => text().nullable()();

  TextColumn get itemName => text()();

  TextColumn get itemGroup => text()();

  TextColumn get stockUom => text()();

  TextColumn get description => text().nullable()();

  BoolColumn get disabled => boolean().withDefault(const Constant(false))();

  BoolColumn get hasVariants => boolean().withDefault(const Constant(false))();

  RealColumn get valuationRate => real().nullable()();

  DateTimeColumn get modified => dateTime().nullable()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(tables: <Type>[CachedItems])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'frappe_mobile_item_app_db'));

  @override
  int get schemaVersion => 1;

  Future<void> upsertItems(List<CachedItemsCompanion> items) async {
    await batch((Batch batch) {
      batch.insertAllOnConflictUpdate(cachedItems, items);
    });
  }

  Future<void> upsertItem(CachedItemsCompanion item) async {
    await into(cachedItems).insertOnConflictUpdate(item);
  }

  Future<CachedItem?> getItemById(String id) {
    return (select(
      cachedItems,
    )..where((CachedItems tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> deleteById(String id) async {
    await (delete(
      cachedItems,
    )..where((CachedItems tbl) => tbl.id.equals(id))).go();
  }

  Future<void> clearItems() async {
    await delete(cachedItems).go();
  }

  Future<List<CachedItem>> getItems({
    required int limit,
    required int offset,
    String? search,
    String? itemGroup,
    bool? disabled,
  }) async {
    final SimpleSelectStatement<$CachedItemsTable, CachedItem> query =
        select(cachedItems)
          ..orderBy(<OrderingTerm Function($CachedItemsTable)>[
            (CachedItems tbl) => OrderingTerm.desc(tbl.modified),
          ])
          ..limit(limit, offset: offset);

    if (itemGroup != null && itemGroup.trim().isNotEmpty) {
      query.where((CachedItems tbl) => tbl.itemGroup.equals(itemGroup));
    }

    if (disabled != null) {
      query.where((CachedItems tbl) => tbl.disabled.equals(disabled));
    }

    if (search != null && search.trim().isNotEmpty) {
      final String pattern = '%$search%';
      query.where(
        (CachedItems tbl) =>
            tbl.itemName.like(pattern) | tbl.itemCode.like(pattern),
      );
    }

    return query.get();
  }
}

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final LocalDatabase db = LocalDatabase();
  ref.onDispose(db.close);
  return db;
});
