import '../../../../core/permissions/permission_flags.dart';
import '../../domain/entities/session_entity.dart';
import '../dtos/login_dto.dart';

class SessionMapper {
  const SessionMapper();

  SessionEntity fromLoginDto({
    required LoginDto dto,
    required String baseUrl,
    required String username,
    required String cookieHeader,
    List<String> roles = const <String>[],
    Map<String, PermissionFlags> permissions =
        const <String, PermissionFlags>{},
  }) {
    return SessionEntity(
      baseUrl: baseUrl,
      username: username.isEmpty ? dto.email : username,
      cookieHeader: cookieHeader,
      roles: roles,
      permissions: permissions,
    );
  }
}
