import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {
  const LoadNotifications();
}

class RefreshNotifications extends NotificationsEvent {
  const RefreshNotifications();
}

class LoadNotificationDetail extends NotificationsEvent {
  final String notificationId;

  const LoadNotificationDetail(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkNotificationViewedLocally extends NotificationsEvent {
  final String notificationId;

  const MarkNotificationViewedLocally(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class ClearNotificationDetail extends NotificationsEvent {
  const ClearNotificationDetail();
}
