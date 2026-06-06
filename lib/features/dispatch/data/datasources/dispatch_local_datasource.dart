import 'package:orion_app/core/constants/database_constants.dart';
import 'package:orion_app/core/database/database_helper.dart';
import 'package:orion_app/features/dispatch/data/models/delivery_model.dart';
import 'package:orion_app/features/dispatch/data/models/route_sheet_model.dart';
import 'package:orion_app/features/dispatch/data/models/trip_stop_model.dart';
import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:sqflite/sqflite.dart';

abstract class DispatchLocalDataSource {
  Future<void> seedDemoDataIfEmpty();

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
  Future<void> seedDemoDataIfEmpty() async {
    final existing = await getRouteSheets();
    if (existing.isNotEmpty) return;

    final today = DateTime.now();
    const routeId = 'route-demo-001';

    final route = RouteSheetModel(
      id: routeId,
      tenantId: 'tenant-demo',
      driverId: 'driver-demo',
      vehicleId: 'vehicle-001',
      vehiclePlate: 'ABC-1234',
      vehicleModel: 'Mercedes Sprinter 2024',
      status: RouteSheetStatus.assigned,
      scheduledDate: today,
    );

    final baseHour = DateTime(today.year, today.month, today.day, 8);
    final stops = [
      TripStopModel(
        id: 'stop-001',
        routeSheetId: routeId,
        sequence: 1,
        locationName: 'Bodega Central',
        address: 'Av. Industrial 1200, Zona Norte',
        estimatedArrival: baseHour.add(const Duration(hours: 1)),
        status: TripStopStatus.pending,
      ),
      TripStopModel(
        id: 'stop-002',
        routeSheetId: routeId,
        sequence: 2,
        locationName: 'Supermercado El Ahorro',
        address: 'Calle 5 #45-12, Centro',
        estimatedArrival: baseHour.add(const Duration(hours: 2, minutes: 30)),
        status: TripStopStatus.pending,
      ),
      TripStopModel(
        id: 'stop-003',
        routeSheetId: routeId,
        sequence: 3,
        locationName: 'Farmacia Salud Total',
        address: 'Carrera 80 #10-55, Sur',
        estimatedArrival: baseHour.add(const Duration(hours: 4)),
        status: TripStopStatus.pending,
      ),
    ];

    await saveRouteSheet(route);
    for (final stop in stops) {
      await saveTripStop(stop);
      await saveDelivery(
        DeliveryModel(
          id: 'del-${stop.id}-1',
          tripStopId: stop.id,
          customerName: 'Cliente ${stop.sequence}',
          packageDescription: 'Paquete estándar #${stop.sequence}',
        ),
      );
    }
  }

  @override
  Future<RouteSheetModel?> getDailyRouteSheet() async {
    await seedDemoDataIfEmpty();
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
