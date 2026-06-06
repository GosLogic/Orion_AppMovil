import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/dispatch/domain/entities/delivery.dart';
import 'package:orion_app/features/dispatch/domain/repositories/dispatch_repository.dart';

class GetDeliveriesUseCase {
  final DispatchRepository repository;

  GetDeliveriesUseCase(this.repository);

  Future<Result<List<Delivery>>> call(String tripStopId) {
    return repository.getDeliveries(tripStopId);
  }
}
