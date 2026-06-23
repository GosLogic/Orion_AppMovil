import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:orion_app/core/constants/database_constants.dart';
import 'package:orion_app/core/database/database_helper.dart';
import 'package:orion_app/core/network/auth_token_provider.dart';

import 'package:orion_app/features/auth/data/models/driver_session_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession(DriverSessionModel session);

  Future<DriverSessionModel?> getSession();

  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource, AuthTokenProvider {
  AuthLocalDataSourceImpl({
    required DatabaseHelper databaseHelper,
    FlutterSecureStorage? secureStorage,
  })  : _databaseHelper = databaseHelper,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final DatabaseHelper _databaseHelper;
  final FlutterSecureStorage _secureStorage;

  static const _jwtKey = 'orion_jwt';
  static const _tenantIdKey = 'orion_tenant_id';

  @override
  Future<void> saveSession(DriverSessionModel session) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseConstants.driverSessionTable,
      session.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _secureStorage.write(key: _jwtKey, value: session.jwt);
    await _secureStorage.write(key: _tenantIdKey, value: session.tenantId);
  }

  @override
  Future<DriverSessionModel?> getSession() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(DatabaseConstants.driverSessionTable, limit: 1);
    if (rows.isEmpty) return null;
    return DriverSessionModel.fromLocalMap(rows.first);
  }

  @override
  Future<void> clearSession() async {
    final db = await _databaseHelper.database;
    await db.delete(DatabaseConstants.driverSessionTable);
    await _secureStorage.delete(key: _jwtKey);
    await _secureStorage.delete(key: _tenantIdKey);
  }

  @override
  Future<String?> getJwt() => _secureStorage.read(key: _jwtKey);

  @override
  Future<String?> getTenantId() => _secureStorage.read(key: _tenantIdKey);

  @override
  Future<String?> getDriverId() async {
    final session = await getSession();
    return session?.driverId;
  }

  @override
  Future<bool> hasValidSession() async {
    final session = await getSession();
    return session != null && session.isValid;
  }
}
