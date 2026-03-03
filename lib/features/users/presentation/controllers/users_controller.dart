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
      return UsersController(ref.watch(usersApiClientProvider));
    });

final userDetailProvider = FutureProvider.family<UserEntity, String>((
  Ref ref,
  String id,
) async {
  return ref.watch(usersControllerProvider.notifier).getUserDetail(id);
});

class UsersController extends StateNotifier<UsersState> {
  UsersController(this._apiClient)
    : _fileUploadService = FrappeFileUploadService(_apiClient),
      super(const UsersState.initial());

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
  final FrappeFileUploadService _fileUploadService;
  Timer? _searchDebounce;

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
    final Map<String, dynamic> json = await _apiClient.get(
      '${ApiConstants.userPath}/${Uri.encodeComponent(id)}',
      queryParameters: <String, dynamic>{'fields': jsonEncode(_userFields)},
    );
    final Map<String, dynamic> data =
        (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return _mapUser(data);
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
      final String fileUrl = await _fileUploadService.uploadImage(
        filePath: filePath,
        doctype: 'User',
        docname: userId,
        fieldname: 'user_image',
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
    return '${ApiConstants.baseUrl}$normalized';
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
