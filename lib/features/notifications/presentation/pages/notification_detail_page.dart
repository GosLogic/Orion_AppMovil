import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/widgets/orion_decorations.dart';
import 'package:orion_app/core/widgets/orion_list_ui.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:orion_app/features/notifications/presentation/utils/notification_type_style.dart';

class NotificationDetailPage extends StatefulWidget {
  const NotificationDetailPage({super.key, required this.notificationId});

  final String notificationId;

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<NotificationsBloc>()
        .add(LoadNotificationDetail(widget.notificationId));
  }

  @override
  Widget build(BuildContext context) {
    return OrionPageScaffold(
      title: 'Alerta',
      body: BlocConsumer<NotificationsBloc, NotificationsState>(
        listenWhen: (prev, curr) =>
            curr.errorMessage != null && !curr.isLoadingDetail,
        listener: (context, state) {
          if (state.errorMessage != null &&
              state.selectedNotification == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: OrionColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoadingDetail && state.selectedNotification == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final notification = state.selectedNotification;
          if (notification == null) {
            return OrionEmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No se pudo cargar la alerta',
              subtitle: 'Revisa tu conexión e intenta de nuevo',
            );
          }

          final style = NotificationTypeStyle.forType(notification.type);
          final isRead = state.isEffectivelyRead(notification);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OrionSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: style.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            style.icon,
                            color: style.color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.typeLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: style.color,
                                ),
                              ),
                              Text(
                                notification.channelLabel,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        OrionStatusChip(
                          label: isRead ? 'Leída' : 'Nueva',
                          color: isRead
                              ? OrionColors.success
                              : OrionColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: OrionColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OrionSurfaceCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    OrionDetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'Enviada',
                      value: formatNotificationDate(notification.sentAt),
                    ),
                    const Divider(height: 24),
                    OrionDetailRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Usuario',
                      value: notification.userId,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
