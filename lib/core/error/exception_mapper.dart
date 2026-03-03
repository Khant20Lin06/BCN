import 'package:dio/dio.dart';

import 'app_exception.dart';
import 'failure.dart';

Failure mapExceptionToFailure(Object error) {
  if (error is Failure) {
    return error;
  }

  if (error is DioException) {
    final Object? sourceError = error.error;
    if (sourceError is AppException) {
      return mapExceptionToFailure(sourceError);
    }
    return _mapDioException(error);
  }

  if (error is TimeoutExceptionApp) {
    return TimeoutFailure(message: error.message, code: error.code);
  }

  if (error is UnauthorizedException) {
    return UnauthorizedFailure(message: error.message, code: error.code);
  }

  if (error is ForbiddenException) {
    return ForbiddenFailure(message: error.message, code: error.code);
  }

  if (error is ValidationException) {
    return ValidationFailure(message: error.message, code: error.code);
  }

  if (error is NotFoundException) {
    return NotFoundFailure(message: error.message, code: error.code);
  }

  if (error is ConflictException) {
    return ConflictFailure(message: error.message, code: error.code);
  }

  if (error is ServerException) {
    return ServerFailure(message: error.message, code: error.code);
  }

  if (error is NetworkException) {
    return NetworkFailure(message: error.message, code: error.code);
  }

  if (error is AppException) {
    return UnknownFailure(message: error.message, code: error.code);
  }

  return UnknownFailure(message: error.toString());
}

Failure _mapDioException(DioException error) {
  final int? status = error.response?.statusCode;

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return const TimeoutFailure(message: 'Request timeout');
  }

  if (error.type == DioExceptionType.connectionError) {
    return const NetworkFailure(message: 'Network connection error');
  }

  if (status == 401) {
    return const UnauthorizedFailure(message: 'Unauthorized');
  }

  if (status == 403) {
    return const ForbiddenFailure(message: 'Forbidden');
  }

  if (status == 404) {
    return const NotFoundFailure(message: 'Resource not found');
  }

  if (status == 409) {
    return const ConflictFailure(message: 'Conflict');
  }

  if (status != null && status >= 500) {
    return const ServerFailure(message: 'Server error');
  }

  return UnknownFailure(message: error.message ?? 'Unexpected network error');
}
