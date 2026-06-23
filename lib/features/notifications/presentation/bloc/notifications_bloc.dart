import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/notifications/domain/usecases/get_notification_detail_usecase.dart';
import 'package:orion_app/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required GetNotificationsUseCase getNotificationsUseCase,
    required GetNotificationDetailUseCase getNotificationDetailUseCase,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _getNotificationDetailUseCase = getNotificationDetailUseCase,
        super(const NotificationsState()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<LoadNotificationDetail>(_onLoadNotificationDetail);
    on<MarkNotificationViewedLocally>(_onMarkViewedLocally);
    on<ClearNotificationDetail>(_onClearDetail);
  }

  final GetNotificationsUseCase _getNotificationsUseCase;
  final GetNotificationDetailUseCase _getNotificationDetailUseCase;

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: NotificationsStatus.loading,
        clearError: true,
      ),
    );

    final result = await _getNotificationsUseCase();
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: NotificationsStatus.loaded,
            notifications: value,
            clearError: true,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            status: NotificationsStatus.error,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearError: true));

    final result = await _getNotificationsUseCase();
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: NotificationsStatus.loaded,
            notifications: value,
            isRefreshing: false,
            clearError: true,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            status: state.notifications.isEmpty
                ? NotificationsStatus.error
                : NotificationsStatus.loaded,
            errorMessage: failure.message,
            isRefreshing: false,
          ),
        );
    }
  }

  Future<void> _onLoadNotificationDetail(
    LoadNotificationDetail event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(isLoadingDetail: true, clearError: true));

    final result = await _getNotificationDetailUseCase(event.notificationId);
    switch (result) {
      case Success(:final value):
        final viewed = {...state.locallyViewedIds, value.id};
        emit(
          state.copyWith(
            selectedNotification: value,
            locallyViewedIds: viewed,
            isLoadingDetail: false,
            clearError: true,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            isLoadingDetail: false,
            errorMessage: failure.message,
          ),
        );
    }
  }

  void _onMarkViewedLocally(
    MarkNotificationViewedLocally event,
    Emitter<NotificationsState> emit,
  ) {
    emit(
      state.copyWith(
        locallyViewedIds: {...state.locallyViewedIds, event.notificationId},
      ),
    );
  }

  void _onClearDetail(
    ClearNotificationDetail event,
    Emitter<NotificationsState> emit,
  ) {
    emit(state.copyWith(clearSelected: true));
  }
}
