import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/frappe_api_client.dart';
import '../../../../core/storage/local_database.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/auth_local_ds.dart';
import '../../data/datasources/auth_remote_ds.dart';
import '../../data/mappers/session_mapper.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/login_input.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../state/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  final FrappeApiClient apiClient = FrappeApiClient(
    storageService: ref.watch(secureStorageServiceProvider),
    dioFactory: DioFactory(ref.watch(appLoggerProvider)),
  );

  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(apiClient),
    localDataSource: AuthLocalDataSource(
      ref.watch(secureStorageServiceProvider),
    ),
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

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (Ref ref) {
    return AuthController(
      ref: ref,
      loginUseCase: ref.watch(loginUseCaseProvider),
      getSessionUseCase: ref.watch(getSessionUseCaseProvider),
      logoutUseCase: ref.watch(logoutUseCaseProvider),
    )..initialize();
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required this.ref,
    required LoginUseCase loginUseCase,
    required GetSessionUseCase getSessionUseCase,
    required LogoutUseCase logoutUseCase,
  }) : _loginUseCase = loginUseCase,
       _getSessionUseCase = getSessionUseCase,
       _logoutUseCase = logoutUseCase,
       super(const AuthState.initial());

  final Ref ref;
  final LoginUseCase _loginUseCase;
  final GetSessionUseCase _getSessionUseCase;
  final LogoutUseCase _logoutUseCase;

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
}
