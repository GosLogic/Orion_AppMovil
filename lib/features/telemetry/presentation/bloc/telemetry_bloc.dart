import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/features/telemetry/data/services/gps_tracker_service.dart';
import 'package:orion_app/features/telemetry/data/services/telemetry_coordinator.dart';
import 'package:orion_app/features/telemetry/data/services/telemetry_sync_service.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_event.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_state.dart';

class TelemetryBloc extends Bloc<TelemetryEvent, TelemetryState> {
  TelemetryBloc({
    required TelemetryCoordinator coordinator,
    required TelemetrySyncService syncService,
  })  : _coordinator = coordinator,
        _syncService = syncService,
        super(const TelemetryState()) {
    on<StartTelemetry>(_onStart);
    on<StopTelemetry>(_onStop);
    on<RefreshTelemetryStatus>(_onRefresh);

    _syncService.stateNotifier.addListener(_onSyncStateChanged);
  }

  final TelemetryCoordinator _coordinator;
  final TelemetrySyncService _syncService;

  void _onSyncStateChanged() {
    add(const RefreshTelemetryStatus());
  }

  Future<void> _onStart(
    StartTelemetry event,
    Emitter<TelemetryState> emit,
  ) async {
    try {
      await _coordinator.start(
        vehicleId: event.vehicleId,
        routeSheetId: event.routeSheetId,
      );
      emit(
        state.copyWith(
          status: TelemetryStatus.trackingActive,
          activeVehicleId: event.vehicleId,
          activeRouteSheetId: event.routeSheetId,
          clearError: true,
          clearWarning: true,
        ),
      );
      add(const RefreshTelemetryStatus());
    } on GpsTrackerException catch (e) {
      emit(
        state.copyWith(
          status: TelemetryStatus.gpsError,
          warningMessage:
              'Jornada activa pero GPS no disponible: ${e.message}',
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: TelemetryStatus.gpsError,
          warningMessage: 'No se pudo iniciar telemetría: $e',
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onStop(
    StopTelemetry event,
    Emitter<TelemetryState> emit,
  ) async {
    await _coordinator.stop();
    emit(
      state.copyWith(
        status: TelemetryStatus.trackingStopped,
        clearContext: true,
        clearError: true,
        clearWarning: true,
      ),
    );
    add(const RefreshTelemetryStatus());
  }

  Future<void> _onRefresh(
    RefreshTelemetryStatus event,
    Emitter<TelemetryState> emit,
  ) async {
    final syncState = _syncService.stateNotifier.value;
    emit(
      state.copyWith(
        pendingCount: syncState.pendingCount,
        lastSyncedAt: syncState.lastSyncedAt,
        isSyncing: syncState.isSyncing,
      ),
    );
  }

  @override
  Future<void> close() {
    _syncService.stateNotifier.removeListener(_onSyncStateChanged);
    return super.close();
  }
}
