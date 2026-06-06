import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_bloc.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_state.dart';
import 'package:orion_app/features/telemetry/presentation/widgets/position_indicator.dart';

class TelemetryStatusPage extends StatelessWidget {
  const TelemetryStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telemetría')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<TelemetryBloc, TelemetryState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PositionIndicator(isTracking: state.isTrackingActive),
                const SizedBox(height: 16),
                if (state.activeVehicleId != null)
                  Text('Vehículo: ${state.activeVehicleId}'),
                if (state.activeRouteSheetId != null)
                  Text('Hoja de ruta: ${state.activeRouteSheetId}'),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'La telemetría se inicia y detiene automáticamente '
                  'al pulsar INICIAR / FINALIZAR JORNADA en Mi Ruta.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
