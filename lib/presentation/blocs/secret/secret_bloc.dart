import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/burn_secret_usecase.dart';
import '../../../domain/usecases/create_secret_usecase.dart';
import '../../../domain/usecases/get_recent_secrets_usecase.dart';
import '../../../domain/usecases/reveal_secret_usecase.dart';
import 'secret_event.dart';
import 'secret_state.dart';

/// BLoC for secret management
class SecretBloc extends Bloc<SecretEvent, SecretState> {
  final CreateSecretUseCase createSecretUseCase;
  final RevealSecretUseCase revealSecretUseCase;
  final BurnSecretUseCase burnSecretUseCase;
  final GetRecentSecretsUseCase getRecentSecretsUseCase;

  SecretBloc({
    required this.createSecretUseCase,
    required this.revealSecretUseCase,
    required this.burnSecretUseCase,
    required this.getRecentSecretsUseCase,
  }) : super(SecretInitial()) {
    on<CreateSecretEvent>(_onCreateSecret);
    on<RevealSecretEvent>(_onRevealSecret);
    on<BurnSecretEvent>(_onBurnSecret);
    on<GetRecentSecretsEvent>(_onGetRecentSecrets);
    on<ResetSecretEvent>(_onResetSecret);
  }

  Future<void> _onCreateSecret(
    CreateSecretEvent event,
    Emitter<SecretState> emit,
  ) async {
    emit(SecretLoading());

    final result = await createSecretUseCase(
      secret: event.secret,
      passphrase: event.passphrase,
      ttl: event.ttl,
      recipient: event.recipient,
    );

    result.fold(
      (failure) => emit(SecretError(failure.message)),
      (secret) => emit(SecretCreated(secret)),
    );
  }

  Future<void> _onRevealSecret(
    RevealSecretEvent event,
    Emitter<SecretState> emit,
  ) async {
    emit(SecretLoading());

    final result = await revealSecretUseCase(
      secretKey: event.secretKey,
      passphrase: event.passphrase,
    );

    result.fold(
      (failure) => emit(SecretError(failure.message)),
      (secret) => emit(SecretRevealed(secret)),
    );
  }

  Future<void> _onBurnSecret(
    BurnSecretEvent event,
    Emitter<SecretState> emit,
  ) async {
    emit(SecretLoading());

    final result = await burnSecretUseCase(metadataKey: event.metadataKey);

    result.fold(
      (failure) => emit(SecretError(failure.message)),
      (metadata) => emit(SecretBurned(metadata)),
    );
  }

  Future<void> _onGetRecentSecrets(
    GetRecentSecretsEvent event,
    Emitter<SecretState> emit,
  ) async {
    emit(SecretLoading());

    final result = await getRecentSecretsUseCase();

    result.fold(
      (failure) => emit(SecretError(failure.message)),
      (secrets) => emit(RecentSecretsLoaded(secrets)),
    );
  }

  void _onResetSecret(
    ResetSecretEvent event,
    Emitter<SecretState> emit,
  ) {
    emit(SecretInitial());
  }
}
