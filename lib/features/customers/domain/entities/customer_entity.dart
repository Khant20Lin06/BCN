class CustomerEntity {
  const CustomerEntity({
    required this.id,
    required this.customerName,
    required this.customerType,
    required this.customerGroup,
    required this.territory,
    this.creation,
    this.modified,
  });

  final String id;
  final String customerName;
  final String customerType;
  final String customerGroup;
  final String territory;
  final DateTime? creation;
  final DateTime? modified;

  String get displayName {
    final String normalizedName = customerName.trim();
    if (normalizedName.isNotEmpty) {
      return normalizedName;
    }
    return id;
  }
}
