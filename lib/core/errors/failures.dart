import 'package:equatable/equatable.dart';

/// Base failure class for handling errors in the domain layer
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
  });
}

class ApiFailure extends Failure {
  final int? statusCode;

  const ApiFailure({
    required super.message,
    this.statusCode,
    super.code,
  });

  @override
  List<Object?> get props => [message, code, statusCode];
}

class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });
}

class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code,
  });
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
    super.code,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

class SecurityFailure extends Failure {
  const SecurityFailure({
    required super.message,
    super.code,
  });
}
