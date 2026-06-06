import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/dispatch/domain/entities/delivery.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:orion_app/features/dispatch/domain/repositories/dispatch_repository.dart';
import 'package:orion_app/features/dispatch/domain/usecases/end_jornada_usecase.dart';
import 'package:orion_app/features/dispatch/domain/usecases/get_deliveries_usecase.dart';
import 'package:orion_app/features/dispatch/domain/usecases/load_daily_route_usecase.dart';
import 'package:orion_app/features/dispatch/domain/usecases/mark_stop_arrived_usecase.dart';
import 'package:orion_app/features/dispatch/domain/usecases/start_jornada_usecase.dart';
import 'package:orion_app/features/dispatch/domain/usecases/submit_proof_of_delivery_usecase.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_event.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_state.dart';

class DispatchBloc extends Bloc<DispatchEvent, DispatchState> {
  DispatchBloc({
    required LoadDailyRouteUseCase loadDailyRouteUseCase,
    required StartJornadaUseCase startJornadaUseCase,
    required EndJornadaUseCase endJornadaUseCase,
    required MarkStopArrivedUseCase markStopArrivedUseCase,
    required GetDeliveriesUseCase getDeliveriesUseCase,
    required SubmitProofOfDeliveryUseCase submitProofOfDeliveryUseCase,
    required DispatchRepository dispatchRepository,
  })  : _loadDailyRouteUseCase = loadDailyRouteUseCase,
        _startJornadaUseCase = startJornadaUseCase,
        _endJornadaUseCase = endJornadaUseCase,
        _markStopArrivedUseCase = markStopArrivedUseCase,
        _getDeliveriesUseCase = getDeliveriesUseCase,
        _submitProofOfDeliveryUseCase = submitProofOfDeliveryUseCase,
        _dispatchRepository = dispatchRepository,
        super(const DispatchState()) {
    on<LoadDailyRoute>(_onLoadDailyRoute);
    on<StartJornada>(_onStartJornada);
    on<EndJornada>(_onEndJornada);
    on<MarkStopArrived>(_onMarkStopArrived);
    on<LoadStopDeliveries>(_onLoadStopDeliveries);
    on<SubmitProofOfDelivery>(_onSubmitProofOfDelivery);
  }

  final LoadDailyRouteUseCase _loadDailyRouteUseCase;
  final StartJornadaUseCase _startJornadaUseCase;
  final EndJornadaUseCase _endJornadaUseCase;
  final MarkStopArrivedUseCase _markStopArrivedUseCase;
  final GetDeliveriesUseCase _getDeliveriesUseCase;
  final SubmitProofOfDeliveryUseCase _submitProofOfDeliveryUseCase;
  final DispatchRepository _dispatchRepository;

  Future<void> _onLoadDailyRoute(
    LoadDailyRoute event,
    Emitter<DispatchState> emit,
  ) async {
    emit(state.copyWith(status: DispatchStatus.loading, clearMessages: true));

    final routeResult = await _loadDailyRouteUseCase();
    switch (routeResult) {
      case Success(value: final route):
        if (route == null) {
          emit(
            state.copyWith(
              status: DispatchStatus.loaded,
              dailyRoute: null,
              tripStops: const [],
            ),
          );
          return;
        }

        final stopsResult = await _dispatchRepository.getTripStops(route.id);
        switch (stopsResult) {
          case Success(value: final stops):
            emit(
              state.copyWith(
                status: DispatchStatus.loaded,
                dailyRoute: route,
                tripStops: stops,
              ),
            );
          case Error(failure: final failure):
            emit(
              state.copyWith(
                status: DispatchStatus.failure,
                dailyRoute: route,
                errorMessage: failure.message,
              ),
            );
        }
      case Error(failure: final failure):
        emit(
          state.copyWith(
            status: DispatchStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> _onStartJornada(
    StartJornada event,
    Emitter<DispatchState> emit,
  ) async {
    final route = state.dailyRoute;
    if (route == null || !route.canStartJornada) return;

    emit(state.copyWith(status: DispatchStatus.submitting, clearMessages: true));

    final result = await _startJornadaUseCase(route.id);
    switch (result) {
      case Success(value: final updatedRoute):
        emit(
          state.copyWith(
            status: DispatchStatus.loaded,
            dailyRoute: updatedRoute,
            successMessage: '¡Jornada iniciada! Ya puedes atender las paradas.',
          ),
        );
      case Error(failure: final failure):
        emit(
          state.copyWith(
            status: DispatchStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> _onEndJornada(
    EndJornada event,
    Emitter<DispatchState> emit,
  ) async {
    final route = state.dailyRoute;
    if (route == null || !route.canEndJornada) return;

    emit(state.copyWith(status: DispatchStatus.submitting, clearMessages: true));

    final result = await _endJornadaUseCase(route.id);
    switch (result) {
      case Success(value: final updatedRoute):
        emit(
          state.copyWith(
            status: DispatchStatus.loaded,
            dailyRoute: updatedRoute,
            successMessage: 'Jornada finalizada correctamente.',
          ),
        );
      case Error(failure: final failure):
        emit(
          state.copyWith(
            status: DispatchStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> _onMarkStopArrived(
    MarkStopArrived event,
    Emitter<DispatchState> emit,
  ) async {
    emit(state.copyWith(status: DispatchStatus.submitting, clearMessages: true));

    final result = await _markStopArrivedUseCase(event.tripStopId);
    switch (result) {
      case Success(value: final updatedStop):
        final updatedStops = state.tripStops.map((stop) {
          return stop.id == updatedStop.id ? updatedStop : stop;
        }).toList();
        emit(
          state.copyWith(
            status: DispatchStatus.loaded,
            tripStops: updatedStops,
            selectedStop: updatedStop,
            successMessage: 'Llegada registrada en la parada.',
          ),
        );
      case Error(failure: final failure):
        emit(
          state.copyWith(
            status: DispatchStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> _onLoadStopDeliveries(
    LoadStopDeliveries event,
    Emitter<DispatchState> emit,
  ) async {
    TripStop? stop;
    for (final s in state.tripStops) {
      if (s.id == event.tripStopId) {
        stop = s;
        break;
      }
    }

    emit(
      state.copyWith(
        status: DispatchStatus.loading,
        selectedStop: stop,
        clearMessages: true,
      ),
    );

    final result = await _getDeliveriesUseCase(event.tripStopId);
    switch (result) {
      case Success(value: final deliveries):
        emit(
          state.copyWith(
            status: DispatchStatus.loaded,
            deliveries: deliveries,
            selectedStop: stop,
          ),
        );
      case Error(failure: final failure):
        emit(
          state.copyWith(
            status: DispatchStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> _onSubmitProofOfDelivery(
    SubmitProofOfDelivery event,
    Emitter<DispatchState> emit,
  ) async {
    emit(state.copyWith(status: DispatchStatus.submitting, clearMessages: true));

    final result = await _submitProofOfDeliveryUseCase(
      deliveryId: event.deliveryId,
      proof: event.proof,
    );

    switch (result) {
      case Success():
        final selectedStopId = state.selectedStop?.id;
        final routeResult = await _loadDailyRouteUseCase();
        if (routeResult case Success(value: final route)) {
          if (route != null) {
            final stopsResult = await _dispatchRepository.getTripStops(route.id);
            if (stopsResult case Success(value: final stops)) {
              List<Delivery> deliveries = state.deliveries;
              if (selectedStopId != null) {
                final delResult =
                    await _getDeliveriesUseCase(selectedStopId);
                if (delResult case Success(value: final updated)) {
                  deliveries = updated;
                }
              }
              emit(
                state.copyWith(
                  status: DispatchStatus.loaded,
                  dailyRoute: route,
                  tripStops: stops,
                  deliveries: deliveries,
                  successMessage:
                      'Entrega registrada. Se sincronizará al tener red.',
                ),
              );
              return;
            }
          }
        }
        emit(
          state.copyWith(
            status: DispatchStatus.loaded,
            successMessage:
                'Entrega registrada. Se sincronizará al tener red.',
          ),
        );
      case Error(failure: final failure):
        emit(
          state.copyWith(
            status: DispatchStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }
}
