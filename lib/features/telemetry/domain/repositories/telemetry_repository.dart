import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/telemetry/domain/entities/vehicle_position.dart';

abstract class TelemetryRepository {
  Future<Result<void>> insertPosition(VehiclePosition position);
                                  
  Future<Result<List<VehiclePosition>>> getUnsyncedPositions({int limit = 100});
}
