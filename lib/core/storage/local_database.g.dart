// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $CachedItemsTable extends CachedItems
    with TableInfo<$CachedItemsTable, CachedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemCodeMeta = const VerificationMeta(
    'itemCode',
  );
  @override
  late final GeneratedColumn<String> itemCode = GeneratedColumn<String>(
    'item_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemGroupMeta = const VerificationMeta(
    'itemGroup',
  );
  @override
  late final GeneratedColumn<String> itemGroup = GeneratedColumn<String>(
    'item_group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockUomMeta = const VerificationMeta(
    'stockUom',
  );
  @override
  late final GeneratedColumn<String> stockUom = GeneratedColumn<String>(
    'stock_uom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _disabledMeta = const VerificationMeta(
    'disabled',
  );
  @override
  late final GeneratedColumn<bool> disabled = GeneratedColumn<bool>(
    'disabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("disabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasVariantsMeta = const VerificationMeta(
    'hasVariants',
  );
  @override
  late final GeneratedColumn<bool> hasVariants = GeneratedColumn<bool>(
    'has_variants',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_variants" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _valuationRateMeta = const VerificationMeta(
    'valuationRate',
  );
  @override
  late final GeneratedColumn<double> valuationRate = GeneratedColumn<double>(
    'valuation_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<DateTime> modified = GeneratedColumn<DateTime>(
    'modified',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemCode,
    itemName,
    itemGroup,
    stockUom,
    description,
    disabled,
    hasVariants,
    valuationRate,
    modified,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_code')) {
      context.handle(
        _itemCodeMeta,
        itemCode.isAcceptableOrUnknown(data['item_code']!, _itemCodeMeta),
      );
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('item_group')) {
      context.handle(
        _itemGroupMeta,
        itemGroup.isAcceptableOrUnknown(data['item_group']!, _itemGroupMeta),
      );
    } else if (isInserting) {
      context.missing(_itemGroupMeta);
    }
    if (data.containsKey('stock_uom')) {
      context.handle(
        _stockUomMeta,
        stockUom.isAcceptableOrUnknown(data['stock_uom']!, _stockUomMeta),
      );
    } else if (isInserting) {
      context.missing(_stockUomMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('disabled')) {
      context.handle(
        _disabledMeta,
        disabled.isAcceptableOrUnknown(data['disabled']!, _disabledMeta),
      );
    }
    if (data.containsKey('has_variants')) {
      context.handle(
        _hasVariantsMeta,
        hasVariants.isAcceptableOrUnknown(
          data['has_variants']!,
          _hasVariantsMeta,
        ),
      );
    }
    if (data.containsKey('valuation_rate')) {
      context.handle(
        _valuationRateMeta,
        valuationRate.isAcceptableOrUnknown(
          data['valuation_rate']!,
          _valuationRateMeta,
        ),
      );
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_code'],
      ),
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      itemGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_group'],
      )!,
      stockUom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock_uom'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      disabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}disabled'],
      )!,
      hasVariants: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_variants'],
      )!,
      valuationRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}valuation_rate'],
      ),
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedItemsTable createAlias(String alias) {
    return $CachedItemsTable(attachedDatabase, alias);
  }
}

class CachedItem extends DataClass implements Insertable<CachedItem> {
  final String id;
  final String? itemCode;
  final String itemName;
  final String itemGroup;
  final String stockUom;
  final String? description;
  final bool disabled;
  final bool hasVariants;
  final double? valuationRate;
  final DateTime? modified;
  final DateTime updatedAt;
  const CachedItem({
    required this.id,
    this.itemCode,
    required this.itemName,
    required this.itemGroup,
    required this.stockUom,
    this.description,
    required this.disabled,
    required this.hasVariants,
    this.valuationRate,
    this.modified,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || itemCode != null) {
      map['item_code'] = Variable<String>(itemCode);
    }
    map['item_name'] = Variable<String>(itemName);
    map['item_group'] = Variable<String>(itemGroup);
    map['stock_uom'] = Variable<String>(stockUom);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['disabled'] = Variable<bool>(disabled);
    map['has_variants'] = Variable<bool>(hasVariants);
    if (!nullToAbsent || valuationRate != null) {
      map['valuation_rate'] = Variable<double>(valuationRate);
    }
    if (!nullToAbsent || modified != null) {
      map['modified'] = Variable<DateTime>(modified);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedItemsCompanion(
      id: Value(id),
      itemCode: itemCode == null && nullToAbsent
          ? const Value.absent()
          : Value(itemCode),
      itemName: Value(itemName),
      itemGroup: Value(itemGroup),
      stockUom: Value(stockUom),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      disabled: Value(disabled),
      hasVariants: Value(hasVariants),
      valuationRate: valuationRate == null && nullToAbsent
          ? const Value.absent()
          : Value(valuationRate),
      modified: modified == null && nullToAbsent
          ? const Value.absent()
          : Value(modified),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedItem(
      id: serializer.fromJson<String>(json['id']),
      itemCode: serializer.fromJson<String?>(json['itemCode']),
      itemName: serializer.fromJson<String>(json['itemName']),
      itemGroup: serializer.fromJson<String>(json['itemGroup']),
      stockUom: serializer.fromJson<String>(json['stockUom']),
      description: serializer.fromJson<String?>(json['description']),
      disabled: serializer.fromJson<bool>(json['disabled']),
      hasVariants: serializer.fromJson<bool>(json['hasVariants']),
      valuationRate: serializer.fromJson<double?>(json['valuationRate']),
      modified: serializer.fromJson<DateTime?>(json['modified']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemCode': serializer.toJson<String?>(itemCode),
      'itemName': serializer.toJson<String>(itemName),
      'itemGroup': serializer.toJson<String>(itemGroup),
      'stockUom': serializer.toJson<String>(stockUom),
      'description': serializer.toJson<String?>(description),
      'disabled': serializer.toJson<bool>(disabled),
      'hasVariants': serializer.toJson<bool>(hasVariants),
      'valuationRate': serializer.toJson<double?>(valuationRate),
      'modified': serializer.toJson<DateTime?>(modified),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedItem copyWith({
    String? id,
    Value<String?> itemCode = const Value.absent(),
    String? itemName,
    String? itemGroup,
    String? stockUom,
    Value<String?> description = const Value.absent(),
    bool? disabled,
    bool? hasVariants,
    Value<double?> valuationRate = const Value.absent(),
    Value<DateTime?> modified = const Value.absent(),
    DateTime? updatedAt,
  }) => CachedItem(
    id: id ?? this.id,
    itemCode: itemCode.present ? itemCode.value : this.itemCode,
    itemName: itemName ?? this.itemName,
    itemGroup: itemGroup ?? this.itemGroup,
    stockUom: stockUom ?? this.stockUom,
    description: description.present ? description.value : this.description,
    disabled: disabled ?? this.disabled,
    hasVariants: hasVariants ?? this.hasVariants,
    valuationRate: valuationRate.present
        ? valuationRate.value
        : this.valuationRate,
    modified: modified.present ? modified.value : this.modified,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedItem copyWithCompanion(CachedItemsCompanion data) {
    return CachedItem(
      id: data.id.present ? data.id.value : this.id,
      itemCode: data.itemCode.present ? data.itemCode.value : this.itemCode,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      itemGroup: data.itemGroup.present ? data.itemGroup.value : this.itemGroup,
      stockUom: data.stockUom.present ? data.stockUom.value : this.stockUom,
      description: data.description.present
          ? data.description.value
          : this.description,
      disabled: data.disabled.present ? data.disabled.value : this.disabled,
      hasVariants: data.hasVariants.present
          ? data.hasVariants.value
          : this.hasVariants,
      valuationRate: data.valuationRate.present
          ? data.valuationRate.value
          : this.valuationRate,
      modified: data.modified.present ? data.modified.value : this.modified,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedItem(')
          ..write('id: $id, ')
          ..write('itemCode: $itemCode, ')
          ..write('itemName: $itemName, ')
          ..write('itemGroup: $itemGroup, ')
          ..write('stockUom: $stockUom, ')
          ..write('description: $description, ')
          ..write('disabled: $disabled, ')
          ..write('hasVariants: $hasVariants, ')
          ..write('valuationRate: $valuationRate, ')
          ..write('modified: $modified, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemCode,
    itemName,
    itemGroup,
    stockUom,
    description,
    disabled,
    hasVariants,
    valuationRate,
    modified,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedItem &&
          other.id == this.id &&
          other.itemCode == this.itemCode &&
          other.itemName == this.itemName &&
          other.itemGroup == this.itemGroup &&
          other.stockUom == this.stockUom &&
          other.description == this.description &&
          other.disabled == this.disabled &&
          other.hasVariants == this.hasVariants &&
          other.valuationRate == this.valuationRate &&
          other.modified == this.modified &&
          other.updatedAt == this.updatedAt);
}

class CachedItemsCompanion extends UpdateCompanion<CachedItem> {
  final Value<String> id;
  final Value<String?> itemCode;
  final Value<String> itemName;
  final Value<String> itemGroup;
  final Value<String> stockUom;
  final Value<String?> description;
  final Value<bool> disabled;
  final Value<bool> hasVariants;
  final Value<double?> valuationRate;
  final Value<DateTime?> modified;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedItemsCompanion({
    this.id = const Value.absent(),
    this.itemCode = const Value.absent(),
    this.itemName = const Value.absent(),
    this.itemGroup = const Value.absent(),
    this.stockUom = const Value.absent(),
    this.description = const Value.absent(),
    this.disabled = const Value.absent(),
    this.hasVariants = const Value.absent(),
    this.valuationRate = const Value.absent(),
    this.modified = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedItemsCompanion.insert({
    required String id,
    this.itemCode = const Value.absent(),
    required String itemName,
    required String itemGroup,
    required String stockUom,
    this.description = const Value.absent(),
    this.disabled = const Value.absent(),
    this.hasVariants = const Value.absent(),
    this.valuationRate = const Value.absent(),
    this.modified = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemName = Value(itemName),
       itemGroup = Value(itemGroup),
       stockUom = Value(stockUom);
  static Insertable<CachedItem> custom({
    Expression<String>? id,
    Expression<String>? itemCode,
    Expression<String>? itemName,
    Expression<String>? itemGroup,
    Expression<String>? stockUom,
    Expression<String>? description,
    Expression<bool>? disabled,
    Expression<bool>? hasVariants,
    Expression<double>? valuationRate,
    Expression<DateTime>? modified,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemCode != null) 'item_code': itemCode,
      if (itemName != null) 'item_name': itemName,
      if (itemGroup != null) 'item_group': itemGroup,
      if (stockUom != null) 'stock_uom': stockUom,
      if (description != null) 'description': description,
      if (disabled != null) 'disabled': disabled,
      if (hasVariants != null) 'has_variants': hasVariants,
      if (valuationRate != null) 'valuation_rate': valuationRate,
      if (modified != null) 'modified': modified,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedItemsCompanion copyWith({
    Value<String>? id,
    Value<String?>? itemCode,
    Value<String>? itemName,
    Value<String>? itemGroup,
    Value<String>? stockUom,
    Value<String?>? description,
    Value<bool>? disabled,
    Value<bool>? hasVariants,
    Value<double?>? valuationRate,
    Value<DateTime?>? modified,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedItemsCompanion(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      itemGroup: itemGroup ?? this.itemGroup,
      stockUom: stockUom ?? this.stockUom,
      description: description ?? this.description,
      disabled: disabled ?? this.disabled,
      hasVariants: hasVariants ?? this.hasVariants,
      valuationRate: valuationRate ?? this.valuationRate,
      modified: modified ?? this.modified,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemCode.present) {
      map['item_code'] = Variable<String>(itemCode.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (itemGroup.present) {
      map['item_group'] = Variable<String>(itemGroup.value);
    }
    if (stockUom.present) {
      map['stock_uom'] = Variable<String>(stockUom.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (disabled.present) {
      map['disabled'] = Variable<bool>(disabled.value);
    }
    if (hasVariants.present) {
      map['has_variants'] = Variable<bool>(hasVariants.value);
    }
    if (valuationRate.present) {
      map['valuation_rate'] = Variable<double>(valuationRate.value);
    }
    if (modified.present) {
      map['modified'] = Variable<DateTime>(modified.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedItemsCompanion(')
          ..write('id: $id, ')
          ..write('itemCode: $itemCode, ')
          ..write('itemName: $itemName, ')
          ..write('itemGroup: $itemGroup, ')
          ..write('stockUom: $stockUom, ')
          ..write('description: $description, ')
          ..write('disabled: $disabled, ')
          ..write('hasVariants: $hasVariants, ')
          ..write('valuationRate: $valuationRate, ')
          ..write('modified: $modified, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $CachedItemsTable cachedItems = $CachedItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cachedItems];
}

typedef $$CachedItemsTableCreateCompanionBuilder =
    CachedItemsCompanion Function({
      required String id,
      Value<String?> itemCode,
      required String itemName,
      required String itemGroup,
      required String stockUom,
      Value<String?> description,
      Value<bool> disabled,
      Value<bool> hasVariants,
      Value<double?> valuationRate,
      Value<DateTime?> modified,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CachedItemsTableUpdateCompanionBuilder =
    CachedItemsCompanion Function({
      Value<String> id,
      Value<String?> itemCode,
      Value<String> itemName,
      Value<String> itemGroup,
      Value<String> stockUom,
      Value<String?> description,
      Value<bool> disabled,
      Value<bool> hasVariants,
      Value<double?> valuationRate,
      Value<DateTime?> modified,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedItemsTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedItemsTable> {
  $$CachedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemCode => $composableBuilder(
    column: $table.itemCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemGroup => $composableBuilder(
    column: $table.itemGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stockUom => $composableBuilder(
    column: $table.stockUom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get disabled => $composableBuilder(
    column: $table.disabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasVariants => $composableBuilder(
    column: $table.hasVariants,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valuationRate => $composableBuilder(
    column: $table.valuationRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedItemsTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedItemsTable> {
  $$CachedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemCode => $composableBuilder(
    column: $table.itemCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemGroup => $composableBuilder(
    column: $table.itemGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockUom => $composableBuilder(
    column: $table.stockUom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get disabled => $composableBuilder(
    column: $table.disabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasVariants => $composableBuilder(
    column: $table.hasVariants,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valuationRate => $composableBuilder(
    column: $table.valuationRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedItemsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedItemsTable> {
  $$CachedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemCode =>
      $composableBuilder(column: $table.itemCode, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get itemGroup =>
      $composableBuilder(column: $table.itemGroup, builder: (column) => column);

  GeneratedColumn<String> get stockUom =>
      $composableBuilder(column: $table.stockUom, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get disabled =>
      $composableBuilder(column: $table.disabled, builder: (column) => column);

  GeneratedColumn<bool> get hasVariants => $composableBuilder(
    column: $table.hasVariants,
    builder: (column) => column,
  );

  GeneratedColumn<double> get valuationRate => $composableBuilder(
    column: $table.valuationRate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedItemsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedItemsTable,
          CachedItem,
          $$CachedItemsTableFilterComposer,
          $$CachedItemsTableOrderingComposer,
          $$CachedItemsTableAnnotationComposer,
          $$CachedItemsTableCreateCompanionBuilder,
          $$CachedItemsTableUpdateCompanionBuilder,
          (
            CachedItem,
            BaseReferences<_$LocalDatabase, $CachedItemsTable, CachedItem>,
          ),
          CachedItem,
          PrefetchHooks Function()
        > {
  $$CachedItemsTableTableManager(_$LocalDatabase db, $CachedItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> itemCode = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<String> itemGroup = const Value.absent(),
                Value<String> stockUom = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> disabled = const Value.absent(),
                Value<bool> hasVariants = const Value.absent(),
                Value<double?> valuationRate = const Value.absent(),
                Value<DateTime?> modified = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedItemsCompanion(
                id: id,
                itemCode: itemCode,
                itemName: itemName,
                itemGroup: itemGroup,
                stockUom: stockUom,
                description: description,
                disabled: disabled,
                hasVariants: hasVariants,
                valuationRate: valuationRate,
                modified: modified,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> itemCode = const Value.absent(),
                required String itemName,
                required String itemGroup,
                required String stockUom,
                Value<String?> description = const Value.absent(),
                Value<bool> disabled = const Value.absent(),
                Value<bool> hasVariants = const Value.absent(),
                Value<double?> valuationRate = const Value.absent(),
                Value<DateTime?> modified = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedItemsCompanion.insert(
                id: id,
                itemCode: itemCode,
                itemName: itemName,
                itemGroup: itemGroup,
                stockUom: stockUom,
                description: description,
                disabled: disabled,
                hasVariants: hasVariants,
                valuationRate: valuationRate,
                modified: modified,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedItemsTable,
      CachedItem,
      $$CachedItemsTableFilterComposer,
      $$CachedItemsTableOrderingComposer,
      $$CachedItemsTableAnnotationComposer,
      $$CachedItemsTableCreateCompanionBuilder,
      $$CachedItemsTableUpdateCompanionBuilder,
      (
        CachedItem,
        BaseReferences<_$LocalDatabase, $CachedItemsTable, CachedItem>,
      ),
      CachedItem,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$CachedItemsTableTableManager get cachedItems =>
      $$CachedItemsTableTableManager(_db, _db.cachedItems);
}
