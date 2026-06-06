import 'package:flutter/material.dart';

class PositionIndicator extends StatelessWidget {
  final bool isTracking;
  final int unsyncedCount;

  const PositionIndicator({
    super.key,
    required this.isTracking,
    this.unsyncedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isTracking ? Icons.gps_fixed : Icons.gps_off,
          color: isTracking ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(isTracking ? 'Telemetría activa' : 'Telemetría inactiva'),
        if (unsyncedCount > 0) ...[
          const SizedBox(width: 8),
          Chip(
            label: Text('$unsyncedCount pendientes'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }
}
