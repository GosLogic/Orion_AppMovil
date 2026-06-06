import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/incidents/domain/entities/route_incident.dart';
import 'package:orion_app/features/incidents/domain/repositories/incidents_repository.dart';

class TriggerPanicAlertUseCase {
  final IncidentsRepository repository;

  TriggerPanicAlertUseCase(this.repository);

  Future<Result<RouteIncident>> call({
    required double latitude,
    required double longitude,
    String? stopId,
  }) {
    return repository.triggerPanicAlert(
      latitude: latitude,
      longitude: longitude,
      stopId: stopId,
    );
  }
}
