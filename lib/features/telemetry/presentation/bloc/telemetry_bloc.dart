import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/features/telemetry/data/services/gps_tracker_service.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_event.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_state.dart';

class TelemetryBloc extends Bloc<TelemetryEvent, TelemetryState> {
  TelemetryBloc({required GpsTrackerService gpsTrackerService})
      : _gpsTrackerService = gpsTrackerService,
        super(const TelemetryState()) {
    on<StartTelemetry>(_onStart);
    on<StopTelemetry>(_onStop);
  }

  final GpsTrackerService _gpsTrackerService;

  Future<void> _onStart(
    StartTelemetry event,
    Emitter<TelemetryState> emit,
  ) async {
    try {
      await _gpsTrackerService.startTracking(
        event.vehicleId,
        event.routeSheetId,
      );
      emit(
        TelemetryState(
          status: TelemetryStatus.trackingActive,
          activeVehicleId: event.vehicleId,
          activeRouteSheetId: event.routeSheetId,
        ),
      );
    } on GpsTrackerException catch (e) {
      emit(
        TelemetryState(
          status: TelemetryStatus.gpsError,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        TelemetryState(
          status: TelemetryStatus.gpsError,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onStop(
    StopTelemetry event,
    Emitter<TelemetryState> emit,
  ) async {
    await _gpsTrackerService.stopTracking();
    emit(const TelemetryState(status: TelemetryStatus.trackingStopped));
  }
}
