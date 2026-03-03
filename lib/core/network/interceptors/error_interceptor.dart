import 'dart:convert';

import 'package:dio/dio.dart';

import '../../error/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final dynamic rawData = err.response?.data;
    String message = _extractMessage(
      rawData,
      err.message ?? 'Unexpected request error',
    );
    String? code;

    if (rawData is Map<String, dynamic>) {
      code = rawData['exc_type'] as String?;
    }

    final int? statusCode = err.response?.statusCode;

    final AppException appException;
    if (statusCode == 401) {
      appException = UnauthorizedException(
        message: message,
        code: code,
        statusCode: statusCode,
      );
    } else if (statusCode == 403) {
      appException = ForbiddenException(
        message: message,
        code: code,
        statusCode: statusCode,
      );
    } else if (statusCode == 404) {
      appException = NotFoundException(
        message: message,
        code: code,
        statusCode: statusCode,
      );
    } else if (statusCode == 409) {
      appException = ConflictException(
        message: message,
        code: code,
        statusCode: statusCode,
      );
    } else if (statusCode != null && statusCode >= 500) {
      appException = ServerException(
        message: message,
        code: code,
        statusCode: statusCode,
      );
    } else {
      appException = AppException(
        message: message,
        code: code,
        statusCode: statusCode,
      );
    }

    handler.reject(err.copyWith(error: appException));
  }

  String _extractMessage(dynamic rawData, String fallback) {
    if (rawData is! Map<String, dynamic>) {
      return fallback;
    }

    final String? serverMessages = rawData['_server_messages'] as String?;
    if (serverMessages != null && serverMessages.isNotEmpty) {
      try {
        final List<dynamic> parsed =
            jsonDecode(serverMessages) as List<dynamic>;
        if (parsed.isNotEmpty) {
          final dynamic first = parsed.first;
          if (first is String && first.isNotEmpty) {
            final dynamic nested = jsonDecode(first);
            if (nested is Map<String, dynamic>) {
              final dynamic nestedMessage = nested['message'];
              if (nestedMessage is String && nestedMessage.isNotEmpty) {
                return nestedMessage;
              }
            }
            return first;
          }
          if (first is Map<String, dynamic>) {
            final dynamic nestedMessage = first['message'];
            if (nestedMessage is String && nestedMessage.isNotEmpty) {
              return nestedMessage;
            }
          }
        }
      } catch (_) {
        return serverMessages;
      }
    }

    final dynamic directMessage = rawData['message'];
    if (directMessage is String && directMessage.isNotEmpty) {
      return directMessage;
    }

    final dynamic exception = rawData['exception'];
    if (exception is String && exception.isNotEmpty) {
      return exception;
    }

    return fallback;
  }
}
