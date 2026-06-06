import 'package:orion_app/features/telemetry/domain/entities/vehicle_position.dart';

class VehiclePositionModel extends VehiclePosition {
  final int? id;

  const VehiclePositionModel({
    this.id,
    required super.time,
    required super.vehicleId,
    required super.latitude,
    required super.longitude,
    required super.speedKmh,
    required super.heading,
    super.routeSheetId,
    super.isMocked = false,
    super.synced = false,
  });

  factory VehiclePositionModel.fromEntity(VehiclePosition position) {
    return VehiclePositionModel(
      time: position.time,
      vehicleId: position.vehicleId,
      latitude: position.latitude,
      longitude: position.longitude,
      speedKmh: position.speedKmh,
      heading: position.heading,
      routeSheetId: position.routeSheetId,
      isMocked: position.isMocked,
      synced: position.synced,
    );
  }

  factory VehiclePositionModel.fromMap(Map<String, dynamic> map) {
    return VehiclePositionModel(
      id: map['id'] as int?,
      time: DateTime.parse(map['time'] as String),
      vehicleId: map['vehicle_id'] as int,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      speedKmh: (map['speed_kmh'] as num).toDouble(),
      heading: map['heading'] as int,
      routeSheetId: map['route_sheet_id'] as int?,
      isMocked: (map['is_mocked'] as int) == 1,
      synced: (map['synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'vehicle_id': vehicleId,
        'latitude': latitude,
        'longitude': longitude,
        'speed_kmh': speedKmh,
        'heading': heading,
        'route_sheet_id': routeSheetId,
        'is_mocked': isMocked,
        'synced': synced,
      };

  Map<String, dynamic> toMap() => {
        'time': time.toIso8601String(),
        'vehicle_id': vehicleId,
        'latitude': latitude,
        'longitude': longitude,
        'speed_kmh': speedKmh,
        'heading': heading,
        'route_sheet_id': routeSheetId,
        'is_mocked': isMocked ? 1 : 0,
        'synced': synced ? 1 : 0,
      };

  VehiclePosition toEntity() => VehiclePosition(
        time: time,
        vehicleId: vehicleId,
        latitude: latitude,
        longitude: longitude,
        speedKmh: speedKmh,
        heading: heading,
        routeSheetId: routeSheetId,
        isMocked: isMocked,
        synced: synced,
      );
}
