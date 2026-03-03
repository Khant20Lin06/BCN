import 'package:json_annotation/json_annotation.dart';

part 'item_group_dto.g.dart';

@JsonSerializable()
class ItemGroupDto {
  const ItemGroupDto({required this.name});

  final String name;

  factory ItemGroupDto.fromJson(Map<String, dynamic> json) =>
      _$ItemGroupDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ItemGroupDtoToJson(this);
}
