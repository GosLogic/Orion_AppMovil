import 'package:flutter/material.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/widgets/orion_list_ui.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';

class StopStatusBadge extends StatelessWidget {
  const StopStatusBadge({super.key, required this.status});

  final TripStopStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TripStopStatus.pending => ('Pendiente', OrionColors.warning),
      TripStopStatus.arrived => ('Llegó', OrionColors.primaryLight),
      TripStopStatus.completed => ('Completada', OrionColors.success),
      TripStopStatus.skipped => ('Omitida', OrionColors.textMuted),
    };

    return OrionStatusChip(label: label, color: color);
  }
}
