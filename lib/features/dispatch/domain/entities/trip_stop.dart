import 'package:equatable/equatable.dart';

enum TripStopStatus { pending, arrived, completed, skipped }

class TripStop extends Equatable {
  final String id;
  final String routeSheetId;
  final int sequence;
  final String address;
  final String locationName;
  final DateTime? estimatedArrival;
  final TripStopStatus status;

  const TripStop({
    required this.id,
    required this.routeSheetId,
    required this.sequence,
    required this.address,
    this.locationName = '',
    this.estimatedArrival,
    required this.status,
  });

  String get displayName =>
      locationName.isNotEmpty ? locationName : 'Parada $sequence';

  TripStop copyWith({
    String? id,
    String? routeSheetId,
    int? sequence,
    String? address,
    String? locationName,
    DateTime? estimatedArrival,
    TripStopStatus? status,
  }) {
    return TripStop(
      id: id ?? this.id,
      routeSheetId: routeSheetId ?? this.routeSheetId,
      sequence: sequence ?? this.sequence,
      address: address ?? this.address,
      locationName: locationName ?? this.locationName,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props =>
      [id, routeSheetId, sequence, estimatedArrival, status];
}
