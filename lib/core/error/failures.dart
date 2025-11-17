import 'package:flutter/foundation.dart';

/// Base class for all failures in the application
@immutable
abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  String toString() => 'Failure: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => message.hashCode ^ statusCode.hashCode;
}

/// Failure related to server/API errors
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
  });
}

/// Failure related to network connectivity
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Network connection failed. Please check your internet connection.',
  });
}

/// Failure related to authentication/authorization
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed. Please check your credentials.',
    super.statusCode = 401,
  });
}

/// Failure related to validation
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.statusCode = 400,
  });
}

/// Failure related to secure storage operations
class StorageFailure extends Failure {
  const StorageFailure({
    super.message = 'Secure storage operation failed.',
  });
}

/// Failure when a resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested resource was not found.',
    super.statusCode = 404,
  });
}

/// Failure for unknown or unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred.',
  });
}
