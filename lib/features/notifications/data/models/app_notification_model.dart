import 'package:orion_app/features/notifications/domain/entities/app_notification.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.message,
    required super.type,
    required super.channel,
    required super.isRead,
    required super.sentAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: _parseType(json['type'] as String?),
      channel: _parseChannel(json['channel'] as String?),
      isRead: json['is_read'] == true,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }

  static NotificationType _parseType(String? value) {
    return switch (value?.toUpperCase()) {
      'ALARM' => NotificationType.alarm,
      'SUCCESS' => NotificationType.success,
      'WARNING' => NotificationType.warning,
      _ => NotificationType.info,
    };
  }

  static NotificationChannel _parseChannel(String? value) {
    return switch (value?.toUpperCase()) {
      'PUSH' => NotificationChannel.push,
      'SMS' => NotificationChannel.sms,
      _ => NotificationChannel.email,
    };
  }

  AppNotification toEntity() => AppNotification(
        id: id,
        userId: userId,
        title: title,
        message: message,
        type: type,
        channel: channel,
        isRead: isRead,
        sentAt: sentAt,
      );
}
