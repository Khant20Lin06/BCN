class FrappeListResponseDto {
  const FrappeListResponseDto({required this.data});

  final List<Map<String, dynamic>> data;

  factory FrappeListResponseDto.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawData =
        (json['data'] as List<dynamic>?) ?? <dynamic>[];
    return FrappeListResponseDto(
      data: rawData.whereType<Map<String, dynamic>>().toList(growable: false),
    );
  }
}
