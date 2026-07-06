import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/auth/domain/entities/auth_credentials.dart';
import 'package:orion_app/features/auth/domain/entities/driver_session.dart';

abstract class AuthRepository {
  Future<Result<DriverSession>> login(AuthCredentials credentials);

  Future<Result<void>> logout();

  Future<Result<DriverSession?>> getActiveSession();

  Future<Result<bool>> isSessionValid();

  Future<Result<DriverSession>> refreshSession();
}
