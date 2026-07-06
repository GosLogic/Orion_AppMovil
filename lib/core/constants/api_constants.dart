import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:orion_app/core/config/dev_api_config.dart';

class ApiConstants {
  ApiConstants._();

  /// URL del API Gateway. Prioridad: `ORION_API_BASE_URL` → Android físico
  /// (IP LAN de la PC) → emulador (`10.0.2.2`) → localhost (desktop).
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('ORION_API_BASE_URL');
    if (fromEnv.isNotEmpty) return _resolveForPlatform(fromEnv);

    if (!kIsWeb && Platform.isAndroid) {
      final host = DevApiConfig.useEmulator
          ? '10.0.2.2'
          : (DevApiConfig.useAdbReverse
              ? '127.0.0.1'
              : DevApiConfig.pcLanHost);
      return 'http://$host:8080/v1';
    }

    return 'http://localhost:8080/v1';
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
    if (!kIsWeb && Platform.isAndroid) {
      final host = DevApiConfig.useEmulator
          ? '10.0.2.2'
          : (DevApiConfig.useAdbReverse
              ? '127.0.0.1'
              : DevApiConfig.pcLanHost);
      return 'http://$host:8086/v1';
    }
    return 'http://localhost:8086/v1';
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
