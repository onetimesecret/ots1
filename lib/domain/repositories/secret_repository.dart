import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/secret.dart';
import '../entities/secret_metadata.dart';

/// Repository interface for secret operations
abstract class SecretRepository {
  /// Create a new secret
  /// Returns Either<Failure, Secret> containing the created secret or a failure
  Future<Either<Failure, Secret>> createSecret({
    required String secret,
    String? passphrase,
    int? ttl,
    String? recipient,
  });

  /// Retrieve secret metadata
  /// Returns Either<Failure, SecretMetadata> containing metadata or a failure
  Future<Either<Failure, SecretMetadata>> getSecretMetadata({
    required String metadataKey,
  });

  /// Reveal/consume a secret
  /// Returns Either<Failure, Secret> containing the secret value or a failure
  Future<Either<Failure, Secret>> revealSecret({
    required String secretKey,
    String? passphrase,
  });

  /// Burn/delete a secret
  /// Returns Either<Failure, SecretMetadata> containing updated metadata or a failure
  Future<Either<Failure, SecretMetadata>> burnSecret({
    required String metadataKey,
  });

  /// Get recent secrets for the authenticated user
  /// Returns Either<Failure, List<SecretMetadata>> containing recent secrets or a failure
  Future<Either<Failure, List<SecretMetadata>>> getRecentSecrets();

  /// Generate a share link for a secret
  /// Returns Either<Failure, String> containing the share URL or a failure
  Future<Either<Failure, String>> generateShareLink({
    required String secretKey,
  });
}
