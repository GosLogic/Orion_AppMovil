import 'package:dio/dio.dart';
import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/core/network/api_client.dart';
import 'package:orion_app/features/telemetry/data/models/telemetry_batch_response_model.dart';
import 'package:orion_app/features/telemetry/data/models/vehicle_position_api_dto.dart';
import 'package:orion_app/features/telemetry/data/models/vehicle_position_model.dart';

abstract class TelemetryRemoteDataSource {
  Future<TelemetryBatchResponseModel> sendBatch(
    List<VehiclePositionModel> positions,
  );

  Future<void> sendSingle(VehiclePositionModel position);

  Future<Map<String, dynamic>?> fetchLatestPosition(String vehicleExternalId);
}

class TelemetryRemoteDataSourceImpl implements TelemetryRemoteDataSource {
  TelemetryRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<TelemetryBatchResponseModel> sendBatch(
    List<VehiclePositionModel> positions,
  ) async {
    if (positions.isEmpty) {
      return const TelemetryBatchResponseModel(accepted: 0, rejected: 0);
    }

    final payload = {
      'positions': positions
          .map((p) => VehiclePositionApiDto.fromModel(p).toJson())
          .toList(),
    };

    final response = await _apiClient.post(
      ApiConstants.vehiclePositionsBatch,
      data: payload,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return TelemetryBatchResponseModel.fromJson(data);
    }
    return const TelemetryBatchResponseModel(accepted: 0, rejected: 0);
  }

  @override
  Future<void> sendSingle(VehiclePositionModel position) async {
    final payload = VehiclePositionApiDto.fromModel(position).toJson();
    await _apiClient.post(ApiConstants.vehiclePositions, data: payload);
  }

  @override
  Future<Map<String, dynamic>?> fetchLatestPosition(
    String vehicleExternalId,
  ) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.vehiclePositionsLatest,
        queryParameters: {'vehicle_id': vehicleExternalId},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
