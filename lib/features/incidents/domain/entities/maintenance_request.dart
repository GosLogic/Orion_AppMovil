import 'package:equatable/equatable.dart';

enum MaintenanceSeverity { low, medium, high, critical }

class MaintenanceRequest extends Equatable {
  final String id;
  final String vehicleId;
  final String description;
  final MaintenanceSeverity severity;
  final DateTime reportedAt;
  final String? photoEvidencePath;
  final bool synced;
  final String? serverStatus;

  const MaintenanceRequest({
    required this.id,
    required this.vehicleId,
    required this.description,
    required this.severity,
    required this.reportedAt,
    this.photoEvidencePath,
    this.synced = false,
    this.serverStatus,
  });

  String get severityLabel => switch (severity) {
        MaintenanceSeverity.low => 'Bajo',
        MaintenanceSeverity.medium => 'Medio',
        MaintenanceSeverity.high => 'Alto',
        MaintenanceSeverity.critical => 'Crítico',
      };

  MaintenanceRequest copyWith({
    String? id,
    String? vehicleId,
    String? description,
    MaintenanceSeverity? severity,
    DateTime? reportedAt,
    String? photoEvidencePath,
    bool? synced,
    String? serverStatus,
  }) {
    return MaintenanceRequest(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      reportedAt: reportedAt ?? this.reportedAt,
      photoEvidencePath: photoEvidencePath ?? this.photoEvidencePath,
      synced: synced ?? this.synced,
      serverStatus: serverStatus ?? this.serverStatus,
    );
  }

  @override
  List<Object?> get props =>
      [id, vehicleId, severity, reportedAt, synced, serverStatus];
}
