import 'package:equatable/equatable.dart';

enum RouteIncidentType {
  traffic,
  vehicleFailure,
  clientAbsent,
  other,
}

class RouteIncident extends Equatable {
  final String id;
  final String? stopId;
  final RouteIncidentType type;
  final String description;
  final DateTime reportedAt;
  final bool isPanic;
  final double? latitude;
  final double? longitude;
  final bool synced;

  const RouteIncident({
    required this.id,
    this.stopId,
    required this.type,
    required this.description,
    required this.reportedAt,
    this.isPanic = false,
    this.latitude,
    this.longitude,
    this.synced = false,
  });

  String get typeLabel => switch (type) {
        RouteIncidentType.traffic => 'Tráfico',
        RouteIncidentType.vehicleFailure => 'Falla vehículo',
        RouteIncidentType.clientAbsent => 'Cliente ausente',
        RouteIncidentType.other => 'Otro',
      };

  @override
  List<Object?> get props => [id, stopId, type, reportedAt, isPanic];
}
