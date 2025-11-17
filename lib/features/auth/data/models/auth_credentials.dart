/// Model for authentication credentials
class AuthCredentials {
  final String apiKey;
  final String username;

  const AuthCredentials({
    required this.apiKey,
    required this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      'api_key': apiKey,
      'username': username,
    };
  }

  factory AuthCredentials.fromJson(Map<String, dynamic> json) {
    return AuthCredentials(
      apiKey: json['api_key'] as String,
      username: json['username'] as String,
    );
  }
}
