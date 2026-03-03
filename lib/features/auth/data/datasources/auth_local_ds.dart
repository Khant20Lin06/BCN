import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/session_entity.dart';

class AuthLocalDataSource {
  const AuthLocalDataSource(this._storageService);

  final SecureStorageService _storageService;

  Future<void> saveSession(SessionEntity session) =>
      _storageService.saveSession(session);

  Future<SessionEntity?> getSession() => _storageService.getSession();

  Future<void> clearSession() => _storageService.clearSession();
}
