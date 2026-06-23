import 'package:equatable/equatable.dart';
import 'package:orion_app/features/notifications/domain/entities/app_notification.dart';

enum NotificationsStatus { initial, loading, loaded, error }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<AppNotification> notifications;
  final AppNotification? selectedNotification;
  final Set<String> locallyViewedIds;
  final String? errorMessage;
  final bool isRefreshing;
  final bool isLoadingDetail;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.selectedNotification,
    this.locallyViewedIds = const {},
    this.errorMessage,
    this.isRefreshing = false,
    this.isLoadingDetail = false,
  });

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? notifications,
    AppNotification? selectedNotification,
    bool clearSelected = false,
    Set<String>? locallyViewedIds,
    String? errorMessage,
    bool clearError = false,
    bool? isRefreshing,
    bool? isLoadingDetail,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      selectedNotification:
          clearSelected ? null : (selectedNotification ?? this.selectedNotification),
      locallyViewedIds: locallyViewedIds ?? this.locallyViewedIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
    );
  }

  bool isEffectivelyRead(AppNotification notification) {
    return notification.isRead || locallyViewedIds.contains(notification.id);
  }

  int get unreadCount =>
      notifications.where((n) => !isEffectivelyRead(n)).length;

  @override
  List<Object?> get props => [
        status,
        notifications,
        selectedNotification,
        locallyViewedIds,
        errorMessage,
        isRefreshing,
        isLoadingDetail,
      ];
}
