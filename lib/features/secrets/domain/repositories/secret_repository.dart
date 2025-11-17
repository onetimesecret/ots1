import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/secret.dart';

/// Repository interface for secret operations
abstract class SecretRepository {
  /// Create a new secret
  Future<Either<Failure, Secret>> createSecret({
    required String secret,
    String? passphrase,
    int? ttl,
    String? recipient,
  });

  /// Retrieve a secret by key
  Future<Either<Failure, Secret>> getSecret({
    required String secretKey,
    String? passphrase,
  });

  /// Get secret metadata
  Future<Either<Failure, Secret>> getMetadata({
    required String metadataKey,
  });

  /// Burn a secret (delete it before it expires)
  Future<Either<Failure, void>> burnSecret({
    required String metadataKey,
  });
}
