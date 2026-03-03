class AppException implements Exception {
  AppException({required this.message, this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() =>
      'AppException(statusCode: $statusCode, code: $code, message: $message)';
}

class UnauthorizedException extends AppException {
  UnauthorizedException({required super.message, super.code, super.statusCode});
}

class ForbiddenException extends AppException {
  ForbiddenException({required super.message, super.code, super.statusCode});
}

class NotFoundException extends AppException {
  NotFoundException({required super.message, super.code, super.statusCode});
}

class ValidationException extends AppException {
  ValidationException({required super.message, super.code, super.statusCode});
}

class ConflictException extends AppException {
  ConflictException({required super.message, super.code, super.statusCode});
}

class ServerException extends AppException {
  ServerException({required super.message, super.code, super.statusCode});
}

class NetworkException extends AppException {
  NetworkException({required super.message, super.code, super.statusCode});
}

class TimeoutExceptionApp extends AppException {
  TimeoutExceptionApp({required super.message, super.code, super.statusCode});
}
