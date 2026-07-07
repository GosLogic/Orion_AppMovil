import 'package:flutter/material.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:orion_app/features/dispatch/presentation/widgets/stop_status_badge.dart';

class StopCardWidget extends StatelessWidget {
  const StopCardWidget({
    super.key,
    required this.stop,
    this.isLocked = true,
    this.isLast = false,
    this.onTap,
    this.onNavigate,
  });

  final TripStop stop;
  final bool isLocked;
  final bool isLast;
  final VoidCallback? onTap;
  final VoidCallback? onNavigate;

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodeColor =
        isLocked ? OrionColors.textMuted : OrionColors.primary;
    final lineColor = isLocked
        ? Colors.grey.shade300
        : OrionColors.primaryLight.withValues(alpha: 0.35);

    return Opacity(
      opacity: isLocked ? 0.55 : 1.0,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: isLocked
                          ? null
                          : OrionColors.primaryGradient,
                      color: isLocked ? Colors.grey.shade400 : null,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: isLocked
                          ? null
                          : [
                              BoxShadow(
                                color: OrionColors.primary
                                    .withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Text(
                        '${stop.sequence}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 3,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: lineColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: Material(
                  color: isLocked
                      ? OrionColors.surface
                      : OrionColors.surfaceCard,
                  elevation: isLocked ? 0 : 2,
                  shadowColor: OrionColors.primary.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isLocked
                          ? Colors.grey.shade200
                          : OrionColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: InkWell(
                    onTap: isLocked ? null : onTap,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  stop.displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isLocked
                                        ? OrionColors.textMuted
                                        : OrionColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StopStatusBadge(status: stop.status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 18,
                                color: isLocked
                                    ? OrionColors.textMuted
                                    : OrionColors.primaryLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ETA ${_formatTime(stop.estimatedArrival)}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: isLocked
                                      ? OrionColors.textMuted
                                      : OrionColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 18,
                                color: nodeColor.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  stop.address,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isLocked
                                        ? OrionColors.textMuted
                                        : OrionColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (onNavigate != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: OrionColors.accent,
                                  side: BorderSide(
                                    color: OrionColors.accent.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: onNavigate,
                                icon: const Icon(
                                  Icons.navigation_rounded,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Abrir en Waze',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (isLocked) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Inicia jornada para desbloquear',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
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
