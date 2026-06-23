import 'package:dio/dio.dart';
import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/core/network/notification_api_client.dart';
import 'package:orion_app/features/notifications/data/models/app_notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<AppNotificationModel>> fetchAll();

  Future<AppNotificationModel> fetchById(String id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl({required NotificationApiClient apiClient})
      : _apiClient = apiClient;

  final NotificationApiClient _apiClient;

  @override
  Future<List<AppNotificationModel>> fetchAll() async {
    final response = await _apiClient.get(ApiConstants.notifications);
    final data = response.data;
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(AppNotificationModel.fromJson)
        .toList();
  }

  @override
  Future<AppNotificationModel> fetchById(String id) async {
    final response = await _apiClient.get('${ApiConstants.notifications}/$id');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return AppNotificationModel.fromJson(data);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Respuesta inválida del servidor de notificaciones.',
    );
  }
}
