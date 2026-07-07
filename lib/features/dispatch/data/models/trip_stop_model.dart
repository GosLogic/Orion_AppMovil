import 'dart:convert';

import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';

class TripStopModel extends TripStop {
  const TripStopModel({
    required super.id,
    required super.routeSheetId,
    required super.sequence,
    required super.address,
    super.locationName = '',
    super.latitude,
    super.longitude,
    super.estimatedArrival,
    required super.status,
  });

  factory TripStopModel.fromJson(Map<String, dynamic> json) {
    return TripStopModel(
      id: json['id'] as String,
      routeSheetId: json['route_sheet_id'] as String,
      sequence: json['sequence'] as int? ?? json['stop_order'] as int? ?? 0,
      address: json['address'] as String,
      locationName: json['location_name'] as String? ?? '',
      latitude: _parseCoord(json['latitude'] ?? json['lat']),
      longitude: _parseCoord(json['longitude'] ?? json['lng']),
      estimatedArrival: json['estimated_arrival'] != null
          ? DateTime.parse(json['estimated_arrival'] as String)
          : null,
      status: _parseStatus(json['status'] as String?),
    );
  }

  factory TripStopModel.fromEntity(TripStop stop) {
    return TripStopModel(
      id: stop.id,
      routeSheetId: stop.routeSheetId,
      sequence: stop.sequence,
      address: stop.address,
      locationName: stop.locationName,
      latitude: stop.latitude,
      longitude: stop.longitude,
      estimatedArrival: stop.estimatedArrival,
      status: stop.status,
    );
  }

  factory TripStopModel.fromLocalMap(Map<String, dynamic> map) {
    final payload =
        jsonDecode(map['payload_json'] as String) as Map<String, dynamic>;
    return TripStopModel.fromJson({...payload, 'id': map['id']});
  }

  static TripStopStatus _parseStatus(String? value) {
    return switch (value?.toLowerCase()) {
      'pending' => TripStopStatus.pending,
      'arrived' => TripStopStatus.arrived,
      'completed' => TripStopStatus.completed,
      'skipped' => TripStopStatus.skipped,
      _ => TripStopStatus.pending,
    };
  }

  static double? _parseCoord(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'route_sheet_id': routeSheetId,
        'sequence': sequence,
        'stop_order': sequence,
        'address': address,
        'location_name': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'estimated_arrival': estimatedArrival?.toIso8601String(),
        'status': status.name.toUpperCase(),
      };

  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'route_sheet_id': routeSheetId,
        'sequence': sequence,
        'address': address,
        'status': status.name,
        'payload_json': jsonEncode(toJson()),
        'synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

  TripStop toEntity() => TripStop(
        id: id,
        routeSheetId: routeSheetId,
        sequence: sequence,
        address: address,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        estimatedArrival: estimatedArrival,
        status: status,
      );
}
