import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/providers.dart';
import '../../domain/entities/secret.dart';

/// Provider for creating a secret
final createSecretProvider = StateNotifierProvider.autoDispose<
    CreateSecretNotifier, AsyncValue<Secret?>>(
  (ref) => CreateSecretNotifier(ref),
);

class CreateSecretNotifier extends StateNotifier<AsyncValue<Secret?>> {
  final Ref _ref;

  CreateSecretNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> createSecret({
    required String secret,
    String? passphrase,
    int? ttl,
    String? recipient,
  }) async {
    state = const AsyncValue.loading();

    final result = await _ref.read(secretRepositoryProvider).createSecret(
          secret: secret,
          passphrase: passphrase,
          ttl: ttl,
          recipient: recipient,
        );

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (secret) => state = AsyncValue.data(secret),
    );
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for retrieving a secret
final getSecretProvider = StateNotifierProvider.autoDispose<
    GetSecretNotifier, AsyncValue<Secret?>>(
  (ref) => GetSecretNotifier(ref),
);

class GetSecretNotifier extends StateNotifier<AsyncValue<Secret?>> {
  final Ref _ref;

  GetSecretNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> getSecret({
    required String secretKey,
    String? passphrase,
  }) async {
    state = const AsyncValue.loading();

    final result = await _ref.read(secretRepositoryProvider).getSecret(
          secretKey: secretKey,
          passphrase: passphrase,
        );

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (secret) => state = AsyncValue.data(secret),
    );
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
