import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for authentication
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<CheckAuthenticationEvent>(_onCheckAuthentication);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<ValidateCredentialsEvent>(_onValidateCredentials);
  }

  Future<void> _onCheckAuthentication(
    CheckAuthenticationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authRepository.getCredentials();

    result.fold(
      (failure) => emit(Unauthenticated()),
      (credentials) {
        if (credentials != null) {
          emit(Authenticated(credentials));
        } else {
          emit(Unauthenticated());
        }
      },
    );
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authRepository.saveCredentials(
      credentials: event.credentials,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Authenticated(event.credentials)),
    );
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authRepository.deleteCredentials();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> _onValidateCredentials(
    ValidateCredentialsEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authRepository.validateCredentials(
      credentials: event.credentials,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (isValid) {
        if (isValid) {
          emit(CredentialsValid());
          emit(Authenticated(event.credentials));
        } else {
          emit(const CredentialsInvalid('Invalid credentials'));
        }
      },
    );
  }
}
