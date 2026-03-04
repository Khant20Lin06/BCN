import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, String>> execute(String email) {
    return _repository.requestPasswordReset(email);
  }
}
