import 'dart:convert';

import 'package:orion_app/features/incidents/domain/entities/maintenance_request.dart';

class MaintenanceRequestModel extends MaintenanceRequest {
  const MaintenanceRequestModel({
    required super.id,
    required super.vehicleId,
    required super.description,
    required super.severity,
    required super.reportedAt,
    super.photoEvidencePath,
    super.synced = false,
  });

  factory MaintenanceRequestModel.fromEntity(MaintenanceRequest request) {
    return MaintenanceRequestModel(
      id: request.id,
      vehicleId: request.vehicleId,
      description: request.description,
      severity: request.severity,
      reportedAt: request.reportedAt,
      photoEvidencePath: request.photoEvidencePath,
      synced: request.synced,
    );
  }

  factory MaintenanceRequestModel.fromLocalMap(Map<String, dynamic> map) {
    final payload =
        jsonDecode(map['payload_json'] as String) as Map<String, dynamic>;
    return MaintenanceRequestModel.fromJson({...payload, 'id': map['id']});
  }

  factory MaintenanceRequestModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequestModel(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      description: json['description'] as String,
      severity: _parseSeverity(json['severity'] as String?),
      reportedAt: DateTime.parse(
        (json['reported_at'] ?? json['created_at']) as String,
      ),
      photoEvidencePath: json['photo_evidence_path'] as String?,
      synced: json['synced'] == true || json['synced'] == 1,
    );
  }

  static MaintenanceSeverity _parseSeverity(String? value) {
    return switch (value?.toUpperCase()) {
      'LOW' => MaintenanceSeverity.low,
      'MEDIUM' => MaintenanceSeverity.medium,
      'HIGH' => MaintenanceSeverity.high,
      'CRITICAL' => MaintenanceSeverity.critical,
      _ => MaintenanceSeverity.medium,
    };
  }

  static String _severityToApi(MaintenanceSeverity severity) {
    return switch (severity) {
      MaintenanceSeverity.low => 'LOW',
      MaintenanceSeverity.medium => 'MEDIUM',
      MaintenanceSeverity.high => 'HIGH',
      MaintenanceSeverity.critical => 'CRITICAL',
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicle_id': vehicleId,
        'description': description,
        'severity': _severityToApi(severity),
        'reported_at': reportedAt.toIso8601String(),
        'photo_evidence_path': photoEvidencePath,
        'synced': synced,
      };

  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'issue_type': _severityToApi(severity),
        'description': description,
        'payload_json': jsonEncode(toJson()),
        'synced': synced ? 1 : 0,
        'created_at': reportedAt.toIso8601String(),
      };

  MaintenanceRequest toEntity() => MaintenanceRequest(
        id: id,
        vehicleId: vehicleId,
        description: description,
        severity: severity,
        reportedAt: reportedAt,
        photoEvidencePath: photoEvidencePath,
        synced: synced,
      );
}
