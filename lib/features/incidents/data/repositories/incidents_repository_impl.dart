import 'package:dio/dio.dart';
import 'package:orion_app/core/error/failures.dart';
import 'package:orion_app/core/sync/sync_manager.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/incidents/data/datasources/incidents_local_datasource.dart';
import 'package:orion_app/features/incidents/data/datasources/maintenance_remote_datasource.dart';
import 'package:orion_app/features/incidents/data/models/incident_model.dart';
import 'package:orion_app/features/incidents/data/models/maintenance_request_model.dart';
import 'package:orion_app/features/incidents/data/services/maintenance_sync_service.dart';
import 'package:orion_app/features/incidents/domain/entities/maintenance_request.dart';
import 'package:orion_app/features/incidents/domain/entities/route_incident.dart';
import 'package:orion_app/features/incidents/domain/repositories/incidents_repository.dart';
import 'package:orion_app/core/constants/api_constants.dart';

class IncidentsRepositoryImpl implements IncidentsRepository {
  IncidentsRepositoryImpl({
    required IncidentsLocalDataSource localDataSource,
    required MaintenanceRemoteDataSource maintenanceRemoteDataSource,
    required MaintenanceSyncService maintenanceSyncService,
    required SyncManager syncManager,
  })  : _localDataSource = localDataSource,
        _maintenanceRemote = maintenanceRemoteDataSource,
        _maintenanceSync = maintenanceSyncService,
        _syncManager = syncManager;

  final IncidentsLocalDataSource _localDataSource;
  final MaintenanceRemoteDataSource _maintenanceRemote;
  final MaintenanceSyncService _maintenanceSync;
  final SyncManager _syncManager;

  @override
  Future<Result<RouteIncident>> submitRouteIncident(
    RouteIncident incident,
  ) async {
    try {
      final model = RouteIncidentModel.fromEntity(incident);
      await _localDataSource.saveRouteIncident(model);

      await _syncManager.enqueue(
        feature: 'incidents',
        endpoint: ApiConstants.incidents,
        payload: model.toJson(),
      );

      return Success(model.toEntity());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<MaintenanceRequest>> submitMaintenanceRequest(
    MaintenanceRequest request,
  ) async {
    try {
      final model = MaintenanceRequestModel.fromEntity(request);
      await _localDataSource.saveMaintenanceRequest(model);

      try {
        final response = await _maintenanceRemote.createRequest(model);
        await _localDataSource.markMaintenanceSynced(
          model.id,
          serverStatus: response.status,
        );
        return Success(
          MaintenanceRequestModel(
            id: model.id,
            vehicleId: model.vehicleId,
            description: model.description,
            severity: model.severity,
            reportedAt: model.reportedAt,
            photoEvidencePath: model.photoEvidencePath,
            synced: true,
            serverStatus: response.status,
          ).toEntity(),
        );
      } on DioException {
        _maintenanceSync.start();
        return Success(model.toEntity());
      }
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<MaintenanceRequest>>> getMaintenanceHistory() async {
    try {
      final models = await _localDataSource.getMaintenanceRequests();
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<int>> syncPendingMaintenance() async {
    try {
      final count = await _maintenanceSync.syncPending(force: true);
      return Success(count);
    } catch (e) {
      return Error(SyncFailure(e.toString()));
    }
  }

  @override
  Future<Result<RouteIncident>> triggerPanicAlert({
    required double latitude,
    required double longitude,
    String? stopId,
  }) async {
    try {
      final panic = RouteIncidentModel(
        id: 'panic-${DateTime.now().millisecondsSinceEpoch}',
        stopId: stopId,
        type: RouteIncidentType.other,
        description: 'ALERTA DE PÁNICO — EMERGENCIA EN RUTA',
        reportedAt: DateTime.now(),
        isPanic: true,
        latitude: latitude,
        longitude: longitude,
      );

      await _localDataSource.saveRouteIncident(panic);

      await _syncManager.enqueue(
        feature: 'incidents',
        endpoint: ApiConstants.panic,
        payload: panic.toJson(),
        maxRetries: 15,
      );

      await _syncManager.processQueue();

      return Success(panic.toEntity());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }
}
