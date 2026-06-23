import 'package:flutter_test/flutter_test.dart';
import 'package:orion_app/features/notifications/data/models/app_notification_model.dart';
import 'package:orion_app/features/notifications/domain/entities/app_notification.dart';

void main() {
  group('AppNotificationModel', () {
    test('fromJson parsea snake_case del backend', () {
      final model = AppNotificationModel.fromJson({
        'id': '1',
        'user_id': 'driver-demo',
        'title': 'Bienvenido',
        'message': 'Bienvenido al sistema Orion...',
        'type': 'INFO',
        'channel': 'EMAIL',
        'is_read': false,
        'sent_at': '2026-06-22T10:30:00',
      });

      expect(model.id, '1');
      expect(model.userId, 'driver-demo');
      expect(model.title, 'Bienvenido');
      expect(model.type, NotificationType.info);
      expect(model.channel, NotificationChannel.email);
      expect(model.isRead, isFalse);
      expect(model.sentAt, DateTime.parse('2026-06-22T10:30:00'));
    });

    test('parsea tipos ALARM y WARNING', () {
      final alarm = AppNotificationModel.fromJson({
        'id': '2',
        'user_id': 'driver-demo',
        'title': 'Alerta',
        'message': 'Pánico',
        'type': 'ALARM',
        'channel': 'PUSH',
        'is_read': true,
        'sent_at': '2026-06-22T11:00:00',
      });

      expect(alarm.type, NotificationType.alarm);
      expect(alarm.channel, NotificationChannel.push);
      expect(alarm.isRead, isTrue);
    });
  });
}
