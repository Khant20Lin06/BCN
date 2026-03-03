class SessionEntity {
  const SessionEntity({
    required this.baseUrl,
    required this.username,
    required this.cookieHeader,
  });

  final String baseUrl;
  final String username;
  final String cookieHeader;

  SessionEntity copyWith({
    String? baseUrl,
    String? username,
    String? cookieHeader,
  }) {
    return SessionEntity(
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      cookieHeader: cookieHeader ?? this.cookieHeader,
    );
  }
}
