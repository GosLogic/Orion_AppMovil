import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/incidents/domain/entities/maintenance_request.dart';
import 'package:orion_app/features/incidents/domain/entities/route_incident.dart';

abstract class IncidentsRepository {
  Future<Result<RouteIncident>> submitRouteIncident(RouteIncident incident);

  Future<Result<MaintenanceRequest>> submitMaintenanceRequest(
    MaintenanceRequest request,
  );

  Future<Result<List<MaintenanceRequest>>> getMaintenanceHistory();

  Future<Result<int>> syncPendingMaintenance();

  Future<Result<RouteIncident>> triggerPanicAlert({
    required double latitude,
    required double longitude,
    String? stopId,
  });
}
