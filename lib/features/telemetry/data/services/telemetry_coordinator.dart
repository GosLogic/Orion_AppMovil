import 'package:orion_app/features/telemetry/data/services/gps_tracker_service.dart';
import 'package:orion_app/features/telemetry/data/services/telemetry_sync_service.dart';

/// Orquesta captura GPS local y sincronización remota durante la jornada.
class TelemetryCoordinator {
  TelemetryCoordinator({
    required GpsTrackerService gpsTrackerService,
    required TelemetrySyncService syncService,
  })  : _gpsTrackerService = gpsTrackerService,
        _syncService = syncService;

  final GpsTrackerService _gpsTrackerService;
  final TelemetrySyncService _syncService;

  bool get isTracking => _gpsTrackerService.isTracking;

  TelemetrySyncService get syncService => _syncService;

  Future<void> start({
    required int vehicleId,
    required int routeSheetId,
  }) async {
    _gpsTrackerService.onPositionSaved = _syncService.refreshPendingCount;
    await _gpsTrackerService.startTracking(vehicleId, routeSheetId);
    _syncService.start();
  }

  Future<void> stop() async {
    _gpsTrackerService.onPositionSaved = null;
    await _gpsTrackerService.stopTracking();
    await _syncService.flushAndStop();
  }
}
