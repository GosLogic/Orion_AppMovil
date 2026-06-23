import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  /// URL del API Gateway. Prioridad: `ORION_API_BASE_URL` → Android emulador
  /// (`10.0.2.2`) → localhost (Windows/desktop).
  ///
  /// En emulador Android, `localhost` / `127.0.0.1` se reemplazan por
  /// `10.0.2.2` (alias del host desde el emulador).
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('ORION_API_BASE_URL');
    final raw = fromEnv.isNotEmpty
        ? fromEnv
        : (!kIsWeb && Platform.isAndroid)
            ? 'http://10.0.2.2:8080/v1'
            : 'http://localhost:8080/v1';
    return _resolveForPlatform(raw);
  }

  static String _resolveForPlatform(String url) {
    if (kIsWeb || !Platform.isAndroid) return url;
    return url
        .replaceFirst('://localhost', '://10.0.2.2')
        .replaceFirst('://127.0.0.1', '://10.0.2.2');
  }

  /// URL maintenance-service. Prioridad: ORION_MAINTENANCE_BASE_URL → gateway /v1.
  static String get maintenanceBaseUrl {
    const fromEnv = String.fromEnvironment('ORION_MAINTENANCE_BASE_URL');
    if (fromEnv.isNotEmpty) return _resolveForPlatform(fromEnv);
    return baseUrl;
  }

  /// URL notification-service. Prioridad: ORION_NOTIFICATION_BASE_URL → :8086/v1.
  static String get notificationBaseUrl {
    const fromEnv = String.fromEnvironment('ORION_NOTIFICATION_BASE_URL');
    if (fromEnv.isNotEmpty) return _resolveForPlatform(fromEnv);
    final host = (!kIsWeb && Platform.isAndroid)
        ? 'http://10.0.2.2:8086/v1'
        : 'http://localhost:8086/v1';
    return _resolveForPlatform(host);
  }
  static const String authorizationHeader = 'Authorization';
  static const String tenantIdHeader = 'X-Tenant-Id';
  static const String driverIdHeader = 'X-Driver-Id';
  static const String bearerPrefix = 'Bearer ';

  // Auth (IAM)
  static const String login = '/auth/driver/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Dispatch
  static const String routeSheets = '/dispatch/route-sheets';
  static const String tripStops = '/dispatch/trip-stops';
  static const String deliveries = '/dispatch/deliveries';

  // Telemetry (prefijo /v1 incluido en baseUrl)
  static const String vehiclePositions = '/telemetry/vehicle-positions';
  static const String vehiclePositionsBatch =
      '/telemetry/vehicle-positions/batch';
  static const String vehiclePositionsLatest =
      '/telemetry/vehicle-positions/latest';

  // Incidents
  static const String incidents = '/incidents';
  static const String maintenanceRequests = '/maintenance/requests';
  static const String panic = '/incidents/panic';

  // Notifications (orion-notification-service, puerto 8086)
  static const String notifications = '/notification';
  static const String notificationDispatch = '/notification/dispatch';
}
