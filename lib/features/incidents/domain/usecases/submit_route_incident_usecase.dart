import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/incidents/domain/entities/route_incident.dart';
import 'package:orion_app/features/incidents/domain/repositories/incidents_repository.dart';

class SubmitRouteIncidentUseCase {
  final IncidentsRepository repository;

  SubmitRouteIncidentUseCase(this.repository);

  Future<Result<RouteIncident>> call(RouteIncident incident) {
    return repository.submitRouteIncident(incident);
  }
}
