import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/telemetry/domain/entities/telemetry_sync_result.dart';
import 'package:orion_app/features/telemetry/domain/repositories/telemetry_repository.dart';

class SyncPendingPositionsUseCase {
  SyncPendingPositionsUseCase(this._repository);

  final TelemetryRepository _repository;

  Future<Result<TelemetrySyncResult>> call({int limit = 50}) {
    return _repository.syncPendingPositions(limit: limit);
  }
}
