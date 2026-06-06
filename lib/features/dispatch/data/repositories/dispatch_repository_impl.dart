import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/core/error/failures.dart';
import 'package:orion_app/core/sync/sync_manager.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/dispatch/data/datasources/dispatch_local_datasource.dart';
import 'package:orion_app/features/dispatch/data/models/delivery_model.dart';
import 'package:orion_app/features/dispatch/data/models/route_sheet_model.dart';
import 'package:orion_app/features/dispatch/data/models/trip_stop_model.dart';
import 'package:orion_app/features/dispatch/domain/entities/delivery.dart';
import 'package:orion_app/features/dispatch/domain/entities/proof_of_delivery.dart';
import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:orion_app/features/dispatch/domain/repositories/dispatch_repository.dart';

class DispatchRepositoryImpl implements DispatchRepository {
  DispatchRepositoryImpl({
    required DispatchLocalDataSource localDataSource,
    required SyncManager syncManager,
  })  : _localDataSource = localDataSource,
        _syncManager = syncManager;

  final DispatchLocalDataSource _localDataSource;
  final SyncManager _syncManager;

  @override
  Future<Result<RouteSheet?>> getDailyRoute() async {
    try {
      final sheet = await _localDataSource.getDailyRouteSheet();
      return Success(sheet?.toEntity());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
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

      await _syncManager.enqueue(
        feature: 'dispatch',
        endpoint: '${ApiConstants.tripStops}/$tripStopId/arrived',
        method: 'PATCH',
        payload: {'status': 'arrived'},
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
    required ProofOfDelivery proof,
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

      final updated = DeliveryModel(
        id: target.id,
        tripStopId: target.tripStopId,
        customerName: target.customerName,
        packageDescription: target.packageDescription,
        proof: proof,
        deliveredAt: DateTime.now(),
        isCompleted: true,
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
        payload: updated.toJson(),
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
