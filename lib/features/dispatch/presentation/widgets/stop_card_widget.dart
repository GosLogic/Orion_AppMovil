import 'package:flutter/material.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:orion_app/features/dispatch/presentation/widgets/stop_status_badge.dart';

class StopCardWidget extends StatelessWidget {
  final TripStop stop;
  final bool isLocked;
  final bool isLast;
  final VoidCallback? onTap;

  const StopCardWidget({
    super.key,
    required this.stop,
    this.isLocked = true,
    this.isLast = false,
    this.onTap,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final opacity = isLocked ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.grey.shade400
                          : const Color(0xFF1A237E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${stop.sequence}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 3,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isLocked
                            ? Colors.grey.shade300
                            : const Color(0xFF1A237E).withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Card(
                  elevation: isLocked ? 0 : 3,
                  color: isLocked ? Colors.grey.shade100 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isLocked
                          ? Colors.grey.shade300
                          : const Color(0xFF1A237E).withValues(alpha: 0.15),
                    ),
                  ),
                  child: InkWell(
                    onTap: isLocked ? null : onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stop.displayName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isLocked
                                        ? Colors.grey.shade600
                                        : const Color(0xFF263238),
                                  ),
                                ),
                              ),
                              StopStatusBadge(status: stop.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 20,
                                color: isLocked
                                    ? Colors.grey.shade500
                                    : const Color(0xFF1565C0),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Llegada estimada: ${_formatTime(stop.estimatedArrival)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isLocked
                                      ? Colors.grey.shade500
                                      : const Color(0xFF455A64),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            stop.address,
                            style: TextStyle(
                              fontSize: 14,
                              color: isLocked
                                  ? Colors.grey.shade500
                                  : const Color(0xFF607D8B),
                            ),
                          ),
                          if (isLocked) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Inicia jornada para desbloquear',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
