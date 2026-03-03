import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/domain/entities/session_entity.dart';
import '../constants/api_constants.dart';
import '../error/app_exception.dart';
import '../storage/secure_storage_service.dart';
import 'dio_factory.dart';

class FrappeApiClient {
  FrappeApiClient({
    required SecureStorageService storageService,
    required DioFactory dioFactory,
  }) : _storageService = storageService,
       _dioFactory = dioFactory;

  final SecureStorageService _storageService;
  final DioFactory _dioFactory;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    SessionEntity? sessionOverride,
    bool requireAuth = true,
    String? baseUrlOverride,
  }) async {
    final Dio dio = await _buildDio(
      sessionOverride: sessionOverride,
      requireAuth: requireAuth,
      baseUrlOverride: baseUrlOverride,
    );
    final Response<dynamic> response = await dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    SessionEntity? sessionOverride,
    bool requireAuth = true,
    String? baseUrlOverride,
  }) async {
    final Dio dio = await _buildDio(
      sessionOverride: sessionOverride,
      requireAuth: requireAuth,
      baseUrlOverride: baseUrlOverride,
    );
    final Response<dynamic> response = await dio.post<dynamic>(
      path,
      data: data,
    );
    return _asMap(response.data);
  }

  Future<Response<dynamic>> postRaw(
    String path, {
    Object? data,
    bool requireAuth = true,
    SessionEntity? sessionOverride,
    String? baseUrlOverride,
    Options? options,
  }) async {
    final Dio dio = await _buildDio(
      sessionOverride: sessionOverride,
      requireAuth: requireAuth,
      baseUrlOverride: baseUrlOverride,
    );
    return dio.post<dynamic>(path, data: data, options: options);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    SessionEntity? sessionOverride,
  }) async {
    final Dio dio = await _buildDio(sessionOverride: sessionOverride);
    final Response<dynamic> response = await dio.put<dynamic>(path, data: data);
    return _asMap(response.data);
  }

  Future<void> delete(String path, {SessionEntity? sessionOverride}) async {
    final Dio dio = await _buildDio(sessionOverride: sessionOverride);
    await dio.delete<dynamic>(path);
  }

  Future<Dio> _buildDio({
    SessionEntity? sessionOverride,
    bool requireAuth = true,
    String? baseUrlOverride,
  }) async {
    final SessionEntity? session =
        sessionOverride ?? await _storageService.getSession();

    if (requireAuth) {
      if (session == null) {
        throw UnauthorizedException(
          message: 'Session not found',
          statusCode: 401,
        );
      }

      _validateBaseUrl(session.baseUrl);
      return _dioFactory.create(
        baseUrl: session.baseUrl,
        headers: <String, String>{'Cookie': session.cookieHeader},
      );
    }

    final String baseUrl =
        (baseUrlOverride ?? session?.baseUrl ?? ApiConstants.baseUrl).trim();
    _validateBaseUrl(baseUrl);
    return _dioFactory.create(baseUrl: baseUrl);
  }

  void _validateBaseUrl(String baseUrl) {
    final Uri uri = Uri.parse(baseUrl);
    if (kReleaseMode && uri.scheme.toLowerCase() != 'https') {
      throw AppException(message: 'HTTPS is required in production mode');
    }

    if (!kReleaseMode &&
        uri.scheme.toLowerCase() != 'https' &&
        uri.host != 'localhost') {
      throw const HttpException(
        'Non-HTTPS URL is not allowed for non-localhost targets',
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw AppException(message: 'Invalid response payload type');
  }
}
