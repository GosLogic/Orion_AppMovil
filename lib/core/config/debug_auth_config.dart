import 'package:flutter/foundation.dart';
import 'package:orion_app/features/auth/data/models/driver_session_model.dart';
import 'package:orion_app/features/auth/domain/entities/auth_credentials.dart';

/// Credenciales de desarrollo. Solo activas cuando [kDebugMode] es true.
class DebugAuthConfig {
  DebugAuthConfig._();

  static const String demoEmail = 'conductor@empresa.com';
  static const String demoPassword = '123456';

  static bool matchesDemoCredentials(AuthCredentials credentials) {
    if (!kDebugMode) return false;
    return credentials.email.trim().toLowerCase() == demoEmail &&
        credentials.password == demoPassword;
  }

  static DriverSessionModel createDemoSession() {
    assert(kDebugMode, 'La sesión demo solo está disponible en debug');
    return DriverSessionModel(
      driverId: 'driver-demo',
      tenantId: 'tenant-demo',
      jwt: 'debug-jwt-orion-driver',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }
}
