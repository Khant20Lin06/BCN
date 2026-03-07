import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/frappe_api_client.dart';
import '../../../../core/permissions/app_permission_resolver.dart';
import '../../../../core/permissions/permission_flags.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/session_entity.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._apiClient, this._storageService);

  final FrappeApiClient _apiClient;
  final SecureStorageService _storageService;
  static bool _crudPermissionProbeUnavailable = false;
  static const Duration _authConnectTimeout = Duration(seconds: 30);
  static const Duration _authReceiveTimeout = Duration(seconds: 45);

  static const Map<AppModule, List<String>> _moduleDocTypes =
      <AppModule, List<String>>{
        AppModule.items: <String>['Item'],
        AppModule.customers: <String>['Customer'],
        AppModule.salesInvoices: <String>['Sales Invoice'],
        AppModule.itemPrices: <String>['Item Price'],
        AppModule.stockBalances: <String>[
          'Bin',
          'Stock Reconciliation',
          'Warehouse',
        ],
        AppModule.profile: <String>['User'],
      };

  static const Map<AppModule, List<String>> _moduleReadDocTypes =
      <AppModule, List<String>>{
        AppModule.items: <String>['Item'],
        AppModule.customers: <String>['Customer'],
        AppModule.salesInvoices: <String>['Sales Invoice'],
        AppModule.itemPrices: <String>['Item Price'],
        AppModule.stockBalances: <String>[
          'Bin',
          'Warehouse',
          'Stock Reconciliation',
        ],
        AppModule.profile: <String>['User'],
      };

  Future<SessionEntity> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final String baseUrl = await _resolveBaseUrl();
    final response = await _apiClient.postRaw(
      '/api/method/login',
      requireAuth: false,
      baseUrlOverride: baseUrl,
      data: <String, dynamic>{'usr': email, 'pwd': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
      connectTimeout: _authConnectTimeout,
      receiveTimeout: _authReceiveTimeout,
    );

    final List<String> setCookies =
        response.headers.map['set-cookie'] ?? <String>[];
    final String cookieHeader = _toCookieHeader(setCookies);
    if (cookieHeader.isEmpty) {
      throw AppException(message: 'Login failed: missing session cookie');
    }

    final SessionEntity candidate = SessionEntity(
      baseUrl: baseUrl,
      username: email,
      cookieHeader: cookieHeader,
    );

    final Map<String, dynamic> me = await _apiClient.get(
      ApiConstants.loggedUserPath,
      requireAuth: true,
      sessionOverride: candidate,
      connectTimeout: _authConnectTimeout,
      receiveTimeout: _authReceiveTimeout,
    );

    final dynamic message = me['message'];
    final dynamic data = me['data'];
    final String username = (message is String && message.isNotEmpty)
        ? message
        : (data is String && data.isNotEmpty)
        ? data
        : email;

    final SessionEntity baseSession = candidate.copyWith(username: username);
    return _buildSessionWithPermissions(baseSession);
  }

  Future<SessionEntity> refreshSession(SessionEntity session) async {
    SessionEntity baseSession = session;
    try {
      final Map<String, dynamic> me = await _apiClient.get(
        ApiConstants.loggedUserPath,
        requireAuth: true,
        sessionOverride: session,
        connectTimeout: _authConnectTimeout,
        receiveTimeout: _authReceiveTimeout,
      );
      final dynamic message = me['message'];
      final dynamic data = me['data'];
      final String username = (message is String && message.isNotEmpty)
          ? message
          : (data is String && data.isNotEmpty)
          ? data
          : session.username;
      baseSession = session.copyWith(username: username);
    } catch (_) {
      // Keep current username if read-profile endpoint is unavailable.
    }

    return _buildSessionWithPermissions(baseSession);
  }

  Future<String> requestPasswordReset({required String email}) async {
    final String baseUrl = await _resolveBaseUrl();
    final Response<dynamic> response = await _apiClient.postRaw(
      ApiConstants.forgotPasswordPath,
      requireAuth: false,
      baseUrlOverride: baseUrl,
      data: <String, dynamic>{'user': email.trim()},
      options: Options(contentType: Headers.formUrlEncodedContentType),
      connectTimeout: _authConnectTimeout,
      receiveTimeout: _authReceiveTimeout,
    );

    final dynamic payload = response.data;
    if (payload is Map<String, dynamic>) {
      final dynamic message = payload['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return 'Password reset instructions have been sent to your email.';
  }

  String _toCookieHeader(List<String> setCookies) {
    final List<String> pairs = <String>[];
    for (final String value in setCookies) {
      final String pair = value.split(';').first.trim();
      if (pair.isNotEmpty) {
        pairs.add(pair);
      }
    }
    return pairs.join('; ');
  }

  Future<SessionEntity> _buildSessionWithPermissions(
    SessionEntity baseSession,
  ) async {
    try {
      final List<String> roles = await _fetchUserRoles(
        session: baseSession,
        username: baseSession.username,
      );
      final Map<String, PermissionFlags> permissions =
          Map<String, PermissionFlags>.from(
            await _fetchModulePermissions(session: baseSession, roles: roles),
          );
      final Map<String, PermissionFlags> crudProbed =
          await _probeCrudPermissions(session: baseSession);
      for (final MapEntry<String, PermissionFlags> entry
          in crudProbed.entries) {
        final PermissionFlags current =
            permissions[entry.key] ?? PermissionFlags.none;
        permissions[entry.key] = current.merge(entry.value);
      }
      final Map<String, PermissionFlags> probed = await _probeReadPermissions(
        session: baseSession,
      );
      for (final MapEntry<String, PermissionFlags> entry in probed.entries) {
        final PermissionFlags current =
            permissions[entry.key] ?? PermissionFlags.none;
        permissions[entry.key] = current.merge(entry.value);
      }
      return baseSession.copyWith(roles: roles, permissions: permissions);
    } on DioException catch (error) {
      if (_isTimeoutError(error) && _hasCachedAuthContext(baseSession)) {
        // Preserve cached auth when startup refresh probes time out.
        return baseSession;
      }
      rethrow;
    }
  }

  Future<Map<String, PermissionFlags>> _probeCrudPermissions({
    required SessionEntity session,
  }) async {
    if (_crudPermissionProbeUnavailable) {
      return const <String, PermissionFlags>{};
    }

    final Map<String, PermissionFlags> permissions =
        <String, PermissionFlags>{};

    for (final MapEntry<AppModule, List<String>> entry
        in _moduleDocTypes.entries) {
      bool canCreate = false;
      bool canWrite = false;
      bool canDelete = false;

      for (final String doctype in entry.value) {
        canCreate =
            canCreate ||
            await _hasPermission(
              session: session,
              doctype: doctype,
              ptype: 'create',
            );
        canWrite =
            canWrite ||
            await _hasPermission(
              session: session,
              doctype: doctype,
              ptype: 'write',
            );
        canDelete =
            canDelete ||
            await _hasPermission(
              session: session,
              doctype: doctype,
              ptype: 'delete',
            );

        if (canCreate && canWrite && canDelete) {
          break;
        }
      }

      if (!(canCreate || canWrite || canDelete)) {
        continue;
      }

      permissions[entry.key.key] = PermissionFlags(
        create: canCreate,
        write: canWrite,
        delete: canDelete,
      );
    }

    return permissions;
  }

  Future<List<String>> _fetchUserRoles({
    required SessionEntity session,
    required String username,
  }) async {
    final Set<String> roles = <String>{};
    try {
      final Map<String, dynamic> response = await _apiClient.get(
        ApiConstants.hasRolePath,
        requireAuth: true,
        sessionOverride: session,
        queryParameters: <String, dynamic>{
          'fields': jsonEncode(<String>['role']),
          'filters': jsonEncode(<List<dynamic>>[
            <dynamic>['Has Role', 'parenttype', '=', 'User'],
            <dynamic>['Has Role', 'parent', '=', username],
          ]),
          'order_by': 'idx asc',
          'limit_page_length': 300,
        },
      );
      final List<dynamic> rows =
          (response['data'] as List<dynamic>?) ?? const <dynamic>[];
      for (final Map<String, dynamic> row
          in rows.whereType<Map<String, dynamic>>()) {
        final String role = (row['role'] as String? ?? '').trim();
        if (role.isNotEmpty) {
          roles.add(role);
        }
      }
    } on DioException catch (error) {
      if (_isTimeoutError(error)) {
        rethrow;
      }
      // fallback below
    } catch (_) {
      // fallback below
    }

    if (roles.isNotEmpty) {
      final List<String> sorted = roles.toList(growable: false);
      sorted.sort(_compareCaseInsensitive);
      return sorted;
    }

    try {
      final Map<String, dynamic> response = await _apiClient.get(
        '${ApiConstants.userPath}/$username',
        requireAuth: true,
        sessionOverride: session,
      );
      final Map<String, dynamic> data =
          (response['data'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      final List<dynamic> rows =
          (data['roles'] as List<dynamic>?) ?? const <dynamic>[];
      for (final Map<String, dynamic> row
          in rows.whereType<Map<String, dynamic>>()) {
        final String role = (row['role'] as String? ?? '').trim();
        if (role.isNotEmpty) {
          roles.add(role);
        }
      }
    } on DioException catch (error) {
      if (_isTimeoutError(error)) {
        rethrow;
      }
      // keep empty if both endpoints are blocked
    } catch (_) {
      // keep empty if both endpoints are blocked
    }

    if (roles.isNotEmpty) {
      final List<String> sorted = roles.toList(growable: false);
      sorted.sort(_compareCaseInsensitive);
      return sorted;
    }

    // Fallback: for some tenants /api/resource/User may be blocked while
    // frappe.client.get for own user still works.
    try {
      final Map<String, dynamic> response = await _apiClient.get(
        '/api/method/frappe.client.get',
        requireAuth: true,
        sessionOverride: session,
        queryParameters: <String, dynamic>{'doctype': 'User', 'name': username},
      );
      final dynamic message = response['message'];
      if (message is Map<String, dynamic>) {
        final List<dynamic> rows =
            (message['roles'] as List<dynamic>?) ?? const <dynamic>[];
        for (final Map<String, dynamic> row
            in rows.whereType<Map<String, dynamic>>()) {
          final String role = (row['role'] as String? ?? '').trim();
          if (role.isNotEmpty) {
            roles.add(role);
          }
        }
      }
    } on DioException catch (error) {
      if (_isTimeoutError(error)) {
        rethrow;
      }
      // Keep empty if all role endpoints are unavailable.
    } catch (_) {
      // Keep empty if all role endpoints are unavailable.
    }

    final List<String> sorted = roles.toList(growable: false);
    sorted.sort(_compareCaseInsensitive);
    return sorted;
  }

  Future<Map<String, PermissionFlags>> _fetchModulePermissions({
    required SessionEntity session,
    required List<String> roles,
  }) async {
    if (roles.isEmpty) {
      return <String, PermissionFlags>{};
    }

    final Map<String, PermissionFlags> permissions =
        <String, PermissionFlags>{};
    for (final MapEntry<AppModule, List<String>> moduleEntry
        in _moduleDocTypes.entries) {
      PermissionFlags merged = PermissionFlags.none;
      bool fetchedAny = false;

      for (final String doctype in moduleEntry.value) {
        final PermissionFlags? doctypePermission =
            await _fetchDoctypePermission(
              session: session,
              doctype: doctype,
              roles: roles,
            );
        if (doctypePermission != null) {
          fetchedAny = true;
          merged = merged.merge(doctypePermission);
        }
      }

      if (fetchedAny) {
        permissions[moduleEntry.key.key] = merged;
      }
    }
    return permissions;
  }

  Future<Map<String, PermissionFlags>> _probeReadPermissions({
    required SessionEntity session,
  }) async {
    final Map<String, PermissionFlags> permissions =
        <String, PermissionFlags>{};

    for (final MapEntry<AppModule, List<String>> entry
        in _moduleReadDocTypes.entries) {
      bool canReadAny = false;
      for (final String doctype in entry.value) {
        final bool canRead = await _canReadDoctype(
          session: session,
          doctype: doctype,
        );
        if (canRead) {
          canReadAny = true;
          break;
        }
      }
      if (!canReadAny) {
        continue;
      }
      permissions[entry.key.key] = const PermissionFlags(
        select: true,
        read: true,
      );
    }

    return permissions;
  }

  Future<bool> _canReadDoctype({
    required SessionEntity session,
    required String doctype,
  }) async {
    try {
      await _apiClient.get(
        '/api/resource/${Uri.encodeComponent(doctype)}',
        requireAuth: true,
        sessionOverride: session,
        queryParameters: <String, dynamic>{
          'fields': jsonEncode(<String>['name']),
          'limit_page_length': 1,
        },
      );
      return true;
    } on DioException catch (error) {
      if (_isTimeoutError(error)) {
        rethrow;
      }
      final int? code = error.response?.statusCode;
      if (code == 401 || code == 403) {
        return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<PermissionFlags?> _fetchDoctypePermission({
    required SessionEntity session,
    required String doctype,
    required List<String> roles,
  }) async {
    try {
      final Map<String, dynamic> response = await _apiClient.get(
        ApiConstants.docPermPath,
        requireAuth: true,
        sessionOverride: session,
        queryParameters: <String, dynamic>{
          'fields': jsonEncode(<String>[
            'select',
            'read',
            'write',
            'create',
            'delete',
          ]),
          'filters': jsonEncode(<List<dynamic>>[
            <dynamic>['DocPerm', 'parent', '=', doctype],
            <dynamic>['DocPerm', 'role', 'in', roles],
            <dynamic>['DocPerm', 'permlevel', '=', 0],
          ]),
          'limit_page_length': 300,
        },
      );
      final List<dynamic> rows =
          (response['data'] as List<dynamic>?) ?? const <dynamic>[];
      PermissionFlags merged = PermissionFlags.none;
      for (final Map<String, dynamic> row
          in rows.whereType<Map<String, dynamic>>()) {
        merged = merged.merge(PermissionFlags.fromDocPermRow(row));
      }
      return merged;
    } on DioException catch (error) {
      if (_isTimeoutError(error)) {
        rethrow;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _hasPermission({
    required SessionEntity session,
    required String doctype,
    required String ptype,
  }) async {
    if (_crudPermissionProbeUnavailable) {
      return false;
    }

    final List<String> methods = <String>[
      '/api/method/frappe.client.has_permission',
      '/api/method/frappe.permissions.has_permission',
    ];

    for (final String method in methods) {
      try {
        final Map<String, dynamic> response = await _apiClient.get(
          method,
          requireAuth: true,
          sessionOverride: session,
          queryParameters: <String, dynamic>{
            'doctype': doctype,
            'ptype': ptype,
          },
        );
        if (_extractHasPermission(response)) {
          return true;
        }
      } on DioException catch (error) {
        if (_isTimeoutError(error)) {
          rethrow;
        }
        if (_isMethodUnavailableStatus(error.response?.statusCode)) {
          _crudPermissionProbeUnavailable = true;
          return false;
        }
        // Try next endpoint variant for non-terminal errors.
      } catch (_) {
        // Try next endpoint variant.
      }
    }

    return false;
  }

  bool _extractHasPermission(Map<String, dynamic> response) {
    final dynamic message = response['message'];
    final bool? fromMessage = _toBool(message);
    if (fromMessage != null) {
      return fromMessage;
    }

    if (message is Map<String, dynamic>) {
      final bool? has = _toBool(message['has_permission']);
      if (has != null) {
        return has;
      }
      final bool? value = _toBool(message['value']);
      if (value != null) {
        return value;
      }
    }

    final bool? direct = _toBool(response['has_permission']);
    if (direct != null) {
      return direct;
    }
    return false;
  }

  bool? _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
        return true;
      }
      if (normalized == '0' || normalized == 'false' || normalized == 'no') {
        return false;
      }
    }
    return null;
  }

  static bool _isMethodUnavailableStatus(int? status) {
    if (status == null) {
      return false;
    }
    return status == 404 || status == 405 || status >= 500;
  }

  static int _compareCaseInsensitive(String a, String b) {
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  static bool _isTimeoutError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  static bool _hasCachedAuthContext(SessionEntity session) {
    return session.roles.isNotEmpty || session.permissions.isNotEmpty;
  }

  Future<String> _resolveBaseUrl() async {
    final String? preferred = await _storageService.getPreferredBaseUrl();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }
    throw AppException(message: 'Server URL is not configured');
  }
}
