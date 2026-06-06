import 'package:flutter/material.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:orion_app/features/dispatch/presentation/widgets/stop_status_badge.dart';

class TripStopCard extends StatelessWidget {
  final TripStop stop;
  final bool isLocked;
  final VoidCallback? onTap;

  const TripStopCard({
    super.key,
    required this.stop,
    this.isLocked = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isLocked ? Colors.grey.shade200 : Colors.white;
    final textColor = isLocked ? Colors.grey.shade600 : const Color(0xFF263238);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardColor,
      elevation: isLocked ? 0 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    isLocked ? Colors.grey.shade400 : const Color(0xFF1A237E),
                child: Text(
                  '${stop.sequence}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stop.locationName.isNotEmpty)
                      Text(
                        stop.locationName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      stop.address,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor.withValues(alpha: 0.85),
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(height: 6),
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
              const SizedBox(width: 8),
              StopStatusBadge(status: stop.status),
            ],
          ),
        ),
      ),
    );
  }
}
