class DatabaseConstants {
  DatabaseConstants._();

  static const String databaseName = 'orion_driver.db';
  static const int databaseVersion = 2;

  // Tablas compartidas
  static const String syncQueueTable = 'sync_queue';

  // Auth / IAM
  static const String driverSessionTable = 'driver_session';

  // Dispatch
  static const String routeSheetsTable = 'route_sheets';
  static const String tripStopsTable = 'trip_stops';
  static const String deliveriesTable = 'deliveries';

  // Telemetry
  static const String vehiclePositionsTable = 'vehicle_positions';

  // Incidents
  static const String incidentsTable = 'incidents';
  static const String maintenanceRequestsTable = 'maintenance_requests';
}
