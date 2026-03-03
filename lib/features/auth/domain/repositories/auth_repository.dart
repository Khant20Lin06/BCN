import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/login_input.dart';
import '../entities/session_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, SessionEntity>> login(LoginInput input);

  Future<Either<Failure, SessionEntity?>> getSession();

  Future<Either<Failure, void>> logout();
}
