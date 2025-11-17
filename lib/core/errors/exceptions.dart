/// Base exception class
class AppException implements Exception {
  final String message;
  final int? code;

  const AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Server exception
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
  });

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

/// Network exception
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.code,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Authentication exception
class AuthenticationException extends AppException {
  const AuthenticationException({
    super.message = 'Authentication failed',
    super.code = 401,
  });

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Rate limit exception
class RateLimitException extends AppException {
  const RateLimitException({
    super.message = 'Rate limit exceeded',
    super.code = 429,
  });

  @override
  String toString() => 'RateLimitException: $message';
}

/// Secret not found exception
class SecretNotFoundException extends AppException {
  const SecretNotFoundException({
    super.message = 'Secret not found or already consumed',
    super.code = 404,
  });

  @override
  String toString() => 'SecretNotFoundException: $message';
}

/// Validation exception
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code = 400,
  });

  @override
  String toString() => 'ValidationException: $message';
}

/// Cache exception
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error',
    super.code,
  });

  @override
  String toString() => 'CacheException: $message';
}

/// Storage exception
class StorageException extends AppException {
  const StorageException({
    super.message = 'Storage error',
    super.code,
  });

  @override
  String toString() => 'StorageException: $message';
}

/// Certificate pinning exception
class CertificatePinningException extends AppException {
  const CertificatePinningException({
    super.message = 'Certificate validation failed',
    super.code,
  });

  @override
  String toString() => 'CertificatePinningException: $message';
}
