import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/incidents/domain/entities/maintenance_request.dart';
import 'package:orion_app/features/incidents/domain/repositories/incidents_repository.dart';

class SubmitMaintenanceRequestUseCase {
  final IncidentsRepository repository;

  SubmitMaintenanceRequestUseCase(this.repository);

  Future<Result<MaintenanceRequest>> call(MaintenanceRequest request) {
    return repository.submitMaintenanceRequest(request);
  }
}
