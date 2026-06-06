import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_event.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_state.dart';

class DispatchPanicButton extends StatelessWidget {
  const DispatchPanicButton({super.key});

  Future<void> _confirmAndTrigger(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFC62828),
          size: 48,
        ),
        title: const Text(
          '¿Emitir alerta de emergencia?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        content: const Text(
          'Se notificará al centro de operaciones con tu ubicación actual. '
          'Solo confirma si estás en peligro real.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'CONFIRMAR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      if (!context.mounted) return;
      context.read<IncidentsBloc>().add(
            TriggerPanicAlert(
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la ubicación GPS'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IncidentsBloc, IncidentsState>(
      listener: (context, state) {
        if (state.status == IncidentsStatus.success &&
            state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: const Color(0xFFC62828),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<IncidentsBloc, IncidentsState>(
        builder: (context, state) {
          final isLoading = state.status == IncidentsStatus.loading;

          return FloatingActionButton.extended(
            heroTag: 'dispatch_panic_fab',
            backgroundColor: const Color(0xFFD50000),
            foregroundColor: Colors.white,
            elevation: 8,
            highlightElevation: 12,
            onPressed: isLoading ? null : () => _confirmAndTrigger(context),
            icon: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sos, size: 28),
            label: const Text(
              'PÁNICO',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}
