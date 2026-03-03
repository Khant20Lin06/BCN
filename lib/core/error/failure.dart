abstract class Failure {
  const Failure({required this.message, this.code});

  final String message;
  final String? code;
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.message, super.code});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({required super.message, super.code});
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure({required super.message, super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.code});
}

class ConflictFailure extends Failure {
  const ConflictFailure({required super.message, super.code});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.code});
}
