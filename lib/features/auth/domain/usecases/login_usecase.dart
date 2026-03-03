import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/login_input.dart';
import '../entities/session_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, SessionEntity>> execute(LoginInput input) {
    return _repository.login(input);
  }
}
