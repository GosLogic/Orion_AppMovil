import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/core/network/api_client.dart';
import 'package:orion_app/features/dispatch/data/models/delivery_model.dart';
import 'package:orion_app/features/dispatch/data/models/route_sheet_model.dart';
import 'package:orion_app/features/dispatch/data/models/trip_stop_model.dart';

abstract class DispatchRemoteDataSource {
  Future<List<RouteSheetModel>> fetchRouteSheets();

  Future<List<TripStopModel>> fetchTripStops(String routeSheetId);

  Future<void> submitDelivery(DeliveryModel delivery);
}

class DispatchRemoteDataSourceImpl implements DispatchRemoteDataSource {
  DispatchRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<RouteSheetModel>> fetchRouteSheets() async {
    final response = await _apiClient.get(ApiConstants.routeSheets);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => RouteSheetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TripStopModel>> fetchTripStops(String routeSheetId) async {
    final response = await _apiClient.get(
      ApiConstants.tripStops,
      queryParameters: {'route_sheet_id': routeSheetId},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => TripStopModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> submitDelivery(DeliveryModel delivery) async {
    await _apiClient.post(
      ApiConstants.deliveries,
      data: delivery.toJson(),
    );
  }
}
