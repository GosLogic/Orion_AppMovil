import 'package:equatable/equatable.dart';
import 'package:orion_app/features/telemetry/domain/utils/telemetry_id_parser.dart';

enum RouteSheetStatus { draft, assigned, inProgress, completed }

/// Hoja de ruta del conductor. [status] describe la jornada (assigned/in_progress/completed),
/// distinto al [TripStop.status] de cada parada.
class RouteSheet extends Equatable {
  final String id;
  final String tenantId;
  final String driverId;
  final String? vehicleId;
  final String vehiclePlate;
  final String vehicleModel;
  final RouteSheetStatus status;
  final DateTime scheduledDate;

  /// ID numérico para telemetría (si el backend lo envía explícitamente).
  final int? numericId;

  /// ID numérico del vehículo para telemetría (si el backend lo envía).
  final int? vehicleNumericId;

  const RouteSheet({
    required this.id,
    required this.tenantId,
    required this.driverId,
    this.vehicleId,
    this.vehiclePlate = '',
    this.vehicleModel = '',
    required this.status,
    required this.scheduledDate,
    this.numericId,
    this.vehicleNumericId,
  });

  bool get isJornadaActive => status == RouteSheetStatus.inProgress;

  bool get canStartJornada =>
      status == RouteSheetStatus.assigned ||
      status == RouteSheetStatus.draft;

  bool get canEndJornada => status == RouteSheetStatus.inProgress;

  /// Entero para `vehicle_id` en POST /telemetry/vehicle-positions/batch.
  int? get telemetryVehicleId =>
      vehicleNumericId ?? tryParseOrionNumericId(vehicleId);

  /// Entero para `route_sheet_id` en POST /telemetry/vehicle-positions/batch.
  int? get telemetryRouteSheetId =>
      numericId ?? tryParseOrionNumericId(id);

  RouteSheet copyWith({
    String? id,
    String? tenantId,
    String? driverId,
    String? vehicleId,
    String? vehiclePlate,
    String? vehicleModel,
    RouteSheetStatus? status,
    DateTime? scheduledDate,
    int? numericId,
    int? vehicleNumericId,
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
      numericId: numericId ?? this.numericId,
      vehicleNumericId: vehicleNumericId ?? this.vehicleNumericId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        driverId,
        vehicleId,
        vehiclePlate,
        status,
        numericId,
        vehicleNumericId,
      ];
}
