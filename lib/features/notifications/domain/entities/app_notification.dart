import 'package:equatable/equatable.dart';

enum NotificationType { alarm, info, success, warning }

enum NotificationChannel { push, email, sms }

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationChannel channel;
  final bool isRead;
  final DateTime sentAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.channel,
    required this.isRead,
    required this.sentAt,
  });

  String get typeLabel => switch (type) {
        NotificationType.alarm => 'ALARMA',
        NotificationType.info => 'INFO',
        NotificationType.success => 'ÉXITO',
        NotificationType.warning => 'AVISO',
      };

  String get channelLabel => switch (channel) {
        NotificationChannel.push => 'PUSH',
        NotificationChannel.email => 'EMAIL',
        NotificationChannel.sms => 'SMS',
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        message,
        type,
        channel,
        isRead,
        sentAt,
      ];
}
