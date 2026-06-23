import 'package:equatable/equatable.dart';
import 'package:orion_app/features/incidents/domain/entities/maintenance_request.dart';
import 'package:orion_app/features/incidents/domain/entities/route_incident.dart';

abstract class IncidentsEvent extends Equatable {
  const IncidentsEvent();

  @override
  List<Object?> get props => [];
}

class SubmitRouteIncident extends IncidentsEvent {
  final RouteIncident incident;

  const SubmitRouteIncident(this.incident);

  @override
  List<Object?> get props => [incident];
}

class SubmitMaintenanceRequest extends IncidentsEvent {
  final MaintenanceRequest request;

  const SubmitMaintenanceRequest(this.request);

  @override
  List<Object?> get props => [request];
}

class TriggerPanicAlert extends IncidentsEvent {
  final double latitude;
  final double longitude;
  final String? stopId;

  const TriggerPanicAlert({
    required this.latitude,
    required this.longitude,
    this.stopId,
  });

  @override
  List<Object?> get props => [latitude, longitude, stopId];
}

class LoadMaintenanceHistory extends IncidentsEvent {
  const LoadMaintenanceHistory();
}

class SyncMaintenancePending extends IncidentsEvent {
  const SyncMaintenancePending();
}
