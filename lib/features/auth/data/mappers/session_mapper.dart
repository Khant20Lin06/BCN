import '../../domain/entities/session_entity.dart';
import '../dtos/login_dto.dart';

class SessionMapper {
  const SessionMapper();

  SessionEntity fromLoginDto({
    required LoginDto dto,
    required String baseUrl,
    required String username,
    required String cookieHeader,
  }) {
    return SessionEntity(
      baseUrl: baseUrl,
      username: username.isEmpty ? dto.email : username,
      cookieHeader: cookieHeader,
    );
  }
}
