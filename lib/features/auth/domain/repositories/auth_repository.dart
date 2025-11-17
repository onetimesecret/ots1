import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Store API credentials
  Future<Either<Failure, void>> storeCredentials({
    required String apiKey,
    required String username,
  });

  /// Get stored API key
  Future<Either<Failure, String?>> getApiKey();

  /// Get stored username
  Future<Either<Failure, String?>> getUsername();

  /// Check if user is authenticated
  Future<Either<Failure, bool>> isAuthenticated();

  /// Clear stored credentials
  Future<Either<Failure, void>> logout();
}
