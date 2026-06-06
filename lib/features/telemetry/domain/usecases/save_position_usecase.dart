import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/telemetry/domain/entities/vehicle_position.dart';
import 'package:orion_app/features/telemetry/domain/repositories/telemetry_repository.dart';

class SavePositionUseCase {
  final TelemetryRepository repository;

  SavePositionUseCase(this.repository);

  Future<Result<void>> call(VehiclePosition position) {
    return repository.insertPosition(position);
  }
}
