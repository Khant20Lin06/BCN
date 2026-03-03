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
  disabled: json['disabled'],
  hasVariants: json['has_variants'],
  valuationRate: json['valuation_rate'] as num?,
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
  'disabled': instance.disabled,
  'has_variants': instance.hasVariants,
  'valuation_rate': instance.valuationRate,
  'modified': instance.modified?.toIso8601String(),
};
