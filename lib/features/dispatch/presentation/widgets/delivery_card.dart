import 'package:flutter/material.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/widgets/orion_list_ui.dart';
import 'package:orion_app/features/dispatch/domain/entities/delivery.dart';

class DeliveryCard extends StatelessWidget {
  const DeliveryCard({super.key, required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = delivery.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done
              ? OrionColors.success.withValues(alpha: 0.2)
              : OrionColors.primary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: OrionColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: done
                    ? OrionColors.success.withValues(alpha: 0.12)
                    : OrionColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                done ? Icons.check_circle_rounded : Icons.inventory_2_outlined,
                color: done ? OrionColors.success : OrionColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.customerName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (delivery.packageDescription.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      delivery.packageDescription,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            if (done)
              const OrionStatusChip(
                label: 'Entregado',
                color: OrionColors.success,
              )
            else
              const OrionStatusChip(
                label: 'Pendiente',
                color: OrionColors.warning,
              ),
          ],
        ),
      ),
    );
  }
}
