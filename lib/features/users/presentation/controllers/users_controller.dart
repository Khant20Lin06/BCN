import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/frappe_api_client.dart';
import '../../../../core/network/frappe_file_upload_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/user_entity.dart';
import '../state/users_state.dart';

final usersApiClientProvider = Provider<FrappeApiClient>((Ref ref) {
  return FrappeApiClient(
    storageService: ref.watch(secureStorageServiceProvider),
    dioFactory: DioFactory(ref.watch(appLoggerProvider)),
  );
});

final usersControllerProvider =
    StateNotifierProvider<UsersController, UsersState>((Ref ref) {
      return UsersController(
        ref.watch(usersApiClientProvider),
        ref.watch(secureStorageServiceProvider),
      );
    });

final userDetailProvider = FutureProvider.family<UserEntity, String>((
  Ref ref,
  String id,
) async {
  return ref.watch(usersControllerProvider.notifier).getUserDetail(id);
});

class UsersController extends StateNotifier<UsersState> {
  UsersController(this._apiClient, this._storageService)
    : _fileUploadService = FrappeFileUploadService(_apiClient),
      super(const UsersState.initial()) {
    unawaited(_hydrateBaseUrl());
  }

  static const List<String> _userFields = <String>[
    'name',
    'full_name',
    'email',
    'enabled',
    'user_type',
    'username',
    'first_name',
    'last_name',
    'user_image',
  ];

  final FrappeApiClient _apiClient;
  final SecureStorageService _storageService;
  final FrappeFileUploadService _fileUploadService;
  Timer? _searchDebounce;
  String _baseUrl = '';

  Future<void> loadUsers() async {
    state = state.copyWith(status: UsersStatus.loading, errorMessage: null);

    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'fields': jsonEncode(_userFields),
        'order_by': 'modified desc',
        'limit_page_length': 100,
      };

      final String search = state.searchQuery.trim();
      if (search.isNotEmpty) {
        params['or_filters'] = jsonEncode(<List<dynamic>>[
          <dynamic>['full_name', 'like', '%$search%'],
          <dynamic>['email', 'like', '%$search%'],
          <dynamic>['username', 'like', '%$search%'],
          <dynamic>['name', 'like', '%$search%'],
        ]);
      }

      final Map<String, dynamic> json = await _apiClient.get(
        ApiConstants.userPath,
        queryParameters: params,
      );

      final List<dynamic> raw = (json['data'] as List<dynamic>?) ?? <dynamic>[];
      final List<UserEntity> users = raw
          .whereType<Map<String, dynamic>>()
          .map(_mapUser)
          .toList(growable: false);

      state = state.copyWith(
        status: users.isEmpty ? UsersStatus.empty : UsersStatus.success,
        users: users,
      );
    } catch (error) {
      state = state.copyWith(
        status: UsersStatus.error,
        errorMessage: _toFailure(error).message,
      );
    }
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final String normalized = value.trim();
      state = state.copyWith(searchQuery: normalized);
      unawaited(loadUsers());
    });
  }

  Future<UserEntity> getUserDetail(String id) async {
    try {
      final Map<String, dynamic> json = await _apiClient.get(
        '${ApiConstants.userPath}/${Uri.encodeComponent(id)}',
        queryParameters: <String, dynamic>{'fields': jsonEncode(_userFields)},
      );
      final Map<String, dynamic> data =
          (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      return _mapUser(data);
    } catch (error) {
      final UserEntity? fallback = await _getSelfProfileFallback(id);
      if (fallback != null) {
        return fallback;
      }
      throw _toFailure(error);
    }
  }

  Future<Failure?> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required String username,
    required bool enabled,
    required String password,
    String? userImage,
  }) async {
    try {
      final Map<String, dynamic> payload = <String, dynamic>{
        'email': email.trim(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'enabled': enabled ? 1 : 0,
        'send_welcome_email': 0,
        if (username.trim().isNotEmpty) 'username': username.trim(),
        if (password.trim().isNotEmpty) 'new_password': password.trim(),
        'user_image': userImage,
      };
      payload.removeWhere((String key, dynamic value) => value == null);

      await _apiClient.post(ApiConstants.userPath, data: payload);
      await loadUsers();
      return null;
    } catch (error) {
      return _toFailure(error);
    }
  }

  Future<Failure?> updateUser({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    required String username,
    required bool enabled,
    required String password,
    String? userImage,
  }) async {
    try {
      final Map<String, dynamic> payload = <String, dynamic>{
        'email': email.trim(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'enabled': enabled ? 1 : 0,
        if (username.trim().isNotEmpty) 'username': username.trim(),
        if (password.trim().isNotEmpty) 'new_password': password.trim(),
        'user_image': userImage,
      };
      payload.removeWhere((String key, dynamic value) => value == null);

      await _apiClient.put(
        '${ApiConstants.userPath}/${Uri.encodeComponent(id)}',
        data: payload,
      );
      await loadUsers();
      return null;
    } catch (error) {
      return _toFailure(error);
    }
  }

  Future<Failure?> deleteUser(String id) async {
    try {
      await _apiClient.delete(
        '${ApiConstants.userPath}/${Uri.encodeComponent(id)}',
      );
      await loadUsers();
      return null;
    } catch (error) {
      return _toFailure(error);
    }
  }

  Future<Either<Failure, String>> uploadUserImage({
    required String filePath,
    String? userId,
  }) async {
    try {
      final bool canAttachToExistingDoc =
          userId != null && userId.trim().isNotEmpty;
      final String fileUrl = await _fileUploadService.uploadImage(
        filePath: filePath,
        doctype: canAttachToExistingDoc ? 'User' : null,
        docname: canAttachToExistingDoc ? userId : null,
        fieldname: canAttachToExistingDoc ? 'user_image' : null,
      );
      return Right<Failure, String>(fileUrl);
    } catch (error) {
      return Left<Failure, String>(_toFailure(error));
    }
  }

  String resolveImageUrl(String? path) {
    final String normalized = (path ?? '').trim();
    if (normalized.isEmpty) {
      return '';
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    if (_baseUrl.isEmpty) {
      return '';
    }
    return '$_baseUrl$normalized';
  }

  Failure _toFailure(Object error) {
    if (error is Failure) {
      return error;
    }
    return mapExceptionToFailure(error);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<UserEntity?> _getSelfProfileFallback(String requestedId) async {
    final session = await _storageService.getSession();
    if (session == null) {
      return null;
    }

    final String normalizedRequested = requestedId.trim().toLowerCase();
    final String normalizedSession = session.username.trim().toLowerCase();
    if (normalizedRequested.isNotEmpty &&
        normalizedRequested != normalizedSession) {
      return null;
    }

    try {
      final Map<String, dynamic> json = await _apiClient.get(
        '/api/method/frappe.client.get',
        queryParameters: <String, dynamic>{
          'doctype': 'User',
          'name': session.username,
        },
      );
      final dynamic message = json['message'];
      if (message is Map<String, dynamic>) {
        return _mapUser(message);
      }
    } catch (_) {
      // Continue to cookie/session fallback.
    }

    final Map<String, String> cookieMap = _cookieMap(session.cookieHeader);
    final String email = _decodeCookie(cookieMap['user_id']).isNotEmpty
        ? _decodeCookie(cookieMap['user_id'])
        : session.username;
    final String fullName = _decodeCookie(cookieMap['full_name']);
    final String userImage = _decodeCookie(cookieMap['user_image']);
    final List<String> nameParts = fullName
        .split(RegExp(r'\s+'))
        .where((String part) => part.trim().isNotEmpty)
        .toList(growable: false);
    final String firstName = nameParts.isEmpty ? '' : nameParts.first;
    final String lastName = nameParts.length <= 1
        ? ''
        : nameParts.sublist(1).join(' ');
    final String username = session.username.contains('@')
        ? session.username.split('@').first
        : session.username;

    return UserEntity(
      id: session.username,
      fullName: fullName,
      email: email,
      enabled: true,
      userType: 'System User',
      username: username,
      firstName: firstName,
      lastName: lastName,
      userImage: userImage.isEmpty ? null : userImage,
    );
  }

  Map<String, String> _cookieMap(String cookieHeader) {
    final Map<String, String> values = <String, String>{};
    for (final String pair in cookieHeader.split(';')) {
      final String trimmed = pair.trim();
      if (trimmed.isEmpty || !trimmed.contains('=')) {
        continue;
      }
      final int separator = trimmed.indexOf('=');
      final String key = trimmed.substring(0, separator).trim();
      final String value = trimmed.substring(separator + 1).trim();
      if (key.isEmpty) {
        continue;
      }
      values[key] = value;
    }
    return values;
  }

  String _decodeCookie(String? value) {
    final String raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return '';
    }
    try {
      return Uri.decodeComponent(raw);
    } catch (_) {
      return raw;
    }
  }

  Future<void> _hydrateBaseUrl() async {
    final String? preferred = await _storageService.getPreferredBaseUrl();
    if (preferred != null && preferred.isNotEmpty) {
      _baseUrl = preferred;
      return;
    }

    final session = await _storageService.getSession();
    _baseUrl = session?.baseUrl.trim() ?? '';
  }
}

UserEntity _mapUser(Map<String, dynamic> data) {
  return UserEntity(
    id: (data['name'] as String?) ?? '',
    fullName: (data['full_name'] as String?) ?? '',
    email: (data['email'] as String?) ?? '',
    enabled: _toBool(data['enabled']),
    userType: (data['user_type'] as String?) ?? '',
    username: (data['username'] as String?) ?? '',
    firstName: (data['first_name'] as String?) ?? '',
    lastName: (data['last_name'] as String?) ?? '',
    userImage: (data['user_image'] as String?)?.trim(),
  );
}

bool _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return false;
}
