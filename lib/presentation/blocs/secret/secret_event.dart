import 'package:equatable/equatable.dart';

/// Secret events
abstract class SecretEvent extends Equatable {
  const SecretEvent();

  @override
  List<Object?> get props => [];
}

/// Create a new secret
class CreateSecretEvent extends SecretEvent {
  final String secret;
  final String? passphrase;
  final int? ttl;
  final String? recipient;

  const CreateSecretEvent({
    required this.secret,
    this.passphrase,
    this.ttl,
    this.recipient,
  });

  @override
  List<Object?> get props => [secret, passphrase, ttl, recipient];
}

/// Reveal/consume a secret
class RevealSecretEvent extends SecretEvent {
  final String secretKey;
  final String? passphrase;

  const RevealSecretEvent({
    required this.secretKey,
    this.passphrase,
  });

  @override
  List<Object?> get props => [secretKey, passphrase];
}

/// Burn/delete a secret
class BurnSecretEvent extends SecretEvent {
  final String metadataKey;

  const BurnSecretEvent(this.metadataKey);

  @override
  List<Object?> get props => [metadataKey];
}

/// Get recent secrets
class GetRecentSecretsEvent extends SecretEvent {}

/// Reset secret state
class ResetSecretEvent extends SecretEvent {}
