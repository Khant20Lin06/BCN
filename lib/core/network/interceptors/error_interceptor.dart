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
    final dynamic normalized = _normalizePayload(rawData);

    if (normalized is String) {
      final String parsed = _extractFromExceptionText(normalized);
      if (parsed.isNotEmpty) {
        return parsed;
      }
      return normalized.trim().isEmpty ? fallback : normalized.trim();
    }

    if (normalized is List<dynamic>) {
      for (final dynamic entry in normalized) {
        final String parsed = _extractMessage(entry, '');
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
      return fallback;
    }

    if (normalized is! Map<String, dynamic>) {
      return fallback;
    }

    final String? serverMessages = normalized['_server_messages'] as String?;
    if (serverMessages != null && serverMessages.isNotEmpty) {
      try {
        final List<dynamic> parsed =
            jsonDecode(serverMessages) as List<dynamic>;
        if (parsed.isNotEmpty) {
          final dynamic first = parsed.first;
          if (first is String && first.isNotEmpty) {
            final dynamic nested = jsonDecode(first);
            if (nested is Map<String, dynamic>) {
              final String nestedMessage = _extractMessage(nested, '');
              if (nestedMessage.isNotEmpty) {
                return nestedMessage;
              }
            }
            final String cleaned = _extractFromExceptionText(first);
            if (cleaned.isNotEmpty) {
              return cleaned;
            }
            return first.trim();
          }
          if (first is Map<String, dynamic>) {
            final String nestedMessage = _extractMessage(first, '');
            if (nestedMessage.isNotEmpty) {
              return nestedMessage;
            }
          }
        }
      } catch (_) {
        final String cleaned = _extractFromExceptionText(serverMessages);
        if (cleaned.isNotEmpty) {
          return cleaned;
        }
        return serverMessages.trim();
      }
    }

    final String directMessage = _extractMessage(normalized['message'], '');
    if (directMessage.isNotEmpty) {
      return directMessage;
    }

    final String exceptionText = _extractMessage(normalized['exception'], '');
    if (exceptionText.isNotEmpty) {
      return exceptionText;
    }

    final String dataText = _extractMessage(normalized['data'], '');
    if (dataText.isNotEmpty) {
      return dataText;
    }

    final String excType = (normalized['exc_type'] as String? ?? '').trim();
    if (excType.isNotEmpty) {
      return excType;
    }

    return fallback;
  }

  dynamic _normalizePayload(dynamic rawData) {
    if (rawData is String) {
      final String trimmed = rawData.trim();
      if (trimmed.isEmpty) {
        return trimmed;
      }
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return trimmed;
      }
    }
    return rawData;
  }

  String _extractFromExceptionText(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final List<String> lines = trimmed
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      return '';
    }

    for (int i = lines.length - 1; i >= 0; i--) {
      final String line = lines[i];
      if (line.startsWith('Traceback')) {
        continue;
      }
      if (line.startsWith('File ')) {
        continue;
      }
      if (line.contains(':')) {
        final List<String> parts = line.split(':');
        if (parts.length >= 2) {
          final String message = parts.sublist(1).join(':').trim();
          if (message.isNotEmpty) {
            return message;
          }
        }
      }
      if (line.isNotEmpty) {
        return line;
      }
    }
    return '';
  }
}
