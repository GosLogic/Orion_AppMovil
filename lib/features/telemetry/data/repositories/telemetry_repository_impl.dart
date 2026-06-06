import 'package:orion_app/core/error/failures.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/telemetry/data/datasources/telemetry_local_datasource.dart';
import 'package:orion_app/features/telemetry/domain/entities/vehicle_position.dart';
import 'package:orion_app/features/telemetry/domain/repositories/telemetry_repository.dart';

class TelemetryRepositoryImpl implements TelemetryRepository {
  TelemetryRepositoryImpl({
    required TelemetryLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final TelemetryLocalDataSource _localDataSource;

  @override
  Future<Result<void>> insertPosition(VehiclePosition position) async {
    try {
      await _localDataSource.insertPosition(position);
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<VehiclePosition>>> getUnsyncedPositions({
    int limit = 100,
  }) async {
    try {
      final models =
          await _localDataSource.getUnsyncedPositions(limit: limit);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }
}
