import '../entities/secret.dart';
import '../repositories/secret_repository.dart';

/// Use case for retrieving a one-time secret
class RetrieveSecret {
  final SecretRepository repository;

  RetrieveSecret(this.repository);

  /// Executes the use case to retrieve a secret
  ///
  /// [secretKey] - The key of the secret to retrieve
  /// [passphrase] - Optional passphrase if the secret is protected
  ///
  /// Returns a [Secret] with the decrypted value
  /// Note: This will burn (destroy) the secret after retrieval
  Future<Secret> call({
    required String secretKey,
    String? passphrase,
  }) {
    return repository.retrieveSecret(
      secretKey: secretKey,
      passphrase: passphrase,
    );
  }
}
