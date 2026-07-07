import 'package:dio/dio.dart';
import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/core/network/api_client.dart';
import 'package:orion_app/features/dispatch/data/models/delivery_model.dart';
import 'package:orion_app/features/dispatch/data/models/route_sheet_model.dart';
import 'package:orion_app/features/dispatch/data/models/trip_stop_model.dart';
import 'package:orion_app/features/dispatch/data/models/trip_stop_remote_bundle.dart';
import 'package:orion_app/features/dispatch/data/utils/dispatch_integration_log.dart';

abstract class DispatchRemoteDataSource {
  Future<List<RouteSheetModel>> fetchRouteSheets();

  Future<List<TripStopRemoteBundle>> fetchTripStops(String routeSheetId);

  Future<void> submitDelivery(DeliveryModel delivery);
}

class DispatchRemoteDataSourceImpl implements DispatchRemoteDataSource {
  DispatchRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<RouteSheetModel>> fetchRouteSheets() async {
    const path = ApiConstants.routeSheets;
    DispatchIntegrationLog.request(method: 'GET', path: path);

    try {
      final response = await _apiClient.get(path);
      DispatchIntegrationLog.response(response);

      final data = response.data;
      if (data is! List) return [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(RouteSheetModel.fromJson)
          .toList();
    } on DioException catch (e) {
      DispatchIntegrationLog.error(e);
      rethrow;
    }
  }

  @override
  Future<List<TripStopRemoteBundle>> fetchTripStops(String routeSheetId) async {
    const path = ApiConstants.tripStops;
    DispatchIntegrationLog.request(
      method: 'GET',
      path: '$path?route_sheet_id=$routeSheetId',
    );

    try {
      final response = await _apiClient.get(
        path,
        queryParameters: {'route_sheet_id': routeSheetId},
      );
      DispatchIntegrationLog.response(response);

      final data = response.data;
      if (data is! List) return [];

      return data.whereType<Map<String, dynamic>>().map((json) {
        final stop = TripStopModel.fromJson(json);
        final hasDeliveriesKey = json.containsKey('deliveries');
        final rawDeliveries = json['deliveries'];
        final deliveries = <DeliveryModel>[];

        if (rawDeliveries is List) {
          for (final item in rawDeliveries) {
            if (item is Map<String, dynamic>) {
              deliveries.add(
                DeliveryModel.fromJson({
                  ...item,
                  'trip_stop_id': item['trip_stop_id'] ?? stop.id,
                }),
              );
            }
          }
        }

        return TripStopRemoteBundle(
          stop: stop,
          deliveries: deliveries,
          deliveriesFromApi: hasDeliveriesKey,
        );
      }).toList();
    } on DioException catch (e) {
      DispatchIntegrationLog.error(e);
      rethrow;
    }
  }

  @override
  Future<void> submitDelivery(DeliveryModel delivery) async {
    const path = ApiConstants.deliveries;
    final payload = delivery.toApiPayload();
    DispatchIntegrationLog.request(
      method: 'POST',
      path: path,
      body: payload,
    );

    try {
      final response = await _apiClient.post(path, data: payload);
      DispatchIntegrationLog.response(response);
      // Backend responde solo {id, status}; no parseamos entrega completa.
    } on DioException catch (e) {
      DispatchIntegrationLog.error(e);
      rethrow;
    }
  }
}
