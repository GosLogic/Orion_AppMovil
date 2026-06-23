import 'package:dio/dio.dart';
import 'package:orion_app/core/error/failures.dart';
import 'package:orion_app/core/network/auth_token_provider.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:orion_app/features/notifications/data/utils/notification_error_mapper.dart';
import 'package:orion_app/features/notifications/domain/entities/app_notification.dart';
import 'package:orion_app/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required NotificationRemoteDataSource remoteDataSource,
    required AuthTokenProvider tokenProvider,
  })  : _remoteDataSource = remoteDataSource,
        _tokenProvider = tokenProvider;

  final NotificationRemoteDataSource _remoteDataSource;
  final AuthTokenProvider _tokenProvider;

  @override
  Future<Result<List<AppNotification>>> getNotificationsForCurrentDriver() async {
    try {
      final driverId = await _tokenProvider.getDriverId();
      if (driverId == null || driverId.isEmpty) {
        return const Error(
          AuthFailure('No hay conductor en sesión para filtrar notificaciones.'),
        );
      }

      final all = await _remoteDataSource.fetchAll();
      final filtered = all
          .where((n) => n.userId == driverId)
          .map((n) => n.toEntity())
          .toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

      return Success(filtered);
    } on DioException catch (e) {
      return Error(NetworkFailure(mapNotificationError(e)));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<AppNotification>> getNotificationById(String id) async {
    try {
      final driverId = await _tokenProvider.getDriverId();
      final notification = await _remoteDataSource.fetchById(id);

      if (driverId != null &&
          driverId.isNotEmpty &&
          notification.userId != driverId) {
        return const Error(
          ValidationFailure('Esta notificación no pertenece a tu usuario.'),
        );
      }

      return Success(notification.toEntity());
    } on DioException catch (e) {
      return Error(NetworkFailure(mapNotificationError(e)));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}
