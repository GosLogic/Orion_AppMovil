import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/core/error/failures.dart';
import 'package:orion_app/core/location/device_location_service.dart';
import 'package:orion_app/core/sync/sync_manager.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/dispatch/data/datasources/dispatch_local_datasource.dart';
import 'package:orion_app/features/dispatch/data/datasources/dispatch_remote_datasource.dart';
import 'package:orion_app/features/dispatch/data/models/delivery_model.dart';
import 'package:orion_app/features/dispatch/data/models/route_sheet_model.dart';
import 'package:orion_app/features/dispatch/data/models/trip_stop_model.dart';
import 'package:orion_app/features/dispatch/data/utils/dispatch_error_mapper.dart';
import 'package:orion_app/features/dispatch/domain/entities/delivery.dart';
import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:orion_app/features/dispatch/domain/repositories/dispatch_repository.dart';

class DispatchRepositoryImpl implements DispatchRepository {
  DispatchRepositoryImpl({
    required DispatchLocalDataSource localDataSource,
    required DispatchRemoteDataSource remoteDataSource,
    required SyncManager syncManager,
    required DeviceLocationService deviceLocationService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _syncManager = syncManager,
        _deviceLocationService = deviceLocationService;

  final DispatchLocalDataSource _localDataSource;
  final DispatchRemoteDataSource _remoteDataSource;
  final SyncManager _syncManager;
  final DeviceLocationService _deviceLocationService;

  @override
  Future<Result<List<RouteSheet>>> getRouteSheets() async {
    try {
      final remoteSheets = await _remoteDataSource.fetchRouteSheets();
      return Success(remoteSheets.map((s) => s.toEntity()).toList());
    } on DioException catch (e) {
      return Error(NetworkFailure(mapDispatchError(e)));
    } catch (e) {
      return Error(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Result<RouteSheet>> loadRouteSheet(String routeSheetId) async {
    try {
      final remoteSheets = await _remoteDataSource.fetchRouteSheets();

      RouteSheetModel? target;
      for (final s in remoteSheets) {
        if (s.id == routeSheetId) {
          target = s;
          break;
        }
      }

      if (target == null) {
        return const Error(CacheFailure('Hoja de ruta no encontrada'));
      }

      await _syncSheetToLocal(target);
      return Success(target.toEntity());
    } on DioException catch (e) {
      return Error(NetworkFailure(mapDispatchError(e)));
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  Future<void> _syncSheetToLocal(RouteSheetModel sheet) async {
    await _localDataSource.clearRouteAndStops();
    await _localDataSource.saveRouteSheet(sheet);

    List<TripStopModel> stops;
    try {
      stops = await _remoteDataSource.fetchTripStops(sheet.id);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[Dispatch] Paradas no cargadas: ${mapDispatchError(e)}');
      }
      stops = const [];
    }

    for (final stop in stops) {
      await _localDataSource.saveTripStop(stop);
      final existing = await _localDataSource.getDeliveries(stop.id);
      if (existing.isEmpty) {
        await _seedDefaultDelivery(stop);
      }
    }
  }

  /// GET remoto → cache local. [RouteSheet.status] = jornada; [TripStop.status] = parada.
  @override
  Future<Result<RouteSheet?>> getDailyRoute() async {
    try {
      final remoteSheets = await _remoteDataSource.fetchRouteSheets();

      if (remoteSheets.isEmpty) {
        await _localDataSource.clearDispatchData();
        return const Success(null);
      }

      final sheet = _pickDailySheet(remoteSheets);
      await _syncSheetToLocal(sheet);

      return Success(sheet.toEntity());
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Dispatch] Error remoto, intentando cache local: ${mapDispatchError(e)}',
        );
      }
      return _getDailyRouteFromCache(fallbackError: mapDispatchError(e));
    } catch (e) {
      return _getDailyRouteFromCache(fallbackError: e.toString());
    }
  }

  Future<Result<RouteSheet?>> _getDailyRouteFromCache({String? fallbackError}) async {
    try {
      final sheet = await _localDataSource.getDailyRouteSheet();
      if (sheet != null) {
        return Success(sheet.toEntity());
      }
      return Error(
        NetworkFailure(
          fallbackError ?? 'No se pudo cargar la ruta desde el servidor',
        ),
      );
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  RouteSheetModel _pickDailySheet(List<RouteSheetModel> sheets) {
    final today = DateTime.now();
    final todaySheets = sheets.where((s) {
      return s.scheduledDate.year == today.year &&
          s.scheduledDate.month == today.month &&
          s.scheduledDate.day == today.day;
    }).toList();
    return todaySheets.isNotEmpty ? todaySheets.first : sheets.first;
  }

  /// Sin GET /deliveries en backend; IDs alineados al seeder (del-stop-001-1, …).
  Future<void> _seedDefaultDelivery(TripStopModel stop) async {
    await _localDataSource.saveDelivery(
      DeliveryModel(
        id: 'del-${stop.id}-1',
        tripStopId: stop.id,
        customerName: 'Cliente ${stop.sequence}',
        packageDescription: 'Paquete estándar #${stop.sequence}',
      ),
    );
  }

  @override
  Future<Result<List<TripStop>>> getTripStops(String routeSheetId) async {
    try {
      final stops = await _localDataSource.getTripStops(routeSheetId);
      return Success(stops.map((s) => s.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<RouteSheet>> startJornada(String routeSheetId) async {
    try {
      final sheet = await _localDataSource.getDailyRouteSheet();
      if (sheet == null || sheet.id != routeSheetId) {
        return const Error(CacheFailure('Hoja de ruta no encontrada'));
      }

      final updated = RouteSheetModel.fromEntity(
        sheet.toEntity().copyWith(status: RouteSheetStatus.inProgress),
      );
      await _localDataSource.saveRouteSheet(updated);

      await _syncManager.enqueue(
        feature: 'dispatch',
        endpoint: '${ApiConstants.routeSheets}/$routeSheetId/start',
        method: 'PATCH',
        payload: {'status': 'in_progress'},
      );

      return Success(updated.toEntity());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<RouteSheet>> endJornada(String routeSheetId) async {
    try {
      final sheet = await _localDataSource.getDailyRouteSheet();
      if (sheet == null || sheet.id != routeSheetId) {
        return const Error(CacheFailure('Hoja de ruta no encontrada'));
      }

      final updated = RouteSheetModel.fromEntity(
        sheet.toEntity().copyWith(status: RouteSheetStatus.completed),
      );
      await _localDataSource.saveRouteSheet(updated);

      await _syncManager.enqueue(
        feature: 'dispatch',
        endpoint: '${ApiConstants.routeSheets}/$routeSheetId/end',
        method: 'PATCH',
        payload: {'status': 'completed'},
      );

      return Success(updated.toEntity());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<TripStop>> markStopArrived(String tripStopId) async {
    try {
      final route = await _localDataSource.getDailyRouteSheet();
      if (route == null) {
        return const Error(CacheFailure('Sin hoja de ruta activa'));
      }

      final stops = await _localDataSource.getTripStops(route.id);
      final stop = stops.where((s) => s.id == tripStopId).firstOrNull;
      if (stop == null) {
        return const Error(CacheFailure('Parada no encontrada'));
      }

      final updated = TripStopModel.fromEntity(
        stop.toEntity().copyWith(status: TripStopStatus.arrived),
      );
      await _localDataSource.saveTripStop(updated);

      final location = await _deviceLocationService.captureForEvent();

      await _syncManager.enqueue(
        feature: 'dispatch',
        endpoint: '${ApiConstants.tripStops}/$tripStopId/arrived',
        method: 'PATCH',
        payload: {
          'status': 'arrived',
          ...location.toApiFields(),
        },
      );

      return Success(updated.toEntity());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Delivery>>> getDeliveries(String tripStopId) async {
    try {
      final deliveries = await _localDataSource.getDeliveries(tripStopId);
      return Success(deliveries.map((d) => d.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<Delivery>> submitProofOfDelivery({
    required String deliveryId,
  }) async {
    try {
      final route = await _localDataSource.getDailyRouteSheet();
      if (route == null) {
        return const Error(CacheFailure('Sin hoja de ruta activa'));
      }

      final stops = await _localDataSource.getTripStops(route.id);
      DeliveryModel? target;

      for (final stop in stops) {
        final deliveries = await _localDataSource.getDeliveries(stop.id);
        target = deliveries.where((d) => d.id == deliveryId).firstOrNull;
        if (target != null) break;
      }

      if (target == null) {
        return const Error(CacheFailure('Entrega no encontrada'));
      }

      final location = await _deviceLocationService.captureForEvent();

      final updated = DeliveryModel(
        id: target.id,
        tripStopId: target.tripStopId,
        customerName: target.customerName,
        packageDescription: target.packageDescription,
        proof: target.proof,
        deliveredAt: DateTime.now(),
        isCompleted: true,
        synced: false,
        latitude: location.latitude,
        longitude: location.longitude,
      );

      await _localDataSource.saveDelivery(updated);

      final stop = stops
          .where((s) => s.id == updated.tripStopId)
          .firstOrNull;
      if (stop != null) {
        final stopDeliveries =
            await _localDataSource.getDeliveries(stop.id);
        final allCompleted = stopDeliveries.every((d) {
          if (d.id == updated.id) return true;
          return d.isCompleted;
        });
        if (allCompleted) {
          await _localDataSource.saveTripStop(
            TripStopModel.fromEntity(
              stop.toEntity().copyWith(status: TripStopStatus.completed),
            ),
          );
        }
      }

      await _syncManager.enqueue(
        feature: 'dispatch',
        endpoint: ApiConstants.deliveries,
        payload: updated.toApiPayload(),
      );

      return Success(updated.toEntity());
    } catch (e) {
      return Error(SyncFailure(e.toString()));
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
