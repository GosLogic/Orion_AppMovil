import 'package:flutter/material.dart';
import 'package:orion_app/core/theme/orion_colors.dart';

/// Indicador compacto de estado GPS (sin detalles técnicos).
class PositionIndicator extends StatelessWidget {
  const PositionIndicator({
    super.key,
    required this.isTracking,
    this.isSyncing = false,
  });

  final bool isTracking;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = isTracking;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: active
            ? OrionColors.accent.withValues(alpha: 0.08)
            : OrionColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? OrionColors.accent.withValues(alpha: 0.25)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: active ? OrionColors.accent : OrionColors.textMuted,
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: OrionColors.accent.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              active ? 'GPS conectado con operaciones' : 'GPS en espera',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: active
                    ? OrionColors.primary
                    : OrionColors.textSecondary,
              ),
            ),
          ),
          if (isSyncing)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
