import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error del servidor']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error de almacenamiento local']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión a red']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Error de autenticación']);
}

class SyncFailure extends Failure {
  const SyncFailure([super.message = 'Error de sincronización']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Datos inválidos']);
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.message = 'Sesión expirada']);
}
