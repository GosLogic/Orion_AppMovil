import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/incidents/domain/usecases/submit_maintenance_request_usecase.dart';
import 'package:orion_app/features/incidents/domain/usecases/submit_route_incident_usecase.dart';
import 'package:orion_app/features/incidents/domain/usecases/trigger_panic_alert_usecase.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_event.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_state.dart';

class IncidentsBloc extends Bloc<IncidentsEvent, IncidentsState> {
  IncidentsBloc({
    required SubmitRouteIncidentUseCase submitRouteIncidentUseCase,
    required SubmitMaintenanceRequestUseCase submitMaintenanceRequestUseCase,
    required TriggerPanicAlertUseCase triggerPanicAlertUseCase,
  })  : _submitRouteIncidentUseCase = submitRouteIncidentUseCase,
        _submitMaintenanceRequestUseCase = submitMaintenanceRequestUseCase,
        _triggerPanicAlertUseCase = triggerPanicAlertUseCase,
        super(const IncidentsState()) {
    on<SubmitRouteIncident>(_onSubmitRouteIncident);
    on<SubmitMaintenanceRequest>(_onSubmitMaintenanceRequest);
    on<TriggerPanicAlert>(_onTriggerPanicAlert);
  }

  final SubmitRouteIncidentUseCase _submitRouteIncidentUseCase;
  final SubmitMaintenanceRequestUseCase _submitMaintenanceRequestUseCase;
  final TriggerPanicAlertUseCase _triggerPanicAlertUseCase;

  Future<void> _onSubmitRouteIncident(
    SubmitRouteIncident event,
    Emitter<IncidentsState> emit,
  ) async {
    emit(state.copyWith(status: IncidentsStatus.loading, clearMessages: true));
    final result = await _submitRouteIncidentUseCase(event.incident);
    _emitResult(
      emit,
      result,
      'Reporte guardado localmente. Se sincronizará al tener red.',
    );
  }

  Future<void> _onSubmitMaintenanceRequest(
    SubmitMaintenanceRequest event,
    Emitter<IncidentsState> emit,
  ) async {
    emit(state.copyWith(status: IncidentsStatus.loading, clearMessages: true));
    final result = await _submitMaintenanceRequestUseCase(event.request);
    _emitResult(
      emit,
      result,
      'Solicitud de mantenimiento guardada. Se sincronizará al tener red.',
    );
  }

  Future<void> _onTriggerPanicAlert(
    TriggerPanicAlert event,
    Emitter<IncidentsState> emit,
  ) async {
    emit(state.copyWith(status: IncidentsStatus.loading, clearMessages: true));
    final result = await _triggerPanicAlertUseCase(
      latitude: event.latitude,
      longitude: event.longitude,
      stopId: event.stopId,
    );
    _emitResult(
      emit,
      result,
      'Alerta de pánico registrada. Reintento prioritario activado.',
    );
  }

  void _emitResult<T>(
    Emitter<IncidentsState> emit,
    Result<T> result,
    String successMessage,
  ) {
    switch (result) {
      case Success():
        emit(
          IncidentsState(
            status: IncidentsStatus.success,
            message: successMessage,
          ),
        );
      case Error(failure: final failure):
        emit(
          IncidentsState(
            status: IncidentsStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }
}
