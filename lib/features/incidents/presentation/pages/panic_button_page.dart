import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_event.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_state.dart';
import 'package:orion_app/features/incidents/presentation/widgets/panic_button.dart';

class PanicButtonPage extends StatelessWidget {
  const PanicButtonPage({super.key});

  Future<void> _triggerPanic(BuildContext context) async {
    final position = await Geolocator.getCurrentPosition();
    if (!context.mounted) return;
    context.read<IncidentsBloc>().add(
          TriggerPanicAlert(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergencia'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocBuilder<IncidentsBloc, IncidentsState>(
          builder: (context, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Presiona solo en caso de emergencia real.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                IncidentsPanicButton(
                  isLoading: state.isLoading,
                  onPressed: () => _triggerPanic(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
