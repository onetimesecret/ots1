import '../entities/secret.dart';
import '../repositories/secret_repository.dart';

/// Use case for creating a one-time secret
class CreateSecret {
  final SecretRepository repository;

  CreateSecret(this.repository);

  /// Executes the use case to create a secret
  ///
  /// [value] - The secret value to share
  /// [ttl] - Time to live in seconds (optional)
  /// [passphrase] - Optional passphrase to protect the secret
  /// [recipient] - Optional recipient email or identifier
  ///
  /// Returns a [Secret] with the secret key and metadata
  Future<Secret> call({
    required String value,
    int? ttl,
    String? passphrase,
    String? recipient,
  }) {
    return repository.createSecret(
      value: value,
      ttl: ttl,
      passphrase: passphrase,
      recipient: recipient,
    );
  }
}
