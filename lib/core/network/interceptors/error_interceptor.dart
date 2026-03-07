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
    } else if (statusCode == 417) {
      appException = ValidationException(
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
        return _sanitizeMessage(parsed);
      }
      final String cleaned = _sanitizeMessage(normalized);
      return cleaned.isEmpty ? fallback : cleaned;
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
                return _sanitizeMessage(nestedMessage);
              }
            }
            final String cleaned = _extractFromExceptionText(first);
            if (cleaned.isNotEmpty) {
              return _sanitizeMessage(cleaned);
            }
            return _sanitizeMessage(first);
          }
          if (first is Map<String, dynamic>) {
            final String nestedMessage = _extractMessage(first, '');
            if (nestedMessage.isNotEmpty) {
              return _sanitizeMessage(nestedMessage);
            }
          }
        }
      } catch (_) {
        final String cleaned = _extractFromExceptionText(serverMessages);
        if (cleaned.isNotEmpty) {
          return _sanitizeMessage(cleaned);
        }
        return _sanitizeMessage(serverMessages);
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
      return _sanitizeMessage(excType);
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
            return _sanitizeMessage(message);
          }
        }
      }
      if (line.isNotEmpty) {
        return _sanitizeMessage(line);
      }
    }
    return '';
  }

  String _sanitizeMessage(String value) {
    String text = value.trim();
    if (text.isEmpty) {
      return '';
    }

    text = text.replaceAllMapped(
      RegExp(r'<a\b[^>]*>(.*?)</a>', caseSensitive: false, dotAll: true),
      (Match match) => ' ${match.group(1) ?? ''} ',
    );
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    text = text.replaceAll(RegExp(r'https?://[^\s"<>]+'), ' ');
    text = text.replaceAll(RegExp(r'//[^\s"<>]+'), ' ');
    text = text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return _normalizeLinkedMessage(text);
  }

  String _normalizeLinkedMessage(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return '';
    }

    final RegExp linkedPattern = RegExp(
      r'([A-Za-z0-9._@/-]+)\s+is linked with\s+([A-Za-z ]+?)\s+([A-Za-z0-9._@/-]+)',
      caseSensitive: false,
    );
    final RegExpMatch? linkedMatch = linkedPattern.firstMatch(normalized);
    if (linkedMatch != null) {
      final String source = linkedMatch.group(1)!.trim();
      final String linkedType = linkedMatch.group(2)!.trim();
      final String linkedId = linkedMatch.group(3)!.trim();
      return '$source is linked with $linkedType $linkedId. Hard delete is blocked. Remove the linked record first or use Soft Delete.';
    }

    if (normalized.toLowerCase().contains('is linked with')) {
      return '$normalized Hard delete is blocked.';
    }

    return normalized;
  }
}
