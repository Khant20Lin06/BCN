import 'package:drift/drift.dart';

import '../../../../core/storage/local_database.dart';
import '../../domain/entities/create_item_input.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/update_item_input.dart';
import '../dtos/item_dto.dart';

class ItemMapper {
  const ItemMapper();

  ItemEntity toEntity(ItemDto dto) {
    return ItemEntity(
      id: dto.id,
      itemCode: dto.itemCode,
      itemName: dto.itemName,
      itemGroup: dto.itemGroup,
      stockUom: dto.stockUom,
      image: dto.image,
      description: dto.description,
      stockQty: dto.openingStock?.toDouble(),
      disabled: _toBool(dto.disabled),
      hasVariants: _toBool(dto.hasVariants),
      maintainStock: _toBool(dto.maintainStock),
      isFixedAsset: _toBool(dto.isFixedAsset),
      valuationRate: dto.valuationRate?.toDouble(),
      standardRate: dto.standardRate?.toDouble(),
      modified: dto.modified,
    );
  }

  ItemDto fromCachedItem(CachedItem item) {
    return ItemDto(
      id: item.id,
      itemCode: item.itemCode,
      itemName: item.itemName,
      itemGroup: item.itemGroup,
      stockUom: item.stockUom,
      image: null,
      description: item.description,
      openingStock: null,
      disabled: item.disabled,
      hasVariants: item.hasVariants,
      maintainStock: false,
      isFixedAsset: false,
      valuationRate: item.valuationRate,
      standardRate: null,
      modified: item.modified,
    );
  }

  CachedItemsCompanion toCompanion(ItemDto dto) {
    return CachedItemsCompanion(
      id: Value<String>(dto.id),
      itemCode: Value<String?>(dto.itemCode),
      itemName: Value<String>(dto.itemName),
      itemGroup: Value<String>(dto.itemGroup),
      stockUom: Value<String>(dto.stockUom),
      description: Value<String?>(dto.description),
      disabled: Value<bool>(_toBool(dto.disabled)),
      hasVariants: Value<bool>(_toBool(dto.hasVariants)),
      valuationRate: Value<double?>(dto.valuationRate?.toDouble()),
      modified: Value<DateTime?>(dto.modified),
      updatedAt: Value<DateTime>(DateTime.now()),
    );
  }

  Map<String, dynamic> createInputToPayload(CreateItemInput input) {
    final String? itemCode = input.itemCode?.trim();
    return <String, dynamic>{
      if (itemCode != null && itemCode.isNotEmpty) 'item_code': itemCode,
      'item_name': input.itemName.trim(),
      'item_group': input.itemGroup.trim(),
      'stock_uom': input.stockUom.trim(),
      if (input.image != null) 'image': input.image,
      'description': input.description?.trim(),
      'disabled': input.disabled ? 1 : 0,
      'has_variants': input.hasVariants ? 1 : 0,
      'is_stock_item': input.maintainStock ? 1 : 0,
      if (input.openingStock != null) 'opening_stock': input.openingStock,
      if (input.valuationRate != null) 'valuation_rate': input.valuationRate,
      if (input.standardRate != null) 'standard_rate': input.standardRate,
      'is_fixed_asset': input.isFixedAsset ? 1 : 0,
    };
  }

  Map<String, dynamic> updateInputToPayload(UpdateItemInput input) {
    return <String, dynamic>{
      'item_name': input.itemName.trim(),
      'item_group': input.itemGroup.trim(),
      'stock_uom': input.stockUom.trim(),
      if (input.image != null) 'image': input.image,
      'description': input.description?.trim(),
      'disabled': input.disabled ? 1 : 0,
      'has_variants': input.hasVariants ? 1 : 0,
      'is_stock_item': input.maintainStock ? 1 : 0,
      if (input.openingStock != null) 'opening_stock': input.openingStock,
      if (input.valuationRate != null) 'valuation_rate': input.valuationRate,
      if (input.standardRate != null) 'standard_rate': input.standardRate,
      'is_fixed_asset': input.isFixedAsset ? 1 : 0,
    };
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }
}
