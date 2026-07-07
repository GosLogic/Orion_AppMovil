import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/widgets/orion_list_ui.dart';
import 'package:orion_app/features/telemetry/data/services/gps_tracker_service.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_bloc.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_state.dart';
import 'package:orion_app/features/telemetry/presentation/widgets/live_route_map_widget.dart';
import 'package:orion_app/features/telemetry/presentation/widgets/position_indicator.dart';
import 'package:orion_app/injection_container.dart';

class TelemetryStatusPage extends StatelessWidget {
  const TelemetryStatusPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final gpsService = sl.get<GpsTrackerService>();

    final content = BlocBuilder<TelemetryBloc, TelemetryState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (embedded)
              const OrionSectionHeader(
                icon: Icons.explore_outlined,
                title: 'Tu ruta en vivo',
                subtitle: 'Mapa real · calles y posición GPS en tiempo real',
              ),
            LiveRouteMapWidget(
              isTracking: state.isTrackingActive,
              positionListenable: gpsService.lastPosition,
              isSyncing: state.isSyncing,
              pendingCount: state.pendingCount,
            ),
            const SizedBox(height: 14),
            PositionIndicator(
              isTracking: state.isTrackingActive,
              isSyncing: state.isSyncing,
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: OrionColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: OrionColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: OrionColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: OrionColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );

    if (embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Telemetría')),
      body: content,
    );
  }
}
