import 'dart:async';

import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.maxRetries = 3});

  final Dio _dio;
  final int maxRetries;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions requestOptions = err.requestOptions;
    final bool shouldRetry =
        requestOptions.method.toUpperCase() == 'GET' &&
        _isTransientError(err) &&
        (requestOptions.extra['retry_count'] as int? ?? 0) < maxRetries;

    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    final int currentRetry =
        (requestOptions.extra['retry_count'] as int? ?? 0) + 1;
    requestOptions.extra['retry_count'] = currentRetry;

    final int delayMs = switch (currentRetry) {
      1 => 300,
      2 => 900,
      _ => 1800,
    };

    await Future<void>.delayed(Duration(milliseconds: delayMs));

    try {
      final Response<dynamic> response = await _dio.fetch<dynamic>(
        requestOptions,
      );
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _isTransientError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return true;
    }

    final int? statusCode = error.response?.statusCode;
    if (statusCode == null) {
      return false;
    }

    return statusCode >= 500;
  }
}
