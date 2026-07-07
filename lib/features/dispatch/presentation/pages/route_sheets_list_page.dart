import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/sync/sync_manager.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/widgets/orion_list_ui.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_bloc.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_event.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_state.dart';
import 'package:orion_app/features/dispatch/presentation/pages/route_home_page.dart';
import 'package:orion_app/injection_container.dart';

/// Lista todas las hojas de ruta del conductor (GET /dispatch/route-sheets).
class RouteSheetsListPage extends StatefulWidget {
  const RouteSheetsListPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<RouteSheetsListPage> createState() => _RouteSheetsListPageState();
}

class _RouteSheetsListPageState extends State<RouteSheetsListPage> {
  @override
  void initState() {
    super.initState();
    context.read<DispatchBloc>().add(const LoadRouteSheets());
  }

  @override
  Widget build(BuildContext context) {
    final content = _RouteSheetsBody(
      onRefresh: _refresh,
      onOpenRoute: _openRouteDetail,
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: OrionColors.background,
      appBar: AppBar(
        title: const Text('Mis Hojas de Ruta'),
        actions: [
          const _SyncStatusIcon(),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: content,
    );
  }

  Future<void> _refresh() async {
    context.read<DispatchBloc>().add(const LoadRouteSheets());
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  void _openRouteDetail(BuildContext context, RouteSheet sheet) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RouteHomePage(routeSheetId: sheet.id),
      ),
    );
    if (!context.mounted) return;
    context.read<DispatchBloc>().add(const LoadRouteSheets());
  }
}

class _RouteSheetsBody extends StatelessWidget {
  const _RouteSheetsBody({
    required this.onRefresh,
    required this.onOpenRoute,
  });

  final Future<void> Function() onRefresh;
  final void Function(BuildContext context, RouteSheet sheet) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DispatchBloc, DispatchState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: OrionColors.error,
              ),
            );
        }
      },
      child: BlocBuilder<DispatchBloc, DispatchState>(
        builder: (context, state) {
          if (state.status == DispatchStatus.loading &&
              state.routeSheets.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: OrionColors.primary),
            );
          }

          if (state.routeSheets.isEmpty) {
            return RefreshIndicator(
              color: OrionColors.primary,
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.55,
                    child: OrionEmptyState(
                      icon: Icons.route_outlined,
                      title: state.infoMessage ??
                          'No tienes hojas de ruta asignadas',
                      subtitle: 'Desliza hacia abajo para actualizar',
                    ),
                  ),
                ],
              ),
            );
          }

          final inProgress = state.routeSheets
              .where((s) => s.status == RouteSheetStatus.inProgress)
              .length;

          return RefreshIndicator(
            color: OrionColors.primary,
            onRefresh: onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: state.routeSheets.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return OrionSectionHeader(
                    icon: Icons.local_shipping_outlined,
                    title: 'Tus rutas de hoy',
                    subtitle: inProgress > 0
                        ? '$inProgress en curso · ${state.routeSheets.length} total'
                        : '${state.routeSheets.length} hoja(s) asignada(s)',
                    count: state.routeSheets.length,
                  );
                }

                final sheet = state.routeSheets[index - 1];
                return _RouteSheetCard(
                  sheet: sheet,
                  onTap: () => onOpenRoute(context, sheet),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RouteSheetCard extends StatelessWidget {
  const _RouteSheetCard({
    required this.sheet,
    required this.onTap,
  });

  final RouteSheet sheet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final plate = sheet.vehiclePlate.isNotEmpty
        ? sheet.vehiclePlate
        : (sheet.vehicleId ?? 'Sin placa');
    final dateLabel =
        '${sheet.scheduledDate.day.toString().padLeft(2, '0')}/'
        '${sheet.scheduledDate.month.toString().padLeft(2, '0')}/'
        '${sheet.scheduledDate.year}';
    final (statusLabel, statusColor) = _statusStyle(sheet.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OrionColors.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: OrionColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: OrionColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OrionStatusChip(
                            label: statusLabel,
                            color: statusColor,
                          ),
                        ],
                      ),
                      if (sheet.vehicleModel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          sheet.vehicleModel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: OrionColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              dateLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: OrionColors.primary.withValues(alpha: 0.6),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, Color) _statusStyle(RouteSheetStatus status) {
    return switch (status) {
      RouteSheetStatus.draft => ('BORRADOR', OrionColors.textMuted),
      RouteSheetStatus.assigned => ('ASIGNADA', OrionColors.primaryLight),
      RouteSheetStatus.inProgress => ('EN CURSO', OrionColors.accent),
      RouteSheetStatus.completed => ('COMPLETADA', OrionColors.success),
    };
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
            ? OrionColors.warning
            : OrionColors.accentSoft;

        return Tooltip(
          message: !syncState.isOnline
              ? 'Sin red'
              : hasPending
                  ? '${syncState.pendingCount} pendientes'
                  : 'Sincronizado',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.cloud_rounded, color: color, size: 24),
          ),
        );
      },
    );
  }
}
