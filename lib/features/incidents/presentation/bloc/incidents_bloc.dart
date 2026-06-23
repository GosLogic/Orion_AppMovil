import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/incidents/domain/repositories/incidents_repository.dart';
import 'package:orion_app/features/incidents/domain/usecases/get_maintenance_history_usecase.dart';
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
    required GetMaintenanceHistoryUseCase getMaintenanceHistoryUseCase,
    required IncidentsRepository incidentsRepository,
  })  : _submitRouteIncidentUseCase = submitRouteIncidentUseCase,
        _submitMaintenanceRequestUseCase = submitMaintenanceRequestUseCase,
        _triggerPanicAlertUseCase = triggerPanicAlertUseCase,
        _getMaintenanceHistoryUseCase = getMaintenanceHistoryUseCase,
        _incidentsRepository = incidentsRepository,
        super(const IncidentsState()) {
    on<SubmitRouteIncident>(_onSubmitRouteIncident);
    on<SubmitMaintenanceRequest>(_onSubmitMaintenanceRequest);
    on<TriggerPanicAlert>(_onTriggerPanicAlert);
    on<LoadMaintenanceHistory>(_onLoadMaintenanceHistory);
    on<SyncMaintenancePending>(_onSyncMaintenancePending);
  }

  final SubmitRouteIncidentUseCase _submitRouteIncidentUseCase;
  final SubmitMaintenanceRequestUseCase _submitMaintenanceRequestUseCase;
  final TriggerPanicAlertUseCase _triggerPanicAlertUseCase;
  final GetMaintenanceHistoryUseCase _getMaintenanceHistoryUseCase;
  final IncidentsRepository _incidentsRepository;

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
    switch (result) {
      case Success(value: final request):
        final message = request.synced
            ? 'Solicitud enviada. Estado: ${request.serverStatus ?? 'PENDING'}'
            : 'Solicitud guardada. Se enviará al tener red (mismo ID).';
        emit(
          state.copyWith(
            status: IncidentsStatus.success,
            message: message,
          ),
        );
        add(const LoadMaintenanceHistory());
      case Error(failure: final failure):
        emit(
          state.copyWith(
            status: IncidentsStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> _onLoadMaintenanceHistory(
    LoadMaintenanceHistory event,
    Emitter<IncidentsState> emit,
  ) async {
    emit(state.copyWith(status: IncidentsStatus.loading, clearMessages: true));
    final result = await _getMaintenanceHistoryUseCase();
    switch (result) {
      case Success(value: final list):
        emit(
          state.copyWith(
            status: IncidentsStatus.initial,
            maintenanceHistory: list,
          ),
        );
      case Error(failure: final failure):
        emit(
          state.copyWith(
            status: IncidentsStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> _onSyncMaintenancePending(
    SyncMaintenancePending event,
    Emitter<IncidentsState> emit,
  ) async {
    emit(state.copyWith(status: IncidentsStatus.loading, clearMessages: true));
    final result = await _incidentsRepository.syncPendingMaintenance();
    switch (result) {
      case Success(value: final count):
        emit(
          state.copyWith(
            status: IncidentsStatus.success,
            message: count > 0
                ? '$count solicitud(es) sincronizada(s)'
                : 'No hay solicitudes pendientes',
          ),
        );
        add(const LoadMaintenanceHistory());
      case Error(failure: final failure):
        emit(
          state.copyWith(
            status: IncidentsStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
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
            maintenanceHistory: state.maintenanceHistory,
          ),
        );
      case Error(failure: final failure):
        emit(
          IncidentsState(
            status: IncidentsStatus.failure,
            errorMessage: failure.message,
            maintenanceHistory: state.maintenanceHistory,
          ),
        );
    }
  }
}
