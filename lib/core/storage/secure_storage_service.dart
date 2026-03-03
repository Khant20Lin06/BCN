import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/session_entity.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService(FlutterSecureStorage());
});

class SecureStorageService {
  const SecureStorageService(this._storage);

  static const String _sessionKey = 'session_payload';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(SessionEntity session) async {
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(<String, Object?>{
        'baseUrl': session.baseUrl,
        'username': session.username,
        'cookieHeader': session.cookieHeader,
      }),
    );
  }

  Future<SessionEntity?> getSession() async {
    final String? raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    return SessionEntity(
      baseUrl: map['baseUrl'] as String,
      username: map['username'] as String,
      cookieHeader: map['cookieHeader'] as String,
    );
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }
}
