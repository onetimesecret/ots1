import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/providers.dart';

/// Authentication state provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<bool>>(
  (ref) => AuthStateNotifier(ref),
);

class AuthStateNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;

  AuthStateNotifier(this._ref) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = const AsyncValue.loading();

    final result = await _ref.read(authRepositoryProvider).isAuthenticated();

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (isAuthenticated) => state = AsyncValue.data(isAuthenticated),
    );
  }

  Future<void> login({
    required String apiKey,
    required String username,
  }) async {
    state = const AsyncValue.loading();

    final result = await _ref.read(authRepositoryProvider).storeCredentials(
          apiKey: apiKey,
          username: username,
        );

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) => state = const AsyncValue.data(true),
    );
  }

  Future<void> logout() async {
    final result = await _ref.read(authRepositoryProvider).logout();

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) => state = const AsyncValue.data(false),
    );
  }
}
