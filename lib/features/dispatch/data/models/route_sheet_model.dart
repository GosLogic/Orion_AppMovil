import 'dart:convert';

import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';
import 'package:orion_app/features/telemetry/domain/utils/telemetry_id_parser.dart';

class RouteSheetModel extends RouteSheet {
  const RouteSheetModel({
    required super.id,
    required super.tenantId,
    required super.driverId,
    super.vehicleId,
    super.vehiclePlate = '',
    super.vehicleModel = '',
    required super.status,
    required super.scheduledDate,
    super.numericId,
    super.vehicleNumericId,
  });

  factory RouteSheetModel.fromJson(Map<String, dynamic> json) {
    return RouteSheetModel(
      id: _externalId(json['id']) ?? '',
      tenantId: _externalId(json['tenant_id']) ?? '',
      driverId: _externalId(json['driver_id']) ?? '',
      vehicleId: _externalId(json['vehicle_id']),
      vehiclePlate: json['vehicle_plate'] as String? ?? '',
      vehicleModel: json['vehicle_model'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      numericId: tryParseOrionNumericId(json['numeric_id']) ??
          tryParseOrionNumericId(json['route_sheet_numeric_id']) ??
          tryParseOrionNumericId(json['id']),
      vehicleNumericId: tryParseOrionNumericId(json['vehicle_numeric_id']) ??
          tryParseOrionNumericId(json['vehicle_id']),
    );
  }

  static String? _externalId(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  factory RouteSheetModel.fromEntity(RouteSheet sheet) {
    return RouteSheetModel(
      id: sheet.id,
      tenantId: sheet.tenantId,
      driverId: sheet.driverId,
      vehicleId: sheet.vehicleId,
      vehiclePlate: sheet.vehiclePlate,
      vehicleModel: sheet.vehicleModel,
      status: sheet.status,
      scheduledDate: sheet.scheduledDate,
      numericId: sheet.numericId,
      vehicleNumericId: sheet.vehicleNumericId,
    );
  }

  factory RouteSheetModel.fromLocalMap(Map<String, dynamic> map) {
    final payload =
        jsonDecode(map['payload_json'] as String) as Map<String, dynamic>;
    return RouteSheetModel.fromJson({...payload, 'id': map['id']});
  }

  static RouteSheetStatus _parseStatus(String? value) {
    return switch (value?.toLowerCase()) {
      'draft' => RouteSheetStatus.draft,
      'assigned' => RouteSheetStatus.assigned,
      'in_progress' || 'inprogress' => RouteSheetStatus.inProgress,
      'completed' => RouteSheetStatus.completed,
      _ => RouteSheetStatus.assigned,
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'vehicle_plate': vehiclePlate,
        'vehicle_model': vehicleModel,
        'status': _statusToJson(status),
        'scheduled_date': scheduledDate.toIso8601String(),
      };

  static String _statusToJson(RouteSheetStatus status) {
    return switch (status) {
      RouteSheetStatus.draft => 'draft',
      RouteSheetStatus.assigned => 'assigned',
      RouteSheetStatus.inProgress => 'in_progress',
      RouteSheetStatus.completed => 'completed',
    };
  }

  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'tenant_id': tenantId,
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'status': _statusToJson(status),
        'scheduled_date': scheduledDate.toIso8601String(),
        'payload_json': jsonEncode(toJson()),
        'synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

  RouteSheet toEntity() => RouteSheet(
        id: id,
        tenantId: tenantId,
        driverId: driverId,
        vehicleId: vehicleId,
        vehiclePlate: vehiclePlate,
        vehicleModel: vehicleModel,
        status: status,
        scheduledDate: scheduledDate,
        numericId: numericId,
        vehicleNumericId: vehicleNumericId,
      );
}
