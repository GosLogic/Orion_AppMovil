import 'package:orion_app/features/auth/domain/entities/driver_session.dart';

class DriverSessionModel extends DriverSession {
  const DriverSessionModel({
    required super.driverId,
    required super.tenantId,
    required super.jwt,
    required super.expiresAt,
  });

  factory DriverSessionModel.fromJson(Map<String, dynamic> json) {
    return DriverSessionModel(
      driverId: json['driver_id'] as String,
      tenantId: json['tenant_id'] as String,
      jwt: json['access_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  factory DriverSessionModel.fromLocalMap(Map<String, dynamic> map) {
    return DriverSessionModel(
      driverId: map['driver_id'] as String,
      tenantId: map['tenant_id'] as String,
      jwt: map['jwt'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'driver_id': driverId,
        'tenant_id': tenantId,
        'access_token': jwt,
        'expires_at': expiresAt.toIso8601String(),
      };

  Map<String, dynamic> toLocalMap() => {
        'id': 1,
        'driver_id': driverId,
        'tenant_id': tenantId,
        'jwt': jwt,
        'expires_at': expiresAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  DriverSession toEntity() => DriverSession(
        driverId: driverId,
        tenantId: tenantId,
        jwt: jwt,
        expiresAt: expiresAt,
      );
}
