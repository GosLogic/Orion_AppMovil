import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:orion_app/features/notifications/presentation/utils/notification_type_style.dart';

class NotificationDetailPage extends StatefulWidget {
  final String notificationId;

  const NotificationDetailPage({
    super.key,
    required this.notificationId,
  });

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
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: const Text(
          'Detalle',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<NotificationsBloc, NotificationsState>(
        listenWhen: (prev, curr) =>
            curr.errorMessage != null && !curr.isLoadingDetail,
        listener: (context, state) {
          if (state.errorMessage != null && state.selectedNotification == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: const Color(0xFFC62828),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoadingDetail && state.selectedNotification == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A237E)),
            );
          }

          final notification = state.selectedNotification;
          if (notification == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No se pudo cargar la notificación.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<NotificationsBloc>().add(
                          LoadNotificationDetail(widget.notificationId),
                        ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final style = NotificationTypeStyle.forType(notification.type);
          final isRead = state.isEffectivelyRead(notification);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
                                size: 30,
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
                                    style: const TextStyle(
                                      color: Color(0xFF78909C),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _ReadBadge(isRead: isRead),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          notification.message,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Color(0xFF455A64),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Fecha de envío',
                          value: formatNotificationDate(notification.sentAt),
                        ),
                        const Divider(height: 24),
                        _DetailRow(
                          label: 'Usuario',
                          value: notification.userId,
                        ),
                        const Divider(height: 24),
                        _DetailRow(
                          label: 'ID',
                          value: notification.id,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'El estado "leída" es informativo. El backend aún no permite marcar como leída vía API.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF78909C),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReadBadge extends StatelessWidget {
  final bool isRead;

  const _ReadBadge({required this.isRead});

  @override
  Widget build(BuildContext context) {
    final color =
        isRead ? const Color(0xFF2E7D32) : const Color(0xFF1A237E);
    final label = isRead ? 'Leída' : 'Nueva';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF78909C),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF263238),
            ),
          ),
        ),
      ],
    );
  }
}
