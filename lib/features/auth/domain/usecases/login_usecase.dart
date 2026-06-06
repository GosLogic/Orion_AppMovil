import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/auth/domain/entities/auth_credentials.dart';
import 'package:orion_app/features/auth/domain/entities/driver_session.dart';
import 'package:orion_app/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Result<DriverSession>> call(AuthCredentials credentials) {
    return repository.login(credentials);
  }
}
