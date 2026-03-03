class AuthTokenPayload {
  const AuthTokenPayload({required this.apiKey, required this.apiSecret});

  final String apiKey;
  final String apiSecret;

  String get authorizationValue => 'token $apiKey:$apiSecret';
}
