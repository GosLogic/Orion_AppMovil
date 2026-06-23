import 'package:orion_app/core/constants/database_constants.dart';
import 'package:orion_app/core/database/database_helper.dart';
import 'package:orion_app/features/telemetry/data/models/vehicle_position_model.dart';
import 'package:orion_app/features/telemetry/domain/entities/vehicle_position.dart';

abstract class TelemetryLocalDataSource {
  Future<void> insertPosition(VehiclePosition position);

  Future<List<VehiclePositionModel>> getUnsyncedPositions({int limit = 100});

  Future<int> countUnsyncedPositions();

  Future<bool> existsPosition(int vehicleId, String timeIso);

  Future<void> markAsSynced(List<int> ids);
}

class TelemetryLocalDataSourceImpl implements TelemetryLocalDataSource {
  TelemetryLocalDataSourceImpl({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  final DatabaseHelper _databaseHelper;

  @override
  Future<void> insertPosition(VehiclePosition position) async {
    final db = await _databaseHelper.database;
    final model = VehiclePositionModel.fromEntity(position);
    final timeIso = model.toMap()['time'] as String;

    final exists = await existsPosition(position.vehicleId, timeIso);
    if (exists) return;

    await db.insert(
      DatabaseConstants.vehiclePositionsTable,
      model.toMap(),
    );
  }

  @override
  Future<bool> existsPosition(int vehicleId, String timeIso) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseConstants.vehiclePositionsTable,
      columns: ['id'],
      where: 'vehicle_id = ? AND time = ?',
      whereArgs: [vehicleId, timeIso],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<List<VehiclePositionModel>> getUnsyncedPositions({
    int limit = 100,
  }) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseConstants.vehiclePositionsTable,
      where: 'synced = 0',
      orderBy: 'time ASC',
      limit: limit,
    );
    return rows.map(VehiclePositionModel.fromMap).toList();
  }

  @override
  Future<int> countUnsyncedPositions() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM ${DatabaseConstants.vehiclePositionsTable} '
      'WHERE synced = 0',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  @override
  Future<void> markAsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _databaseHelper.database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(
        DatabaseConstants.vehiclePositionsTable,
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }
}
