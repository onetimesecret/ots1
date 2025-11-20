import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code,
  });
}

/// Authentication/Authorization failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    super.message = 'Authentication failed. Please check your credentials.',
    super.code = 401,
  });
}

/// Rate limiting failures
class RateLimitFailure extends Failure {
  const RateLimitFailure({
    super.message = 'Rate limit exceeded. Please try again later.',
    super.code = 429,
  });
}

/// Secret not found or already consumed
class SecretNotFoundFailure extends Failure {
  const SecretNotFoundFailure({
    super.message = 'Secret not found or already consumed.',
    super.code = 404,
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 400,
  });
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to access local cache.',
    super.code,
  });
}

/// Storage failures
class StorageFailure extends Failure {
  const StorageFailure({
    super.message = 'Failed to access secure storage.',
    super.code,
  });
}

/// Certificate pinning failures
class CertificatePinningFailure extends Failure {
  const CertificatePinningFailure({
    super.message = 'Certificate validation failed. Connection not secure.',
    super.code,
  });
}

/// Generic/Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred.',
    super.code,
  });
}
