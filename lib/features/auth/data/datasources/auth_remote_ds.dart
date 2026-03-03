import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/frappe_api_client.dart';
import '../../domain/entities/session_entity.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._apiClient);

  final FrappeApiClient _apiClient;

  Future<SessionEntity> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postRaw(
      '/api/method/login',
      requireAuth: false,
      baseUrlOverride: ApiConstants.baseUrl,
      data: <String, dynamic>{'usr': email, 'pwd': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final List<String> setCookies =
        response.headers.map['set-cookie'] ?? <String>[];
    final String cookieHeader = _toCookieHeader(setCookies);
    if (cookieHeader.isEmpty) {
      throw AppException(message: 'Login failed: missing session cookie');
    }

    final SessionEntity candidate = SessionEntity(
      baseUrl: ApiConstants.baseUrl,
      username: email,
      cookieHeader: cookieHeader,
    );

    final Map<String, dynamic> me = await _apiClient.get(
      ApiConstants.loggedUserPath,
      requireAuth: true,
      sessionOverride: candidate,
    );

    final dynamic message = me['message'];
    final dynamic data = me['data'];
    final String username = (message is String && message.isNotEmpty)
        ? message
        : (data is String && data.isNotEmpty)
        ? data
        : email;

    return candidate.copyWith(username: username);
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
}
