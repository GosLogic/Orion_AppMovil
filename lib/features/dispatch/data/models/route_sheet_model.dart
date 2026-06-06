import 'dart:convert';

import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';

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
  });

  factory RouteSheetModel.fromJson(Map<String, dynamic> json) {
    return RouteSheetModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      driverId: json['driver_id'] as String,
      vehicleId: json['vehicle_id'] as String?,
      vehiclePlate: json['vehicle_plate'] as String? ?? '',
      vehicleModel: json['vehicle_model'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
    );
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
      );
}
