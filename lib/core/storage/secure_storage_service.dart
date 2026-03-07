import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_customization.dart';
import '../permissions/permission_flags.dart';
import '../../features/auth/domain/entities/session_entity.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService(FlutterSecureStorage());
});

class SecureStorageService {
  const SecureStorageService(this._storage);

  static const String _sessionKey = 'session_payload';
  static const String _preferredBaseUrlKey = 'preferred_base_url';
  static const String _themeCustomizationKey = 'theme_customization';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(SessionEntity session) async {
    final String normalizedBaseUrl = _normalizeBaseUrl(session.baseUrl);
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(<String, Object?>{
        'baseUrl': normalizedBaseUrl,
        'username': session.username,
        'cookieHeader': session.cookieHeader,
        'roles': session.roles,
        'permissions': session.permissions.map(
          (String key, PermissionFlags value) =>
              MapEntry<String, Object?>(key, value.toJson()),
        ),
      }),
    );
    await savePreferredBaseUrl(normalizedBaseUrl);
  }

  Future<SessionEntity?> getSession() async {
    final String? raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    final List<dynamic> rawRoles =
        (map['roles'] as List<dynamic>?) ?? const <dynamic>[];
    final List<String> roles = rawRoles
        .whereType<String>()
        .map((String role) => role.trim())
        .where((String role) => role.isNotEmpty)
        .toList(growable: false);
    final Map<String, dynamic> rawPermissions =
        (map['permissions'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final Map<String, PermissionFlags> permissions =
        <String, PermissionFlags>{};
    rawPermissions.forEach((String key, dynamic value) {
      if (value is Map<String, dynamic>) {
        permissions[key] = PermissionFlags.fromJson(value);
      } else if (value is Map) {
        permissions[key] = PermissionFlags.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    });

    return SessionEntity(
      baseUrl: map['baseUrl'] as String,
      username: map['username'] as String,
      cookieHeader: map['cookieHeader'] as String,
      roles: roles,
      permissions: permissions,
    );
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }

  Future<void> savePreferredBaseUrl(String baseUrl) async {
    await _storage.write(
      key: _preferredBaseUrlKey,
      value: _normalizeBaseUrl(baseUrl),
    );
  }

  Future<String?> getPreferredBaseUrl() async {
    final String? raw = await _storage.read(key: _preferredBaseUrlKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return _normalizeBaseUrl(raw);
  }

  Future<void> clearPreferredBaseUrl() async {
    await _storage.delete(key: _preferredBaseUrlKey);
  }

  Future<void> clearServerConfiguration() async {
    await clearSession();
    await clearPreferredBaseUrl();
  }

  Future<void> saveThemeCustomization(ThemeCustomization customization) async {
    await _storage.write(
      key: _themeCustomizationKey,
      value: jsonEncode(customization.toJson()),
    );
  }

  Future<ThemeCustomization?> getThemeCustomization() async {
    final String? raw = await _storage.read(key: _themeCustomizationKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    return ThemeCustomization.fromJson(map);
  }

  String _normalizeBaseUrl(String baseUrl) {
    final String trimmed = baseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
