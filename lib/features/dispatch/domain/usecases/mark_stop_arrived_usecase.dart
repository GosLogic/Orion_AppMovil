import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:orion_app/features/dispatch/domain/repositories/dispatch_repository.dart';

class MarkStopArrivedUseCase {
  final DispatchRepository repository;

  MarkStopArrivedUseCase(this.repository);

  Future<Result<TripStop>> call(String tripStopId) {
    return repository.markStopArrived(tripStopId);
  }
}
