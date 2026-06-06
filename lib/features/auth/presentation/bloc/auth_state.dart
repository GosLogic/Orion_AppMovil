import 'package:equatable/equatable.dart';
import 'package:orion_app/features/auth/domain/entities/driver_session.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final DriverSession? session;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.session,
    this.errorMessage,
  });

  bool get isSessionExpired =>
      errorMessage != null &&
      errorMessage!.toLowerCase().contains('expirada');

  AuthState copyWith({
    AuthStatus? status,
    DriverSession? session,
    String? errorMessage,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, session, errorMessage];
}
