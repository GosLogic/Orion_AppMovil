class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'ORION_API_BASE_URL',
    defaultValue: 'https://api.orion.local/v1',
  );

  static const String authorizationHeader = 'Authorization';
  static const String tenantIdHeader = 'X-Tenant-Id';
  static const String bearerPrefix = 'Bearer ';

  // Auth (IAM)
  static const String login = '/auth/driver/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Dispatch
  static const String routeSheets = '/dispatch/route-sheets';
  static const String tripStops = '/dispatch/trip-stops';
  static const String deliveries = '/dispatch/deliveries';

  // Telemetry
  static const String vehiclePositions = '/telemetry/vehicle-positions';
  static const String vehiclePositionsBatch = '/telemetry/vehicle-positions/batch';

  // Incidents
  static const String incidents = '/incidents';
  static const String maintenanceRequests = '/maintenance/requests';
  static const String panic = '/incidents/panic';
}
