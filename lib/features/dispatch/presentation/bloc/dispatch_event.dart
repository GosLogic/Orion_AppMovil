import 'package:equatable/equatable.dart';
import 'package:orion_app/features/dispatch/domain/entities/proof_of_delivery.dart';

abstract class DispatchEvent extends Equatable {
  const DispatchEvent();

  @override
  List<Object?> get props => [];
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
  final ProofOfDelivery proof;

  const SubmitProofOfDelivery({
    required this.deliveryId,
    required this.proof,
  });

  @override
  List<Object?> get props => [deliveryId, proof];
}
