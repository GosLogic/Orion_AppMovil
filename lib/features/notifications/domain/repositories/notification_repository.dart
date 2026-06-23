import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Result<List<AppNotification>>> getNotificationsForCurrentDriver();

  Future<Result<AppNotification>> getNotificationById(String id);
}
