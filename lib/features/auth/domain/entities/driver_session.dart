import 'package:equatable/equatable.dart';

class DriverSession extends Equatable {
  final String driverId;
  final String tenantId;
  final String jwt;
  final DateTime expiresAt;

  const DriverSession({
    required this.driverId,
    required this.tenantId,
    required this.jwt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid => !isExpired && jwt.isNotEmpty && tenantId.isNotEmpty;

  bool expiresWithin(Duration window) {
    return expiresAt.difference(DateTime.now()) <= window;
  }

  @override
  List<Object?> get props => [driverId, tenantId, jwt, expiresAt];
}
