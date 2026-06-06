import 'package:equatable/equatable.dart';
import 'package:orion_app/features/dispatch/domain/entities/delivery.dart';
import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';

enum DispatchStatus { initial, loading, loaded, submitting, failure }

class DispatchState extends Equatable {
  final DispatchStatus status;
  final RouteSheet? dailyRoute;
  final List<TripStop> tripStops;
  final TripStop? selectedStop;
  final List<Delivery> deliveries;
  final String? successMessage;
  final String? errorMessage;

  const DispatchState({
    this.status = DispatchStatus.initial,
    this.dailyRoute,
    this.tripStops = const [],
    this.selectedStop,
    this.deliveries = const [],
    this.successMessage,
    this.errorMessage,
  });

  bool get isJornadaActive => dailyRoute?.isJornadaActive ?? false;

  bool get canStartJornada => dailyRoute?.canStartJornada ?? false;

  bool get canEndJornada => dailyRoute?.canEndJornada ?? false;

  DispatchState copyWith({
    DispatchStatus? status,
    RouteSheet? dailyRoute,
    List<TripStop>? tripStops,
    TripStop? selectedStop,
    List<Delivery>? deliveries,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
    bool clearSelectedStop = false,
  }) {
    return DispatchState(
      status: status ?? this.status,
      dailyRoute: dailyRoute ?? this.dailyRoute,
      tripStops: tripStops ?? this.tripStops,
      selectedStop:
          clearSelectedStop ? null : (selectedStop ?? this.selectedStop),
      deliveries: deliveries ?? this.deliveries,
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        dailyRoute,
        tripStops,
        selectedStop,
        deliveries,
        successMessage,
        errorMessage,
      ];
}
