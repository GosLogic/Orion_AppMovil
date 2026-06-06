import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/error/failures.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/auth/domain/usecases/check_session_usecase.dart';
import 'package:orion_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:orion_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required CheckSessionUseCase checkSessionUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _checkSessionUseCase = checkSessionUseCase,
        super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);
  }

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckSessionUseCase _checkSessionUseCase;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final sessionResult = await _checkSessionUseCase();
    switch (sessionResult) {
      case Success(value: final isValid):
        if (isValid) {
          emit(
            state.copyWith(
              status: AuthStatus.authenticated,
              clearError: true,
            ),
          );
        } else {
          emit(
            const AuthState(status: AuthStatus.unauthenticated),
          );
        }
      case Error(failure: final failure):
        if (failure is SessionExpiredFailure) {
          emit(
            const AuthState(
              status: AuthStatus.unauthenticated,
              errorMessage:
                  'Tu sesión ha expirado. Inicia jornada nuevamente.',
            ),
          );
        } else {
          emit(
            AuthState(
              status: AuthStatus.unauthenticated,
              errorMessage: failure.message,
            ),
          );
        }
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      ),
    );

    final result = await _loginUseCase(event.credentials);
    switch (result) {
      case Success(value: final session):
        emit(
          AuthState(
            status: AuthStatus.authenticated,
            session: session,
          ),
        );
      case Error(failure: final failure):
        final message = failure is AuthFailure
            ? 'Credenciales incorrectas. Verifica tu correo y contraseña.'
            : failure.message;
        emit(
          AuthState(
            status: AuthStatus.error,
            errorMessage: message,
          ),
        );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(
      const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Tu sesión ha expirado. Inicia jornada nuevamente.',
      ),
    );
  }
}
