import 'package:flutter/material.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/features/dispatch/data/services/waze_navigation_service.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:orion_app/injection_container.dart';

/// Abre Waze hacia la parada (con feedback en pantalla).
Future<void> openWazeNavigation(BuildContext context, TripStop stop) async {
  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Abriendo Waze hacia ${stop.displayName}…'),
            ),
          ],
        ),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
      ),
    );

  final result = await sl.get<WazeNavigationService>().navigateToStop(stop);

  if (!context.mounted) return;

  messenger.hideCurrentSnackBar();

  if (result.ok) {
    final appLabel =
        result.app == NavigationApp.googleMaps ? 'Google Maps' : 'Waze';
    messenger.showSnackBar(
      SnackBar(
        content: Text('Navegación abierta en $appLabel'),
        backgroundColor: OrionColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  messenger.showSnackBar(
    SnackBar(
      content: Text(result.message ?? 'No se pudo abrir la navegación'),
      backgroundColor: OrionColors.error,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Reintentar',
        textColor: Colors.white,
        onPressed: () => openWazeNavigation(context, stop),
      ),
    ),
  );
}
