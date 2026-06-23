import 'package:orion_app/core/constants/database_constants.dart';
import 'package:orion_app/core/database/database_helper.dart';
import 'package:orion_app/features/dispatch/data/models/delivery_model.dart';
import 'package:orion_app/features/dispatch/data/models/route_sheet_model.dart';

import 'package:orion_app/features/dispatch/data/models/trip_stop_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class DispatchLocalDataSource {
  /// Borra ruta, paradas y entregas (p. ej. conductor sin hoja asignada).
  Future<void> clearDispatchData();

  /// Borra solo ruta y paradas; conserva entregas locales (POD offline).
  Future<void> clearRouteAndStops();

  Future<RouteSheetModel?> getDailyRouteSheet();

  Future<List<RouteSheetModel>> getRouteSheets();

  Future<List<TripStopModel>> getTripStops(String routeSheetId);

  Future<List<DeliveryModel>> getDeliveries(String tripStopId);

  Future<void> saveRouteSheet(RouteSheetModel sheet);

  Future<void> saveTripStop(TripStopModel stop);

  Future<void> saveDelivery(DeliveryModel delivery);
}

class DispatchLocalDataSourceImpl implements DispatchLocalDataSource {
  DispatchLocalDataSourceImpl({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  final DatabaseHelper _databaseHelper;

  @override
  Future<void> clearDispatchData() async {
    await clearRouteAndStops();
    final db = await _databaseHelper.database;
    await db.delete(DatabaseConstants.deliveriesTable);
  }

  @override
  Future<void> clearRouteAndStops() async {
    final db = await _databaseHelper.database;
    await db.delete(DatabaseConstants.tripStopsTable);
    await db.delete(DatabaseConstants.routeSheetsTable);
  }

  @override
  Future<RouteSheetModel?> getDailyRouteSheet() async {
    final sheets = await getRouteSheets();
    if (sheets.isEmpty) return null;

    final today = DateTime.now();
    final todaySheets = sheets.where((s) {
      return s.scheduledDate.year == today.year &&
          s.scheduledDate.month == today.month &&
          s.scheduledDate.day == today.day;
    }).toList();

    return todaySheets.isNotEmpty ? todaySheets.first : sheets.first;
  }

  @override
  Future<List<RouteSheetModel>> getRouteSheets() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(DatabaseConstants.routeSheetsTable);
    return rows.map(RouteSheetModel.fromLocalMap).toList();
  }

  @override
  Future<List<TripStopModel>> getTripStops(String routeSheetId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseConstants.tripStopsTable,
      where: 'route_sheet_id = ?',
      whereArgs: [routeSheetId],
      orderBy: 'sequence ASC',
    );
    return rows.map(TripStopModel.fromLocalMap).toList();
  }

  @override
  Future<List<DeliveryModel>> getDeliveries(String tripStopId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseConstants.deliveriesTable,
      where: 'trip_stop_id = ?',
      whereArgs: [tripStopId],
    );
    return rows.map(DeliveryModel.fromLocalMap).toList();
  }

  @override
  Future<void> saveRouteSheet(RouteSheetModel sheet) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseConstants.routeSheetsTable,
      sheet.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveTripStop(TripStopModel stop) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseConstants.tripStopsTable,
      stop.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveDelivery(DeliveryModel delivery) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseConstants.deliveriesTable,
      delivery.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
