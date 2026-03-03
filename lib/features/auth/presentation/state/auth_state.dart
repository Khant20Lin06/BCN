import '../../domain/entities/session_entity.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({required this.status, this.session, this.errorMessage});

  const AuthState.initial() : this(status: AuthStatus.initial);

  final AuthStatus status;
  final SessionEntity? session;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    SessionEntity? session,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: errorMessage,
    );
  }
}
