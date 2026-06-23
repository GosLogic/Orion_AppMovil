import 'package:flutter/material.dart';
import 'package:orion_app/features/notifications/domain/entities/app_notification.dart';

class NotificationTypeStyle {
  final IconData icon;
  final Color color;
  final Color background;

  const NotificationTypeStyle({
    required this.icon,
    required this.color,
    required this.background,
  });

  static NotificationTypeStyle forType(NotificationType type) {
    return switch (type) {
      NotificationType.alarm => const NotificationTypeStyle(
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFC62828),
          background: Color(0xFFFFEBEE),
        ),
      NotificationType.warning => const NotificationTypeStyle(
          icon: Icons.report_problem_outlined,
          color: Color(0xFFE65100),
          background: Color(0xFFFFF3E0),
        ),
      NotificationType.success => const NotificationTypeStyle(
          icon: Icons.check_circle_outline,
          color: Color(0xFF2E7D32),
          background: Color(0xFFE8F5E9),
        ),
      NotificationType.info => const NotificationTypeStyle(
          icon: Icons.info_outline,
          color: Color(0xFF1565C0),
          background: Color(0xFFE3F2FD),
        ),
    };
  }
}

String formatNotificationDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
