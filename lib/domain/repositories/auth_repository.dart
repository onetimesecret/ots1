import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_credentials.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Save user credentials securely
  Future<Either<Failure, void>> saveCredentials({
    required UserCredentials credentials,
  });

  /// Get stored user credentials
  Future<Either<Failure, UserCredentials?>> getCredentials();

  /// Delete stored credentials
  Future<Either<Failure, void>> deleteCredentials();

  /// Check if user is authenticated
  Future<Either<Failure, bool>> isAuthenticated();

  /// Validate API credentials
  Future<Either<Failure, bool>> validateCredentials({
    required UserCredentials credentials,
  });
}
