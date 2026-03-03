import 'package:json_annotation/json_annotation.dart';

part 'uom_dto.g.dart';

@JsonSerializable()
class UomDto {
  const UomDto({required this.name});

  final String name;

  factory UomDto.fromJson(Map<String, dynamic> json) => _$UomDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UomDtoToJson(this);
}
