import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/dispatch/domain/entities/delivery.dart';
import 'package:orion_app/features/dispatch/domain/repositories/dispatch_repository.dart';

class SubmitProofOfDeliveryUseCase {
  final DispatchRepository repository;

  SubmitProofOfDeliveryUseCase(this.repository);

  Future<Result<Delivery>> call({required String deliveryId}) {
    return repository.submitProofOfDelivery(deliveryId: deliveryId);
  }
}
