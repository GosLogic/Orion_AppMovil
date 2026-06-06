import 'dart:convert';

import 'package:orion_app/features/incidents/domain/entities/route_incident.dart';

class RouteIncidentModel extends RouteIncident {
  const RouteIncidentModel({
    required super.id,
    super.stopId,
    required super.type,
    required super.description,
    required super.reportedAt,
    super.isPanic = false,
    super.latitude,
    super.longitude,
    super.synced = false,
  });

  factory RouteIncidentModel.fromEntity(RouteIncident incident) {
    return RouteIncidentModel(
      id: incident.id,
      stopId: incident.stopId,
      type: incident.type,
      description: incident.description,
      reportedAt: incident.reportedAt,
      isPanic: incident.isPanic,
      latitude: incident.latitude,
      longitude: incident.longitude,
      synced: incident.synced,
    );
  }

  factory RouteIncidentModel.fromLocalMap(Map<String, dynamic> map) {
    final payload =
        jsonDecode(map['payload_json'] as String) as Map<String, dynamic>;
    return RouteIncidentModel.fromJson({...payload, 'id': map['id']});
  }

  factory RouteIncidentModel.fromJson(Map<String, dynamic> json) {
    return RouteIncidentModel(
      id: json['id'] as String,
      stopId: json['stop_id'] as String?,
      type: _parseType(json['type'] as String?),
      description: json['description'] as String,
      reportedAt: DateTime.parse(
        (json['reported_at'] ?? json['created_at']) as String,
      ),
      isPanic: json['is_panic'] == true || json['is_panic'] == 1,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      synced: json['synced'] == true || json['synced'] == 1,
    );
  }

  static RouteIncidentType _parseType(String? value) {
    return switch (value?.toUpperCase()) {
      'TRAFFIC' => RouteIncidentType.traffic,
      'VEHICLE_FAILURE' => RouteIncidentType.vehicleFailure,
      'CLIENT_ABSENT' => RouteIncidentType.clientAbsent,
      'OTHER' => RouteIncidentType.other,
      _ => RouteIncidentType.other,
    };
  }

  static String _typeToApi(RouteIncidentType type) {
    return switch (type) {
      RouteIncidentType.traffic => 'TRAFFIC',
      RouteIncidentType.vehicleFailure => 'VEHICLE_FAILURE',
      RouteIncidentType.clientAbsent => 'CLIENT_ABSENT',
      RouteIncidentType.other => 'OTHER',
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stop_id': stopId,
        'type': _typeToApi(type),
        'description': description,
        'reported_at': reportedAt.toIso8601String(),
        'is_panic': isPanic,
        'latitude': latitude,
        'longitude': longitude,
        'synced': synced,
      };

  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'incident_type': _typeToApi(type),
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'is_panic': isPanic ? 1 : 0,
        'payload_json': jsonEncode(toJson()),
        'synced': synced ? 1 : 0,
        'created_at': reportedAt.toIso8601String(),
      };

  RouteIncident toEntity() => RouteIncident(
        id: id,
        stopId: stopId,
        type: type,
        description: description,
        reportedAt: reportedAt,
        isPanic: isPanic,
        latitude: latitude,
        longitude: longitude,
        synced: synced,
      );
}
