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

  const MaintenanceRequest({
    required this.id,
    required this.vehicleId,
    required this.description,
    required this.severity,
    required this.reportedAt,
    this.photoEvidencePath,
    this.synced = false,
  });

  String get severityLabel => switch (severity) {
        MaintenanceSeverity.low => 'Bajo',
        MaintenanceSeverity.medium => 'Medio',
        MaintenanceSeverity.high => 'Alto',
        MaintenanceSeverity.critical => 'Crítico',
      };

  @override
  List<Object?> get props => [id, vehicleId, severity, reportedAt];
}
