import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orion_app/core/error/failures.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/telemetry/data/datasources/telemetry_local_datasource.dart';
import 'package:orion_app/features/telemetry/data/datasources/telemetry_remote_datasource.dart';
import 'package:orion_app/features/telemetry/domain/entities/telemetry_sync_result.dart';
import 'package:orion_app/features/telemetry/domain/entities/vehicle_position.dart';
import 'package:orion_app/features/telemetry/domain/repositories/telemetry_repository.dart';

class TelemetryRepositoryImpl implements TelemetryRepository {
  TelemetryRepositoryImpl({
    required TelemetryLocalDataSource localDataSource,
    required TelemetryRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  final TelemetryLocalDataSource _localDataSource;
  final TelemetryRemoteDataSource _remoteDataSource;

  static const int defaultBatchLimit = 50;

  @override
  Future<Result<void>> insertPosition(VehiclePosition position) async {
    if (!_isValidCoordinate(position.latitude, position.longitude)) {
      return const Error(
        ValidationFailure('Coordenadas GPS inválidas, posición descartada'),
      );
    }

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

  @override
  Future<Result<int>> countUnsyncedPositions() async {
    try {
      final count = await _localDataSource.countUnsyncedPositions();
      return Success(count);
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<TelemetrySyncResult>> syncPendingPositions({
    int limit = defaultBatchLimit,
  }) async {
    try {
      final positions =
          await _localDataSource.getUnsyncedPositions(limit: limit);
      if (positions.isEmpty) {
        return const Success(
          TelemetrySyncResult(accepted: 0, rejected: 0, pendingRemaining: 0),
        );
      }

      final response = await _remoteDataSource.sendBatch(positions);

      final accepted = response.accepted.clamp(0, positions.length);
      if (accepted > 0) {
        final idsToMark = positions
            .take(accepted)
            .where((p) => p.id != null)
            .map((p) => p.id!)
            .toList();
        await _localDataSource.markAsSynced(idsToMark);
      }

      final pending = await _localDataSource.countUnsyncedPositions();

      if (kDebugMode && response.rejected > 0) {
        debugPrint(
          '[Telemetry] Batch: accepted=${response.accepted}, '
          'rejected=${response.rejected}, pending=$pending',
        );
      }

      return Success(
        TelemetrySyncResult(
          accepted: response.accepted,
          rejected: response.rejected,
          pendingRemaining: pending,
        ),
      );
    } on DioException catch (e) {
      return Error(
        NetworkFailure(e.message ?? 'Error sincronizando telemetría'),
      );
    } catch (e) {
      return Error(NetworkFailure(e.toString()));
    }
  }

  bool _isValidCoordinate(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
}
