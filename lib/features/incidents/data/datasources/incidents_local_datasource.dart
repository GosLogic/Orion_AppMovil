import 'package:orion_app/core/constants/database_constants.dart';
import 'package:orion_app/core/database/database_helper.dart';
import 'package:orion_app/features/incidents/data/models/incident_model.dart';
import 'package:orion_app/features/incidents/data/models/maintenance_request_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class IncidentsLocalDataSource {
  Future<void> saveRouteIncident(RouteIncidentModel incident);

  Future<void> saveMaintenanceRequest(MaintenanceRequestModel request);

  Future<List<MaintenanceRequestModel>> getMaintenanceRequests();

  Future<List<MaintenanceRequestModel>> getUnsyncedMaintenanceRequests();

  Future<void> markMaintenanceSynced(String id, {String? serverStatus});
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

  @override
  Future<List<MaintenanceRequestModel>> getMaintenanceRequests() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseConstants.maintenanceRequestsTable,
      orderBy: 'created_at DESC',
    );
    return rows.map(MaintenanceRequestModel.fromLocalMap).toList();
  }

  @override
  Future<List<MaintenanceRequestModel>> getUnsyncedMaintenanceRequests() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseConstants.maintenanceRequestsTable,
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
    return rows.map(MaintenanceRequestModel.fromLocalMap).toList();
  }

  @override
  Future<void> markMaintenanceSynced(String id, {String? serverStatus}) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseConstants.maintenanceRequestsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final existing = MaintenanceRequestModel.fromLocalMap(rows.first);
    final updated = MaintenanceRequestModel(
      id: existing.id,
      vehicleId: existing.vehicleId,
      description: existing.description,
      severity: existing.severity,
      reportedAt: existing.reportedAt,
      photoEvidencePath: existing.photoEvidencePath,
      synced: true,
      serverStatus: serverStatus ?? existing.serverStatus ?? 'PENDING',
    );
    await db.update(
      DatabaseConstants.maintenanceRequestsTable,
      updated.toLocalMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
