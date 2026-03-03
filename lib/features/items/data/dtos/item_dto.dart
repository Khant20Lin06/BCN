import 'package:json_annotation/json_annotation.dart';

part 'item_dto.g.dart';

@JsonSerializable()
class ItemDto {
  const ItemDto({
    required this.id,
    this.itemCode,
    required this.itemName,
    required this.itemGroup,
    required this.stockUom,
    this.image,
    this.description,
    this.disabled,
    this.hasVariants,
    this.valuationRate,
    this.modified,
  });

  @JsonKey(name: 'name')
  final String id;

  @JsonKey(name: 'item_code')
  final String? itemCode;

  @JsonKey(name: 'item_name')
  final String itemName;

  @JsonKey(name: 'item_group')
  final String itemGroup;

  @JsonKey(name: 'stock_uom')
  final String stockUom;

  @JsonKey(name: 'image')
  final String? image;

  final String? description;

  final dynamic disabled;

  @JsonKey(name: 'has_variants')
  final dynamic hasVariants;

  @JsonKey(name: 'valuation_rate')
  final num? valuationRate;

  final DateTime? modified;

  factory ItemDto.fromJson(Map<String, dynamic> json) =>
      _$ItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ItemDtoToJson(this);
}
