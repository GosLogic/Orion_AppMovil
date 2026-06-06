import 'package:equatable/equatable.dart';

abstract class TelemetryEvent extends Equatable {
  const TelemetryEvent();

  @override
  List<Object?> get props => [];
}

class StartTelemetry extends TelemetryEvent {
  final int vehicleId;
  final int routeSheetId;

  const StartTelemetry({
    required this.vehicleId,
    required this.routeSheetId,
  });

  @override
  List<Object?> get props => [vehicleId, routeSheetId];
}

class StopTelemetry extends TelemetryEvent {
  const StopTelemetry();
}
