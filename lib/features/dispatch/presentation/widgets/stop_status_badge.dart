import 'package:flutter/material.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';

class StopStatusBadge extends StatelessWidget {
  final TripStopStatus status;

  const StopStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.foreground, width: 1.5),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.foreground,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  _BadgeConfig _configFor(TripStopStatus status) {
    return switch (status) {
      TripStopStatus.pending => const _BadgeConfig(
          label: 'PENDIENTE',
          background: Color(0xFFFFF9C4),
          foreground: Color(0xFFF57F17),
        ),
      TripStopStatus.arrived => const _BadgeConfig(
          label: 'LLEGÓ',
          background: Color(0xFFE3F2FD),
          foreground: Color(0xFF1565C0),
        ),
      TripStopStatus.completed => const _BadgeConfig(
          label: 'COMPLETADA',
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF2E7D32),
        ),
      TripStopStatus.skipped => const _BadgeConfig(
          label: 'OMITIDA',
          background: Color(0xFFECEFF1),
          foreground: Color(0xFF546E7A),
        ),
    };
  }
}

class _BadgeConfig {
  final String label;
  final Color background;
  final Color foreground;

  const _BadgeConfig({
    required this.label,
    required this.background,
    required this.foreground,
  });
}
