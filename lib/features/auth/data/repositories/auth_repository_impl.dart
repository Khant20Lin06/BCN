import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/login_input.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_ds.dart';
import '../datasources/auth_remote_ds.dart';
import '../dtos/login_dto.dart';
import '../mappers/session_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required SessionMapper mapper,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _mapper = mapper;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final SessionMapper _mapper;

  @override
  Future<Either<Failure, SessionEntity>> login(LoginInput input) async {
    try {
      final LoginDto dto = LoginDto(
        email: input.email.trim(),
        password: input.password,
      );

      final SessionEntity remoteSession = await _remoteDataSource
          .loginWithEmailPassword(email: dto.email, password: dto.password);

      final SessionEntity session = _mapper.fromLoginDto(
        dto: dto,
        baseUrl: remoteSession.baseUrl,
        username: remoteSession.username,
        cookieHeader: remoteSession.cookieHeader,
      );

      await _localDataSource.saveSession(session);
      return Right<Failure, SessionEntity>(session);
    } catch (error) {
      return Left<Failure, SessionEntity>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, SessionEntity?>> getSession() async {
    try {
      final SessionEntity? session = await _localDataSource.getSession();
      return Right<Failure, SessionEntity?>(session);
    } catch (error) {
      return Left<Failure, SessionEntity?>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _localDataSource.clearSession();
      return const Right<Failure, void>(null);
    } catch (error) {
      return Left<Failure, void>(mapExceptionToFailure(error));
    }
  }
}
