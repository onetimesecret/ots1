import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_credentials.dart';

/// Auth events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check authentication status
class CheckAuthenticationEvent extends AuthEvent {}

/// Login with credentials
class LoginEvent extends AuthEvent {
  final UserCredentials credentials;

  const LoginEvent(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

/// Logout
class LogoutEvent extends AuthEvent {}

/// Validate credentials
class ValidateCredentialsEvent extends AuthEvent {
  final UserCredentials credentials;

  const ValidateCredentialsEvent(this.credentials);

  @override
  List<Object?> get props => [credentials];
}
