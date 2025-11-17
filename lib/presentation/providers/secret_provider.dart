import 'package:flutter/foundation.dart';
import '../../core/di/injection_container.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/secret.dart';
import '../../domain/usecases/create_secret.dart';
import '../../domain/usecases/retrieve_secret.dart';

/// State for secret operations
enum SecretState {
  initial,
  loading,
  loaded,
  error,
}

/// Provider for managing secret operations and state
class SecretProvider extends ChangeNotifier {
  final CreateSecret _createSecret = getIt<CreateSecret>();
  final RetrieveSecret _retrieveSecret = getIt<RetrieveSecret>();

  SecretState _state = SecretState.initial;
  Secret? _currentSecret;
  String? _errorMessage;

  SecretState get state => _state;
  Secret? get currentSecret => _currentSecret;
  String? get errorMessage => _errorMessage;

  /// Creates a new secret
  Future<void> createSecret({
    required String value,
    int? ttl,
    String? passphrase,
    String? recipient,
  }) async {
    _setState(SecretState.loading);
    _errorMessage = null;

    try {
      final secret = await _createSecret(
        value: value,
        ttl: ttl,
        passphrase: passphrase,
        recipient: recipient,
      );
      _currentSecret = secret;
      _setState(SecretState.loaded);
    } on Failure catch (failure) {
      _errorMessage = failure.message;
      _setState(SecretState.error);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _setState(SecretState.error);
    }
  }

  /// Retrieves a secret by its key
  Future<void> retrieveSecret({
    required String secretKey,
    String? passphrase,
  }) async {
    _setState(SecretState.loading);
    _errorMessage = null;

    try {
      final secret = await _retrieveSecret(
        secretKey: secretKey,
        passphrase: passphrase,
      );
      _currentSecret = secret;
      _setState(SecretState.loaded);
    } on Failure catch (failure) {
      _errorMessage = failure.message;
      _setState(SecretState.error);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _setState(SecretState.error);
    }
  }

  /// Clears the current secret and resets state
  void clearSecret() {
    _currentSecret = null;
    _errorMessage = null;
    _setState(SecretState.initial);
  }

  void _setState(SecretState newState) {
    _state = newState;
    notifyListeners();
  }
}
