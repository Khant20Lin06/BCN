import '../../../../core/permissions/permission_flags.dart';

class SessionEntity {
  const SessionEntity({
    required this.baseUrl,
    required this.username,
    required this.cookieHeader,
    this.roles = const <String>[],
    this.permissions = const <String, PermissionFlags>{},
  });

  final String baseUrl;
  final String username;
  final String cookieHeader;
  final List<String> roles;
  final Map<String, PermissionFlags> permissions;

  SessionEntity copyWith({
    String? baseUrl,
    String? username,
    String? cookieHeader,
    List<String>? roles,
    Map<String, PermissionFlags>? permissions,
  }) {
    return SessionEntity(
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      cookieHeader: cookieHeader ?? this.cookieHeader,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
    );
  }
}
