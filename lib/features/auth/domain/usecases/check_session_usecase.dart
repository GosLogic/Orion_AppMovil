import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/auth/domain/repositories/auth_repository.dart';

class CheckSessionUseCase {
  final AuthRepository repository;

  CheckSessionUseCase(this.repository);

  Future<Result<bool>> call() => repository.isSessionValid();
}
