class UserEntity {
  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.enabled,
    required this.userType,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.userImage,
  });

  final String id;
  final String fullName;
  final String email;
  final bool enabled;
  final String userType;
  final String username;
  final String firstName;
  final String lastName;
  final String? userImage;

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    if (firstName.trim().isNotEmpty || lastName.trim().isNotEmpty) {
      return '${firstName.trim()} ${lastName.trim()}'.trim();
    }
    if (username.trim().isNotEmpty) {
      return username.trim();
    }
    if (email.trim().isNotEmpty) {
      return email.trim();
    }
    return id;
  }
}
