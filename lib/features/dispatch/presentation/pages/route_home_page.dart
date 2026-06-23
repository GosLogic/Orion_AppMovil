import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/sync/sync_manager.dart';
import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_bloc.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_event.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_state.dart';
import 'package:orion_app/features/dispatch/presentation/pages/stop_detail_page.dart';
import 'package:orion_app/features/dispatch/presentation/widgets/stop_card_widget.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_bloc.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_event.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_state.dart';
import 'package:orion_app/features/incidents/presentation/pages/report_maintenance_page.dart';
import 'package:orion_app/injection_container.dart';

class RouteHomePage extends StatefulWidget {
  final String routeSheetId;

  const RouteHomePage({super.key, required this.routeSheetId});

  @override
  State<RouteHomePage> createState() => _RouteHomePageState();
}

class _RouteHomePageState extends State<RouteHomePage> {
  @override
  void initState() {
    super.initState();
    context.read<DispatchBloc>().add(LoadRouteSheet(widget.routeSheetId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: const Text(
          'Hoja de Ruta',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          const _GpsStatusChip(),
          const _SyncStatusIcon(),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<DispatchBloc, DispatchState>(
            listenWhen: (prev, curr) =>
                prev.dailyRoute?.status != curr.dailyRoute?.status,
            listener: _syncTelemetryWithJornada,
          ),
          BlocListener<TelemetryBloc, TelemetryState>(
            listenWhen: (prev, curr) =>
                prev.warningMessage != curr.warningMessage &&
                curr.warningMessage != null,
            listener: (context, state) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.warningMessage!),
                    backgroundColor: const Color(0xFFE65100),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            },
          ),
        ],
        child: BlocListener<DispatchBloc, DispatchState>(
        listener: _handleDispatchMessages,
        child: BlocBuilder<DispatchBloc, DispatchState>(
          builder: (context, state) {
          if (state.status == DispatchStatus.loading &&
              state.dailyRoute == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A237E)),
            );
          }

          if (state.dailyRoute == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.route_outlined,
                      size: 64,
                      color: Color(0xFF455A64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.infoMessage ??
                          'No tienes una hoja de ruta asignada.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF455A64),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Desliza hacia abajo para actualizar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final route = state.dailyRoute!;
          final isSubmitting = state.status == DispatchStatus.submitting;

          return RefreshIndicator(
            color: const Color(0xFF1A237E),
            onRefresh: () async {
              context
                  .read<DispatchBloc>()
                  .add(LoadRouteSheet(widget.routeSheetId));
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _RouteHeader(
                    route: route,
                    stopsCount: state.tripStops.length,
                    isSubmitting: isSubmitting,
                    canStart: state.canStartJornada,
                    canEnd: state.canEndJornada,
                    onStart: () =>
                        context.read<DispatchBloc>().add(const StartJornada()),
                    onEnd: () =>
                        context.read<DispatchBloc>().add(const EndJornada()),
                    onMaintenance: () => _openMaintenanceReport(context, route),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Paradas (${state.tripStops.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final stop = state.tripStops[index];
                        return StopCardWidget(
                          stop: stop,
                          isLocked: !state.isJornadaActive,
                          isLast: index == state.tripStops.length - 1,
                          onTap: () => _openStopDetail(context, stop),
                        );
                      },
                      childCount: state.tripStops.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        ),
        ),
      ),
    );
  }

  void _syncTelemetryWithJornada(BuildContext context, DispatchState state) {
    final route = state.dailyRoute;
    if (route == null) return;

    final telemetryBloc = context.read<TelemetryBloc>();

    if (route.isJornadaActive) {
      final vehicleId = route.telemetryVehicleId;
      final routeSheetId = route.telemetryRouteSheetId;

      if (vehicleId == null || routeSheetId == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo resolver vehicle_id/route_sheet_id desde la hoja '
                'de ruta. Revisa que el backend envíe vehicle_id en la respuesta.',
              ),
              backgroundColor: Color(0xFFE65100),
              behavior: SnackBarBehavior.floating,
            ),
          );
        return;
      }

      telemetryBloc.add(
        StartTelemetry(
          vehicleId: vehicleId,
          routeSheetId: routeSheetId,
        ),
      );
    } else if (route.status == RouteSheetStatus.completed) {
      telemetryBloc.add(const StopTelemetry());
    }
  }

  void _handleDispatchMessages(BuildContext context, DispatchState state) {
    if (state.successMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              state.successMessage!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              state.errorMessage!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _openMaintenanceReport(BuildContext context, RouteSheet route) {
    final vehicleId = route.vehicleId;
    if (vehicleId == null || vehicleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay vehículo asignado en esta hoja de ruta'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportMaintenancePage(vehicleId: vehicleId),
      ),
    );
  }

  void _openStopDetail(BuildContext context, TripStop stop) {
    context.read<DispatchBloc>().add(LoadStopDeliveries(stop.id));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StopDetailPage(tripStop: stop),
      ),
    );
  }
}

class _GpsStatusChip extends StatelessWidget {
  const _GpsStatusChip();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(
      builder: (context, state) {
        final hasError = state.status == TelemetryStatus.gpsError;
        final isActive = state.isTrackingActive;
        final pending = state.pendingCount;

        final Color color;
        final IconData icon;
        if (hasError) {
          color = const Color(0xFFFF5252);
          icon = Icons.gps_not_fixed;
        } else if (isActive) {
          color = const Color(0xFF00E676);
          icon = Icons.gps_fixed;
        } else {
          color = Colors.white54;
          icon = Icons.gps_off;
        }

        String tooltip;
        if (hasError) {
          tooltip = state.errorMessage ?? 'Error de GPS';
        } else if (!isActive) {
          tooltip = 'GPS inactivo (inicia jornada para activar)';
        } else if (state.isSyncing) {
          tooltip = 'Sincronizando posiciones...';
        } else if (pending > 0) {
          tooltip = 'GPS activo · $pending pendientes de envío';
        } else if (state.lastSyncedAt != null) {
          final mins =
              DateTime.now().difference(state.lastSyncedAt!).inMinutes;
          tooltip = mins < 1
              ? 'GPS activo · enviado al servidor'
              : 'GPS activo · última sync hace $mins min';
        } else {
          tooltip = 'GPS activo · capturando (aún sin sync)';
        }

        return Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: hasError
                ? () => _showGpsHelpDialog(context, state.errorMessage)
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 22),
                  if (isActive && pending > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$pending',
                        style: const TextStyle(
                          color: Color(0xFF263238),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGpsHelpDialog(BuildContext context, String? error) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('GPS no disponible'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null) ...[
                Text(error, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
              ],
              const Text(
                'Cómo comprobar que funciona:\n'
                '1. Acepta el permiso de ubicación.\n'
                '2. Emulador Android: menú ⋯ → Location → elige una ciudad.\n'
                '3. Teléfono: activa GPS en Ajustes.\n'
                '4. Inicia jornada de nuevo.\n'
                '5. En consola busca [GPS] Guardado local.\n'
                '6. Chip verde = capturando; número amarillo = pendientes.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusIcon extends StatelessWidget {
  const _SyncStatusIcon();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncManagerState>(
      valueListenable: sl.get<SyncManager>().stateNotifier,
      builder: (context, syncState, _) {
        final hasPending = syncState.pendingCount > 0;
        final color = !syncState.isOnline || hasPending
            ? const Color(0xFFFFC107)
            : const Color(0xFF00E676);
        final tooltip = !syncState.isOnline
            ? 'Sin red — datos en cola local'
            : hasPending
                ? '${syncState.pendingCount} pendientes de sync'
                : 'Sincronizado';

        return Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.cloud, color: color, size: 26),
          ),
        );
      },
    );
  }
}

class _RouteHeader extends StatelessWidget {
  final RouteSheet route;
  final int stopsCount;
  final bool isSubmitting;
  final bool canStart;
  final bool canEnd;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback? onMaintenance;

  const _RouteHeader({
    required this.route,
    required this.stopsCount,
    required this.isSubmitting,
    required this.canStart,
    required this.canEnd,
    required this.onStart,
    required this.onEnd,
    this.onMaintenance,
  });

  @override
  Widget build(BuildContext context) {
    final plateLabel = route.vehiclePlate.isNotEmpty
        ? route.vehiclePlate
        : (route.vehicleId ?? 'Sin vehículo');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            color: const Color(0xFF1A237E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vehículo asignado',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plateLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            if (route.vehicleModel.isNotEmpty)
                              Text(
                                route.vehicleModel,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$stopsCount paradas · Estado: ${_statusLabel(route.status)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (canStart) _JornadaButton(
            label: 'INICIAR JORNADA',
            color: const Color(0xFF00C853),
            icon: Icons.play_arrow_rounded,
            isLoading: isSubmitting,
            onPressed: onStart,
          ),
          if (canEnd) _JornadaButton(
            label: 'FINALIZAR JORNADA',
            color: const Color(0xFFE65100),
            icon: Icons.stop_rounded,
            isLoading: isSubmitting,
            onPressed: onEnd,
          ),
          if (route.isJornadaActive) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A237E),
                  side: const BorderSide(color: Color(0xFF1A237E), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isSubmitting ? null : onMaintenance,
                icon: const Icon(Icons.build_circle_outlined),
                label: const Text(
                  'Reportar mantenimiento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
          if (!canStart && !canEnd)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Jornada completada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(RouteSheetStatus status) {
    return switch (status) {
      RouteSheetStatus.draft => 'BORRADOR',
      RouteSheetStatus.assigned => 'ASIGNADA',
      RouteSheetStatus.inProgress => 'EN CURSO',
      RouteSheetStatus.completed => 'COMPLETADA',
    };
  }
}

class _JornadaButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _JornadaButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          shadowColor: color.withValues(alpha: 0.5),
        ),
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 34),
        label: Text(
          isLoading ? 'Procesando...' : label,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
