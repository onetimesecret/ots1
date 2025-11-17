import '../entities/secret.dart';

/// Repository interface for secret operations
/// This follows the Repository pattern and enables clean architecture
abstract class SecretRepository {
  /// Creates a new one-time secret
  ///
  /// [value] - The secret value to share
  /// [ttl] - Time to live in seconds (optional)
  /// [passphrase] - Optional passphrase to protect the secret
  /// [recipient] - Optional recipient email or identifier
  ///
  /// Returns a [Secret] with the secret key and metadata
  Future<Secret> createSecret({
    required String value,
    int? ttl,
    String? passphrase,
    String? recipient,
  });

  /// Retrieves a one-time secret
  ///
  /// [secretKey] - The key of the secret to retrieve
  /// [passphrase] - Optional passphrase if the secret is protected
  ///
  /// Returns a [Secret] with the decrypted value
  /// Note: This will burn (destroy) the secret after retrieval
  Future<Secret> retrieveSecret({
    required String secretKey,
    String? passphrase,
  });

  /// Gets the metadata of a secret without burning it
  ///
  /// [metadataKey] - The metadata key of the secret
  ///
  /// Returns a [Secret] with metadata information only
  Future<Secret> getSecretMetadata({
    required String metadataKey,
  });

  /// Generates a short, unique secret
  ///
  /// [passphrase] - Optional passphrase to protect the secret
  /// [ttl] - Time to live in seconds (optional)
  /// [recipient] - Optional recipient email or identifier
  ///
  /// Returns a [Secret] with a generated random value
  Future<Secret> generateSecret({
    String? passphrase,
    int? ttl,
    String? recipient,
  });

  /// Checks the API status
  ///
  /// Returns true if the API is accessible and working
  Future<bool> checkStatus();
}
