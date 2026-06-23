import 'package:orion_app/features/telemetry/data/models/vehicle_position_model.dart';
import 'package:orion_app/features/telemetry/domain/entities/vehicle_position.dart';

/// DTO para POST /telemetry/vehicle-positions (snake_case, sin campo synced).
class VehiclePositionApiDto {
  final DateTime time;
  final int vehicleId;
  final double latitude;
  final double longitude;
  final double? speedKmh;
  final int? heading;
  final int? routeSheetId;
  final bool isMocked;

  const VehiclePositionApiDto({
    required this.time,
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    this.speedKmh,
    this.heading,
    this.routeSheetId,
    this.isMocked = false,
  });

  factory VehiclePositionApiDto.fromPosition(VehiclePosition position) {
    return VehiclePositionApiDto(
      time: position.time,
      vehicleId: position.vehicleId,
      latitude: position.latitude,
      longitude: position.longitude,
      speedKmh: position.speedKmh,
      heading: position.heading,
      routeSheetId: position.routeSheetId,
      isMocked: position.isMocked,
    );
  }

  factory VehiclePositionApiDto.fromModel(VehiclePositionModel model) {
    return VehiclePositionApiDto.fromPosition(model);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'time': formatIso8601WithOffset(time),
      'vehicle_id': vehicleId,
      'latitude': latitude,
      'longitude': longitude,
      'is_mocked': isMocked,
    };
    if (speedKmh != null) json['speed_kmh'] = speedKmh;
    if (heading != null) json['heading'] = heading;
    if (routeSheetId != null) json['route_sheet_id'] = routeSheetId;
    return json;
  }

  /// ISO-8601 con offset del dispositivo (ej. 2026-06-22T10:30:00-05:00).
  static String formatIso8601WithOffset(DateTime dateTime) {
    final local = dateTime.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final sec = local.second.toString().padLeft(2, '0');

    return '$y-$m-${d}T$h:$min:$sec$sign$hours:$minutes';
  }
}
