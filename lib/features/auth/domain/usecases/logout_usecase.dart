import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, void>> execute() {
    return _repository.logout();
  }
}
