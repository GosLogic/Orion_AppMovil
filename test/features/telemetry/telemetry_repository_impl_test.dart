import 'package:flutter_test/flutter_test.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/telemetry/data/datasources/telemetry_local_datasource.dart';
import 'package:orion_app/features/telemetry/data/datasources/telemetry_remote_datasource.dart';
import 'package:orion_app/features/telemetry/data/models/telemetry_batch_response_model.dart';
import 'package:orion_app/features/telemetry/data/models/vehicle_position_model.dart';
import 'package:orion_app/features/telemetry/data/repositories/telemetry_repository_impl.dart';
import 'package:orion_app/features/telemetry/domain/entities/vehicle_position.dart';

class _FakeLocalDataSource implements TelemetryLocalDataSource {
  final List<VehiclePositionModel> store = [];
  final Set<int> syncedIds = {};

  @override
  Future<void> insertPosition(VehiclePosition position) async {
    store.add(
      VehiclePositionModel.fromEntity(position).copyWithId(store.length + 1),
    );
  }

  @override
  Future<List<VehiclePositionModel>> getUnsyncedPositions({
    int limit = 100,
  }) async {
    return store
        .where((p) => p.id != null && !syncedIds.contains(p.id))
        .take(limit)
        .toList();
  }

  @override
  Future<int> countUnsyncedPositions() async {
    return store.where((p) => p.id != null && !syncedIds.contains(p.id)).length;
  }

  @override
  Future<bool> existsPosition(int vehicleId, String timeIso) async => false;

  @override
  Future<void> markAsSynced(List<int> ids) async {
    syncedIds.addAll(ids);
  }
}

class _FakeRemoteDataSource implements TelemetryRemoteDataSource {
  int lastBatchSize = 0;

  @override
  Future<TelemetryBatchResponseModel> sendBatch(
    List<VehiclePositionModel> positions,
  ) async {
    lastBatchSize = positions.length;
    return TelemetryBatchResponseModel(
      accepted: positions.length,
      rejected: 0,
    );
  }

  @override
  Future<void> sendSingle(VehiclePositionModel position) async {}

  @override
  Future<Map<String, dynamic>?> fetchLatestPosition(
    String vehicleExternalId,
  ) async =>
      null;
}

extension on VehiclePositionModel {
  VehiclePositionModel copyWithId(int id) {
    return VehiclePositionModel(
      id: id,
      time: time,
      vehicleId: vehicleId,
      latitude: latitude,
      longitude: longitude,
      speedKmh: speedKmh,
      heading: heading,
      routeSheetId: routeSheetId,
      isMocked: isMocked,
      synced: synced,
    );
  }
}

void main() {
  late _FakeLocalDataSource local;
  late _FakeRemoteDataSource remote;
  late TelemetryRepositoryImpl repository;

  setUp(() {
    local = _FakeLocalDataSource();
    remote = _FakeRemoteDataSource();
    repository = TelemetryRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
    );
  });

  test('syncPendingPositions envía batch y marca synced', () async {
    await repository.insertPosition(
      VehiclePosition(
        time: DateTime(2026, 6, 22, 10, 0),
        vehicleId: 1,
        latitude: -12.04,
        longitude: -77.04,
        speedKmh: 10,
        heading: 0,
        routeSheetId: 5,
      ),
    );
    await repository.insertPosition(
      VehiclePosition(
        time: DateTime(2026, 6, 22, 10, 1),
        vehicleId: 1,
        latitude: -12.05,
        longitude: -77.05,
        speedKmh: 20,
        heading: 90,
        routeSheetId: 5,
      ),
    );

    final result = await repository.syncPendingPositions(limit: 50);

    expect(result, isA<Success>());
    final sync = (result as Success).value;
    expect(sync.accepted, 2);
    expect(remote.lastBatchSize, 2);

    final pending = await repository.countUnsyncedPositions();
    expect((pending as Success).value, 0);
  });

  test('insertPosition rechaza coordenadas inválidas', () async {
    final result = await repository.insertPosition(
      VehiclePosition(
        time: DateTime(2026, 6, 22, 10, 0),
        vehicleId: 1,
        latitude: 999,
        longitude: -77.04,
        speedKmh: 10,
        heading: 0,
      ),
    );

    expect(result, isA<Error>());
    expect(local.store, isEmpty);
  });
}
