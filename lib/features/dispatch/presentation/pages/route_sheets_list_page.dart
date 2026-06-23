import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/sync/sync_manager.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:orion_app/features/dispatch/domain/entities/route_sheet.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_bloc.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_event.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_state.dart';
import 'package:orion_app/features/dispatch/presentation/pages/route_home_page.dart';
import 'package:orion_app/features/notifications/presentation/pages/notifications_list_page.dart';
import 'package:orion_app/injection_container.dart';

/// Lista todas las hojas de ruta del conductor (GET /dispatch/route-sheets).
class RouteSheetsListPage extends StatefulWidget {
  const RouteSheetsListPage({super.key});

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
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: const Text(
          'Mis Hojas de Ruta',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificaciones',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsListPage(),
              ),
            ),
          ),
          const _SyncStatusIcon(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: BlocListener<DispatchBloc, DispatchState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: const Color(0xFFC62828),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        child: BlocBuilder<DispatchBloc, DispatchState>(
          builder: (context, state) {
            if (state.status == DispatchStatus.loading &&
                state.routeSheets.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A237E)),
              );
            }

            if (state.routeSheets.isEmpty) {
              return RefreshIndicator(
                color: const Color(0xFF1A237E),
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.5,
                      child: Center(
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
                                    'No tienes hojas de ruta asignadas.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF455A64),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: const Color(0xFF1A237E),
              onRefresh: _refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: state.routeSheets.length,
                itemBuilder: (context, index) {
                  final sheet = state.routeSheets[index];
                  return _RouteSheetCard(
                    sheet: sheet,
                    onTap: () => _openRouteDetail(context, sheet),
                  );
                },
              ),
            );
          },
        ),
      ),
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

class _RouteSheetCard extends StatelessWidget {
  final RouteSheet sheet;
  final VoidCallback onTap;

  const _RouteSheetCard({
    required this.sheet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final plate = sheet.vehiclePlate.isNotEmpty
        ? sheet.vehiclePlate
        : (sheet.vehicleId ?? 'Sin placa');
    final dateLabel =
        '${sheet.scheduledDate.day.toString().padLeft(2, '0')}/'
        '${sheet.scheduledDate.month.toString().padLeft(2, '0')}/'
        '${sheet.scheduledDate.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Color(0xFF1A237E),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plate,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF263238),
                      ),
                    ),
                    if (sheet.vehicleModel.isNotEmpty)
                      Text(
                        sheet.vehicleModel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF607D8B),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Fecha: $dateLabel · ${_statusLabel(sheet.status)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF455A64),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF78909C),
                size: 28,
              ),
            ],
          ),
        ),
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

        return Tooltip(
          message: !syncState.isOnline
              ? 'Sin red'
              : hasPending
                  ? '${syncState.pendingCount} pendientes'
                  : 'Sincronizado',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.cloud, color: color, size: 26),
          ),
        );
      },
    );
  }
}
