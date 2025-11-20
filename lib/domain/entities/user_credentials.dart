import 'package:equatable/equatable.dart';

/// Domain entity representing user credentials for API authentication
class UserCredentials extends Equatable {
  final String username;
  final String apiKey;

  const UserCredentials({
    required this.username,
    required this.apiKey,
  });

  /// Get Basic Auth token
  String get basicAuthToken {
    final credentials = '$username:$apiKey';
    return credentials;
  }

  @override
  List<Object?> get props => [username, apiKey];
}
