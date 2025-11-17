/// Base class for all exceptions in the application
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'AppException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Exception thrown when a server error occurs
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
  });
}

/// Exception thrown when a network error occurs
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network error occurred',
  });
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication failed',
    super.statusCode = 401,
  });
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode = 400,
  });
}

/// Exception thrown when secure storage operations fail
class StorageException extends AppException {
  const StorageException({
    super.message = 'Storage operation failed',
  });
}

/// Exception thrown when a resource is not found
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.statusCode = 404,
  });
}
