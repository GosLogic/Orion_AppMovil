import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/sync/sync_manager.dart';
import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_bloc.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_event.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_state.dart';
import 'package:orion_app/features/dispatch/presentation/pages/stop_detail_page.dart';
import 'package:orion_app/features/dispatch/presentation/widgets/panic_button.dart';
import 'package:orion_app/features/dispatch/presentation/widgets/stop_card_widget.dart';
import 'package:orion_app/features/telemetry/domain/utils/telemetry_id_parser.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_bloc.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_event.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_state.dart';
import 'package:orion_app/injection_container.dart';

class RouteHomePage extends StatefulWidget {
  const RouteHomePage({super.key});

  @override
  State<RouteHomePage> createState() => _RouteHomePageState();
}

class _RouteHomePageState extends State<RouteHomePage> {
  @override
  void initState() {
    super.initState();
    context.read<DispatchBloc>().add(const LoadDailyRoute());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: const Text(
          'Mi Ruta - Orion',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: const [
          _SyncStatusIcon(),
          _GpsStatusIcon(),
          SizedBox(width: 8),
        ],
      ),
      floatingActionButton: const DispatchPanicButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: MultiBlocListener(
        listeners: [
          BlocListener<DispatchBloc, DispatchState>(
            listener: _handleDispatchMessages,
          ),
          BlocListener<TelemetryBloc, TelemetryState>(
            listener: _handleTelemetryMessages,
          ),
        ],
        child: BlocBuilder<DispatchBloc, DispatchState>(
          builder: (context, state) {
          if (state.status == DispatchStatus.loading &&
              state.dailyRoute == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A237E)),
            );
          }

          if (state.dailyRoute == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay ruta asignada para hoy.\nLos horarios aparecerán aquí cuando se sincronicen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF455A64),
                  ),
                ),
              ),
            );
          }

          final route = state.dailyRoute!;
          final isSubmitting = state.status == DispatchStatus.submitting;

          return RefreshIndicator(
            color: const Color(0xFF1A237E),
            onRefresh: () async {
              context.read<DispatchBloc>().add(const LoadDailyRoute());
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
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
    );
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

      final route = state.dailyRoute;
      if (route != null) {
        if (state.successMessage!.contains('Jornada iniciada')) {
          context.read<TelemetryBloc>().add(
                StartTelemetry(
                  vehicleId: parseOrionNumericId(route.vehicleId),
                  routeSheetId: parseOrionNumericId(route.id),
                ),
              );
        } else if (state.successMessage!.contains('Jornada finalizada')) {
          context.read<TelemetryBloc>().add(const StopTelemetry());
        }
      }
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

  void _handleTelemetryMessages(BuildContext context, TelemetryState state) {
    if (state.status == TelemetryStatus.gpsError &&
        state.errorMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Error GPS: ${state.errorMessage}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
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

class _GpsStatusIcon extends StatelessWidget {
  const _GpsStatusIcon();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(
      builder: (context, state) {
        final isActive = state.isTrackingActive;
        final hasError = state.status == TelemetryStatus.gpsError;
        final color = isActive
            ? const Color(0xFF00E676)
            : hasError
                ? const Color(0xFFFFC107)
                : const Color(0xFFD50000);
        final tooltip = isActive
            ? 'Telemetría GPS activa (cada 5s)'
            : hasError
                ? 'Error GPS — revisa permisos'
                : 'GPS inactivo — inicia la jornada';

        return Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Icons.satellite_alt, color: color, size: 26),
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

  const _RouteHeader({
    required this.route,
    required this.stopsCount,
    required this.isSubmitting,
    required this.canStart,
    required this.canEnd,
    required this.onStart,
    required this.onEnd,
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
