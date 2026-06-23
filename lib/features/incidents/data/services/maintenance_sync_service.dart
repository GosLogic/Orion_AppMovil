import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orion_app/features/incidents/data/datasources/incidents_local_datasource.dart';
import 'package:orion_app/features/incidents/data/datasources/maintenance_remote_datasource.dart';
import 'package:orion_app/features/incidents/data/utils/maintenance_error_mapper.dart';

/// Reenvía solicitudes de mantenimiento con synced=0 (mismo id, idempotente).
class MaintenanceSyncService {
  MaintenanceSyncService({
    required IncidentsLocalDataSource localDataSource,
    required MaintenanceRemoteDataSource remoteDataSource,
    Connectivity? connectivity,
    Duration syncInterval = const Duration(minutes: 1),
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _connectivity = connectivity ?? Connectivity(),
        _syncInterval = syncInterval;

  final IncidentsLocalDataSource _localDataSource;
  final MaintenanceRemoteDataSource _remoteDataSource;
  final Connectivity _connectivity;
  final Duration _syncInterval;
  final Random _random = Random();

  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isActive = false;

  void start() {
    if (_isActive) return;
    _isActive = true;
    _timer = Timer.periodic(_syncInterval, (_) => unawaited(syncPending()));
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        if (results.any((r) => r != ConnectivityResult.none)) {
          unawaited(syncPending());
        }
      },
    );
    unawaited(syncPending());
  }

  Future<void> stop() async {
    _isActive = false;
    _timer?.cancel();
    await _connectivitySubscription?.cancel();
    await syncPending(force: true);
  }

  Future<int> syncPending({bool force = false}) async {
    if (!_isActive && !force) return 0;

    final pending = await _localDataSource.getUnsyncedMaintenanceRequests();
    if (pending.isEmpty) return 0;

    var syncedCount = 0;
    for (final request in pending) {
      try {
        final response = await _remoteDataSource.createRequest(request);
        await _localDataSource.markMaintenanceSynced(
          request.id,
          serverStatus: response.status,
        );
        syncedCount++;
        if (kDebugMode) {
          debugPrint(
            '[Maintenance] Sync OK id=${request.id} status=${response.status}',
          );
        }
      } on DioException catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[Maintenance] Sync falló id=${request.id}: '
            '${mapMaintenanceError(e)}',
          );
        }
        await Future<void>.delayed(
          Duration(milliseconds: 500 + _random.nextInt(1000)),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Maintenance] Sync error id=${request.id}: $e');
        }
      }
    }
    return syncedCount;
  }
}
