// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemDto _$ItemDtoFromJson(Map<String, dynamic> json) => ItemDto(
  id: json['name'] as String,
  itemCode: json['item_code'] as String?,
  itemName: json['item_name'] as String,
  itemGroup: json['item_group'] as String,
  stockUom: json['stock_uom'] as String,
  image: json['image'] as String?,
  description: json['description'] as String?,
  openingStock: json['opening_stock'] as num?,
  disabled: json['disabled'],
  hasVariants: json['has_variants'],
  maintainStock: json['is_stock_item'],
  isFixedAsset: json['is_fixed_asset'],
  valuationRate: json['valuation_rate'] as num?,
  standardRate: json['standard_rate'] as num?,
  modified: json['modified'] == null
      ? null
      : DateTime.parse(json['modified'] as String),
);

Map<String, dynamic> _$ItemDtoToJson(ItemDto instance) => <String, dynamic>{
  'name': instance.id,
  'item_code': instance.itemCode,
  'item_name': instance.itemName,
  'item_group': instance.itemGroup,
  'stock_uom': instance.stockUom,
  'image': instance.image,
  'description': instance.description,
  'opening_stock': instance.openingStock,
  'disabled': instance.disabled,
  'has_variants': instance.hasVariants,
  'is_stock_item': instance.maintainStock,
  'is_fixed_asset': instance.isFixedAsset,
  'valuation_rate': instance.valuationRate,
  'standard_rate': instance.standardRate,
  'modified': instance.modified?.toIso8601String(),
};
