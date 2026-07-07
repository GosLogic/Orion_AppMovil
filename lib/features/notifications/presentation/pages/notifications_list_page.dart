import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/widgets/orion_list_ui.dart';
import 'package:orion_app/features/notifications/domain/entities/app_notification.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:orion_app/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:orion_app/features/notifications/presentation/utils/notification_type_style.dart';

class NotificationsListPage extends StatefulWidget {
  const NotificationsListPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<NotificationsListPage> createState() => _NotificationsListPageState();
}

class _NotificationsListPageState extends State<NotificationsListPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(const LoadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final body = BlocConsumer<NotificationsBloc, NotificationsState>(
        listenWhen: (prev, curr) =>
            curr.errorMessage != null &&
            !curr.isRefreshing &&
            curr.status != NotificationsStatus.loading,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: const Color(0xFFC62828),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Reintentar',
                    textColor: Colors.white,
                    onPressed: () => context
                        .read<NotificationsBloc>()
                        .add(const LoadNotifications()),
                  ),
                ),
              );
          }
        },
        builder: (context, state) {
          if (state.status == NotificationsStatus.loading &&
              state.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A237E)),
            );
          }

          if (state.status == NotificationsStatus.error &&
              state.notifications.isEmpty) {
            return _ErrorState(
              message: state.errorMessage ??
                  'No se pudieron cargar las notificaciones.',
              onRetry: () => context
                  .read<NotificationsBloc>()
                  .add(const LoadNotifications()),
            );
          }

          if (state.notifications.isEmpty) {
            return RefreshIndicator(
              color: OrionColors.primary,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: const OrionEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'Sin notificaciones',
                      subtitle: 'Las alertas del operador aparecerán aquí',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: OrionColors.primary,
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: state.notifications.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final unread = state.notifications
                      .where((n) => !state.isEffectivelyRead(n))
                      .length;
                  return OrionSectionHeader(
                    icon: Icons.notifications_active_outlined,
                    title: 'Bandeja de alertas',
                    subtitle: unread > 0
                        ? '$unread sin leer'
                        : 'Todo al día',
                    count: state.notifications.length,
                  );
                }
                final notification = state.notifications[index - 1];
                return _NotificationCard(
                  notification: notification,
                  isRead: state.isEffectivelyRead(notification),
                  onTap: () => _openDetail(context, notification),
                );
              },
            ),
          );
        },
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }

  Future<void> _refresh() async {
    context.read<NotificationsBloc>().add(const RefreshNotifications());
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _openDetail(
    BuildContext context,
    AppNotification notification,
  ) async {
    context
        .read<NotificationsBloc>()
        .add(MarkNotificationViewedLocally(notification.id));

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationDetailPage(notificationId: notification.id),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = NotificationTypeStyle.forType(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRead
              ? Colors.transparent
              : OrionColors.primary.withValues(alpha: 0.15),
          width: isRead ? 0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: OrionColors.primary.withValues(alpha: isRead ? 0.04 : 0.08),
            blurRadius: isRead ? 8 : 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: style.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(style.icon, color: style.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    isRead ? FontWeight.w600 : FontWeight.w800,
                                color: OrionColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: const BoxDecoration(
                                color: OrionColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OrionStatusChip(
                            label: notification.typeLabel,
                            color: style.color,
                          ),
                          Text(
                            formatNotificationDate(notification.sentAt),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: OrionColors.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Color(0xFFC62828),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF455A64),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
