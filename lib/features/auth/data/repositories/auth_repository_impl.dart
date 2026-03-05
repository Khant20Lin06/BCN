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
        roles: remoteSession.roles,
        permissions: remoteSession.permissions,
      );

      await _localDataSource.saveSession(session);
      return Right<Failure, SessionEntity>(session);
    } catch (error) {
      return Left<Failure, SessionEntity>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, String>> requestPasswordReset(String email) async {
    try {
      final String message = await _remoteDataSource.requestPasswordReset(
        email: email,
      );
      return Right<Failure, String>(message);
    } catch (error) {
      return Left<Failure, String>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, SessionEntity?>> getSession() async {
    try {
      final SessionEntity? session = await _localDataSource.getSession();
      if (session == null) {
        return const Right<Failure, SessionEntity?>(null);
      }

      try {
        final SessionEntity refreshed = await _remoteDataSource.refreshSession(
          session,
        );
        await _localDataSource.saveSession(refreshed);
        return Right<Failure, SessionEntity?>(refreshed);
      } catch (refreshError) {
        final Failure refreshFailure = mapExceptionToFailure(refreshError);
        if (refreshFailure is UnauthorizedFailure) {
          await _localDataSource.clearSession();
          return const Right<Failure, SessionEntity?>(null);
        }
        return Right<Failure, SessionEntity?>(session);
      }
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
