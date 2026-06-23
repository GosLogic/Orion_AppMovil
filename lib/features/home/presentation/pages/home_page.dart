import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/sync/sync_manager.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:orion_app/features/dispatch/presentation/pages/route_sheets_list_page.dart';
import 'package:orion_app/features/incidents/presentation/pages/maintenance_history_page.dart';
import 'package:orion_app/features/incidents/presentation/pages/report_incident_page.dart';
import 'package:orion_app/features/notifications/presentation/pages/notifications_list_page.dart';
import 'package:orion_app/features/telemetry/presentation/pages/telemetry_status_page.dart';
import 'package:orion_app/injection_container.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
                                                                      
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orion Driver'),
        actions: [
          ValueListenableBuilder<SyncManagerState>(
            valueListenable: sl.get<SyncManager>().stateNotifier,
            builder: (context, syncState, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Icon(
                    syncState.isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: syncState.isOnline ? Colors.green : Colors.orange,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: ListView(
        children: [
          _HomeTile(
            icon: Icons.route,
            title: 'Hojas de ruta',
            subtitle: 'Paradas y entregas',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RouteSheetsListPage()),
            ),
          ),
          _HomeTile(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Alertas e información del conductor',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsListPage()),
            ),
          ),
          _HomeTile(
            icon: Icons.build_circle_outlined,
            title: 'Mantenimiento',
            subtitle: 'Historial de solicitudes locales',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MaintenanceHistoryPage()),
            ),
          ),
          _HomeTile(
            icon: Icons.gps_fixed,
            title: 'Telemetría',
            subtitle: 'Captura y sincronización GPS',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TelemetryStatusPage()),
            ),
          ),
          _HomeTile(
            icon: Icons.report_problem,
            title: 'Incidentes',
            subtitle: 'Reportes y botón de pánico',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportIncidentPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
