import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/incidents/domain/entities/maintenance_request.dart';
import 'package:orion_app/features/incidents/domain/repositories/incidents_repository.dart';

class GetMaintenanceHistoryUseCase {
  GetMaintenanceHistoryUseCase(this._repository);

  final IncidentsRepository _repository;

  Future<Result<List<MaintenanceRequest>>> call() {
    return _repository.getMaintenanceHistory();
  }
}
