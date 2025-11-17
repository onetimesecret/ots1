import 'package:equatable/equatable.dart';

import '../../../domain/entities/secret.dart';
import '../../../domain/entities/secret_metadata.dart';

/// Secret states
abstract class SecretState extends Equatable {
  const SecretState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SecretInitial extends SecretState {}

/// Loading state
class SecretLoading extends SecretState {}

/// Secret created successfully
class SecretCreated extends SecretState {
  final Secret secret;

  const SecretCreated(this.secret);

  @override
  List<Object?> get props => [secret];
}

/// Secret revealed successfully
class SecretRevealed extends SecretState {
  final Secret secret;

  const SecretRevealed(this.secret);

  @override
  List<Object?> get props => [secret];
}

/// Secret burned successfully
class SecretBurned extends SecretState {
  final SecretMetadata metadata;

  const SecretBurned(this.metadata);

  @override
  List<Object?> get props => [metadata];
}

/// Recent secrets loaded
class RecentSecretsLoaded extends SecretState {
  final List<SecretMetadata> secrets;

  const RecentSecretsLoaded(this.secrets);

  @override
  List<Object?> get props => [secrets];
}

/// Secret error state
class SecretError extends SecretState {
  final String message;

  const SecretError(this.message);

  @override
  List<Object?> get props => [message];
}
