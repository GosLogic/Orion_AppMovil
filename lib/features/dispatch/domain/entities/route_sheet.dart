import 'package:equatable/equatable.dart';

enum RouteSheetStatus { draft, assigned, inProgress, completed }

class RouteSheet extends Equatable {
  final String id;
  final String tenantId;
  final String driverId;
  final String? vehicleId;
  final String vehiclePlate;
  final String vehicleModel;
  final RouteSheetStatus status;
  final DateTime scheduledDate;

  const RouteSheet({
    required this.id,
    required this.tenantId,
    required this.driverId,
    this.vehicleId,
    this.vehiclePlate = '',
    this.vehicleModel = '',
    required this.status,
    required this.scheduledDate,
  });

  bool get isJornadaActive => status == RouteSheetStatus.inProgress;

  bool get canStartJornada =>
      status == RouteSheetStatus.assigned ||
      status == RouteSheetStatus.draft;

  bool get canEndJornada => status == RouteSheetStatus.inProgress;

  RouteSheet copyWith({
    String? id,
    String? tenantId,
    String? driverId,
    String? vehicleId,
    String? vehiclePlate,
    String? vehicleModel,
    RouteSheetStatus? status,
    DateTime? scheduledDate,
  }) {
    return RouteSheet(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
    );
  }

  @override
  List<Object?> get props =>
      [id, tenantId, driverId, vehicleId, vehiclePlate, status];
}
