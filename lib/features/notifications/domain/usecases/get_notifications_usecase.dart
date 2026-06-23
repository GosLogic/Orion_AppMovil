import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/notifications/domain/entities/app_notification.dart';
import 'package:orion_app/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Result<List<AppNotification>>> call() {
    return _repository.getNotificationsForCurrentDriver();
  }
}
