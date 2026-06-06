import 'package:equatable/equatable.dart';

class VehiclePosition extends Equatable {
  final DateTime time;
  final int vehicleId;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final int heading;
  final int? routeSheetId;
  final bool isMocked;
  final bool synced;

  const VehiclePosition({
    required this.time,
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.heading,
    this.routeSheetId,
    this.isMocked = false,
    this.synced = false,
  });

  @override
  List<Object?> get props =>
      [time, vehicleId, latitude, longitude, speedKmh, heading, isMocked];
}
