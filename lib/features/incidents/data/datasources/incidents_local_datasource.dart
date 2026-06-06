import 'package:orion_app/core/constants/database_constants.dart';
import 'package:orion_app/core/database/database_helper.dart';
import 'package:orion_app/features/incidents/data/models/incident_model.dart';
import 'package:orion_app/features/incidents/data/models/maintenance_request_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class IncidentsLocalDataSource {
  Future<void> saveRouteIncident(RouteIncidentModel incident);

  Future<void> saveMaintenanceRequest(MaintenanceRequestModel request);
}

class IncidentsLocalDataSourceImpl implements IncidentsLocalDataSource {
  IncidentsLocalDataSourceImpl({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  final DatabaseHelper _databaseHelper;

  @override
  Future<void> saveRouteIncident(RouteIncidentModel incident) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseConstants.incidentsTable,
      incident.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveMaintenanceRequest(MaintenanceRequestModel request) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseConstants.maintenanceRequestsTable,
      request.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
