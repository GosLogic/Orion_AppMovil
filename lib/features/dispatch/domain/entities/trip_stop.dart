import 'package:equatable/equatable.dart';

enum TripStopStatus { pending, arrived, completed, skipped }

class TripStop extends Equatable {
  final String id;
  final String routeSheetId;
  final int sequence;
  final String address;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final DateTime? estimatedArrival;
  final TripStopStatus status;

  const TripStop({
    required this.id,
    required this.routeSheetId,
    required this.sequence,
    required this.address,
    this.locationName = '',
    this.latitude,
    this.longitude,
    this.estimatedArrival,
    required this.status,
  });

  String get displayName =>
      locationName.isNotEmpty ? locationName : 'Parada $sequence';

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180;

  TripStop copyWith({
    String? id,
    String? routeSheetId,
    int? sequence,
    String? address,
    String? locationName,
    double? latitude,
    double? longitude,
    DateTime? estimatedArrival,
    TripStopStatus? status,
  }) {
    return TripStop(
      id: id ?? this.id,
      routeSheetId: routeSheetId ?? this.routeSheetId,
      sequence: sequence ?? this.sequence,
      address: address ?? this.address,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        routeSheetId,
        sequence,
        address,
        latitude,
        longitude,
        estimatedArrival,
        status,
      ];
}
