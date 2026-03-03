import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/session_entity.dart';
import '../repositories/auth_repository.dart';

class GetSessionUseCase {
  const GetSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, SessionEntity?>> execute() {
    return _repository.getSession();
  }
}
