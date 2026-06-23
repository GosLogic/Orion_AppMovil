import 'package:equatable/equatable.dart';

abstract class DispatchEvent extends Equatable {
  const DispatchEvent();

  @override
  List<Object?> get props => [];
}

class LoadRouteSheets extends DispatchEvent {
  const LoadRouteSheets();
}

class LoadRouteSheet extends DispatchEvent {
  final String routeSheetId;

  const LoadRouteSheet(this.routeSheetId);

  @override
  List<Object?> get props => [routeSheetId];
}

class LoadDailyRoute extends DispatchEvent {
  const LoadDailyRoute();
}

class StartJornada extends DispatchEvent {
  const StartJornada();
}

class EndJornada extends DispatchEvent {
  const EndJornada();
}

class MarkStopArrived extends DispatchEvent {
  final String tripStopId;

  const MarkStopArrived(this.tripStopId);

  @override
  List<Object?> get props => [tripStopId];
}

class LoadStopDeliveries extends DispatchEvent {
  final String tripStopId;

  const LoadStopDeliveries(this.tripStopId);

  @override
  List<Object?> get props => [tripStopId];
}

class SubmitProofOfDelivery extends DispatchEvent {
  final String deliveryId;

  const SubmitProofOfDelivery({required this.deliveryId});

  @override
  List<Object?> get props => [deliveryId];
}
