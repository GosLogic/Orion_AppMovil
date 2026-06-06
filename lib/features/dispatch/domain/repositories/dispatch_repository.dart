import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/dispatch/domain/entities/delivery.dart';
import 'package:orion_app/features/dispatch/domain/entities/proof_of_delivery.dart';
import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';

abstract class DispatchRepository {
  Future<Result<RouteSheet?>> getDailyRoute();

  Future<Result<List<TripStop>>> getTripStops(String routeSheetId);

  Future<Result<RouteSheet>> startJornada(String routeSheetId);

  Future<Result<RouteSheet>> endJornada(String routeSheetId);

  Future<Result<TripStop>> markStopArrived(String tripStopId);

  Future<Result<List<Delivery>>> getDeliveries(String tripStopId);

  Future<Result<Delivery>> submitProofOfDelivery({
    required String deliveryId,
    required ProofOfDelivery proof,
  });
}
