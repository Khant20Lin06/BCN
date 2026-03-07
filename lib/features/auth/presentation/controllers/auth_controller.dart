import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/frappe_api_client.dart';
import '../../../../core/storage/local_database.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../data/datasources/auth_local_ds.dart';
import '../../data/datasources/auth_remote_ds.dart';
import '../../data/mappers/session_mapper.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/login_input.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import '../state/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final FrappeApiClient apiClient = FrappeApiClient(
    storageService: secureStorage,
    dioFactory: DioFactory(ref.watch(appLoggerProvider)),
  );

  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(apiClient, secureStorage),
    localDataSource: AuthLocalDataSource(secureStorage),
    mapper: const SessionMapper(),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((Ref ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final getSessionUseCaseProvider = Provider<GetSessionUseCase>((Ref ref) {
  return GetSessionUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((Ref ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final requestPasswordResetUseCaseProvider =
    Provider<RequestPasswordResetUseCase>((Ref ref) {
      return RequestPasswordResetUseCase(ref.watch(authRepositoryProvider));
    });

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (Ref ref) {
    return AuthController(
      ref: ref,
      loginUseCase: ref.watch(loginUseCaseProvider),
      getSessionUseCase: ref.watch(getSessionUseCaseProvider),
      logoutUseCase: ref.watch(logoutUseCaseProvider),
      requestPasswordResetUseCase: ref.watch(
        requestPasswordResetUseCaseProvider,
      ),
    )..initialize();
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required this.ref,
    required LoginUseCase loginUseCase,
    required GetSessionUseCase getSessionUseCase,
    required LogoutUseCase logoutUseCase,
    required RequestPasswordResetUseCase requestPasswordResetUseCase,
  }) : _loginUseCase = loginUseCase,
       _getSessionUseCase = getSessionUseCase,
       _logoutUseCase = logoutUseCase,
       _requestPasswordResetUseCase = requestPasswordResetUseCase,
       super(const AuthState.initial());

  final Ref ref;
  final LoginUseCase _loginUseCase;
  final GetSessionUseCase _getSessionUseCase;
  final LogoutUseCase _logoutUseCase;
  final RequestPasswordResetUseCase _requestPasswordResetUseCase;

  Future<void> initialize() async {
    final result = await _getSessionUseCase.execute();
    state = result.fold(
      (failure) =>
          AuthState(status: AuthStatus.error, errorMessage: failure.message),
      (session) => session == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, session: session),
    );
  }

  Future<void> submitLogin({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _loginUseCase.execute(
      LoginInput(email: email, password: password),
    );

    state = result.fold(
      (failure) =>
          AuthState(status: AuthStatus.error, errorMessage: failure.message),
      (session) =>
          AuthState(status: AuthStatus.authenticated, session: session),
    );
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await _logoutUseCase.execute();

    final LocalDatabase db = ref.read(localDatabaseProvider);
    await db.clearItems();

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<Either<Failure, String>> requestPasswordReset(String email) async {
    final String normalized = email.trim();
    if (normalized.isEmpty) {
      return const Left<Failure, String>(
        ValidationFailure(message: 'Email is required'),
      );
    }

    return _requestPasswordResetUseCase.execute(normalized);
  }

  void setUnauthenticated({String? message}) {
    if (state.status == AuthStatus.unauthenticated) {
      return;
    }
    state = AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: message?.trim().isEmpty ?? true ? null : message!.trim(),
    );
  }
}
