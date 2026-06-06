import 'package:orion_app/core/constants/database_constants.dart';
import 'package:orion_app/core/sync/sync_queue_item.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseConstants.databaseName);

    return openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.syncQueueTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        feature TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL DEFAULT 'POST',
        payload TEXT NOT NULL,
        headers TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        retry_count INTEGER NOT NULL DEFAULT 0,
        max_retries INTEGER NOT NULL DEFAULT 8,
        last_attempt_at TEXT,
        next_retry_at TEXT,
        created_at TEXT NOT NULL,
        error_message TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.driverSessionTable} (
        id INTEGER PRIMARY KEY,
        driver_id TEXT NOT NULL,
        tenant_id TEXT NOT NULL,
        jwt TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.routeSheetsTable} (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        driver_id TEXT NOT NULL,
        vehicle_id TEXT,
        status TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tripStopsTable} (
        id TEXT PRIMARY KEY,
        route_sheet_id TEXT NOT NULL,
        sequence INTEGER NOT NULL,
        address TEXT NOT NULL,
        status TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (route_sheet_id) REFERENCES ${DatabaseConstants.routeSheetsTable}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.deliveriesTable} (
        id TEXT PRIMARY KEY,
        trip_stop_id TEXT NOT NULL,
        proof_type TEXT NOT NULL,
        photo_path TEXT,
        signature_path TEXT,
        notes TEXT,
        delivered_at TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (trip_stop_id) REFERENCES ${DatabaseConstants.tripStopsTable}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.vehiclePositionsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        time TEXT NOT NULL,
        vehicle_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        speed_kmh REAL NOT NULL,
        heading INTEGER NOT NULL,
        route_sheet_id INTEGER,
        is_mocked INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.incidentsTable} (
        id TEXT PRIMARY KEY,
        incident_type TEXT NOT NULL,
        description TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        is_panic INTEGER NOT NULL DEFAULT 0,
        payload_json TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.maintenanceRequestsTable} (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        issue_type TEXT NOT NULL,
        description TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'DROP TABLE IF EXISTS ${DatabaseConstants.vehiclePositionsTable}',
      );
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.vehiclePositionsTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          time TEXT NOT NULL,
          vehicle_id INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          speed_kmh REAL NOT NULL,
          heading INTEGER NOT NULL,
          route_sheet_id INTEGER,
          is_mocked INTEGER NOT NULL DEFAULT 0,
          synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
  }

  // ── Sync Queue ──────────────────────────────────────────────────────────────

  Future<int> enqueueSyncItem(SyncQueueItem item) async {
    final db = await database;
    return db.insert(DatabaseConstants.syncQueueTable, item.toMap());
  }

  Future<List<SyncQueueItem>> getPendingSyncItems({int limit = 20}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final rows = await db.query(
      DatabaseConstants.syncQueueTable,
      where: "status IN ('pending', 'failed') AND (next_retry_at IS NULL OR next_retry_at <= ?)",
      whereArgs: [now],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map(SyncQueueItem.fromMap).toList();
  }

  Future<void> updateSyncItem(SyncQueueItem item) async {
    final db = await database;
    await db.update(
      DatabaseConstants.syncQueueTable,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteSyncItem(int id) async {
    final db = await database;
    await db.delete(
      DatabaseConstants.syncQueueTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countPendingSyncItems() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ${DatabaseConstants.syncQueueTable} WHERE status IN ('pending', 'failed')",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
