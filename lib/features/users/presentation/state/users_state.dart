import '../../domain/entities/user_entity.dart';

enum UsersStatus { idle, loading, success, empty, error }

class UsersState {
  const UsersState({
    required this.status,
    required this.users,
    required this.searchQuery,
    this.errorMessage,
  });

  const UsersState.initial()
    : this(
        status: UsersStatus.idle,
        users: const <UserEntity>[],
        searchQuery: '',
      );

  final UsersStatus status;
  final List<UserEntity> users;
  final String searchQuery;
  final String? errorMessage;

  UsersState copyWith({
    UsersStatus? status,
    List<UserEntity>? users,
    String? searchQuery,
    String? errorMessage,
  }) {
    return UsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}
