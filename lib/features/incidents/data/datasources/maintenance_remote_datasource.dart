import 'package:dio/dio.dart';
import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/core/network/maintenance_api_client.dart';
import 'package:orion_app/features/incidents/data/models/maintenance_request_model.dart';
import 'package:orion_app/features/incidents/data/models/maintenance_submit_response_model.dart';

abstract class MaintenanceRemoteDataSource {
  Future<MaintenanceSubmitResponseModel> createRequest(
    MaintenanceRequestModel request,
  );

  Future<Map<String, dynamic>?> getRequestById(String externalId);
}

class MaintenanceRemoteDataSourceImpl implements MaintenanceRemoteDataSource {
  MaintenanceRemoteDataSourceImpl({required MaintenanceApiClient apiClient})
      : _apiClient = apiClient;

  final MaintenanceApiClient _apiClient;

  @override
  Future<MaintenanceSubmitResponseModel> createRequest(
    MaintenanceRequestModel request,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.maintenanceRequests,
      data: request.toApiJson(),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return MaintenanceSubmitResponseModel.fromJson(data);
    }
    return MaintenanceSubmitResponseModel(id: request.id, status: 'PENDING');
  }

  @override
  Future<Map<String, dynamic>?> getRequestById(String externalId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.maintenanceRequests}/$externalId',
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
