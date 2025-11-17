import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_credentials.dart';

/// Auth states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AuthInitial extends AuthState {}

/// Loading state
class AuthLoading extends AuthState {}

/// Authenticated state
class Authenticated extends AuthState {
  final UserCredentials credentials;

  const Authenticated(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

/// Unauthenticated state
class Unauthenticated extends AuthState {}

/// Authentication error state
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Credentials validation success
class CredentialsValid extends AuthState {}

/// Credentials validation failure
class CredentialsInvalid extends AuthState {
  final String message;

  const CredentialsInvalid(this.message);

  @override
  List<Object?> get props => [message];
}
