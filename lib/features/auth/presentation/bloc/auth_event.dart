import 'package:equatable/equatable.dart';
import 'package:orion_app/features/auth/domain/entities/auth_credentials.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final AuthCredentials credentials;

  const AuthLoginRequested(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}
