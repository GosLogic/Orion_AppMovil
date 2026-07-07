import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/sync/sync_manager.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/widgets/orion_decorations.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:orion_app/features/dispatch/presentation/pages/route_sheets_list_page.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_event.dart';
import 'package:orion_app/features/incidents/presentation/pages/maintenance_history_page.dart';
import 'package:orion_app/features/incidents/presentation/pages/report_incident_page.dart';
import 'package:orion_app/features/notifications/presentation/pages/notifications_list_page.dart';
import 'package:orion_app/features/telemetry/presentation/pages/telemetry_status_page.dart';
import 'package:orion_app/injection_container.dart';

enum MainNavSection {
  routes,
  notifications,
  maintenance,
  telemetry,
  incidents,
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  MainNavSection _section = MainNavSection.routes;

  static const _titles = {
    MainNavSection.routes: 'Mis Hojas de Ruta',
    MainNavSection.notifications: 'Notificaciones',
    MainNavSection.maintenance: 'Mantenimiento',
    MainNavSection.telemetry: 'Telemetría',
    MainNavSection.incidents: 'Incidentes',
  };

  void _selectSection(MainNavSection section) {
    setState(() => _section = section);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: OrionColors.background,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: OrionColors.primaryGradient),
        ),
        title: Text(_titles[_section]!),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Menú',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (_section == MainNavSection.maintenance)
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Sincronizar mantenimiento',
              onPressed: () => context
                  .read<IncidentsBloc>()
                  .add(const SyncMaintenancePending()),
            ),
          const _SyncStatusChip(),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      drawer: _MainDrawer(
        selected: _section,
        onSelect: _selectSection,
        onLogout: () =>
            context.read<AuthBloc>().add(const AuthLogoutRequested()),
      ),
      body: IndexedStack(
        index: _section.index,
        children: const [
          RouteSheetsListPage(embedded: true),
          NotificationsListPage(embedded: true),
          MaintenanceHistoryPage(embedded: true),
          TelemetryStatusPage(embedded: true),
          ReportIncidentPage(embedded: true),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: OrionColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _section.index,
          backgroundColor: Colors.white,
          elevation: 0,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          indicatorColor: OrionColors.primary.withValues(alpha: 0.12),
          onDestinationSelected: (index) {
            setState(() => _section = MainNavSection.values[index]);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: 'Rutas',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alertas',
            ),
            NavigationDestination(
              icon: Icon(Icons.build_circle_outlined),
              selectedIcon: Icon(Icons.build_circle),
              label: 'Mant.',
            ),
            NavigationDestination(
              icon: Icon(Icons.gps_fixed_outlined),
              selectedIcon: Icon(Icons.gps_fixed),
              label: 'GPS',
            ),
            NavigationDestination(
              icon: Icon(Icons.report_problem_outlined),
              selectedIcon: Icon(Icons.report_problem),
              label: 'Incid.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MainDrawer extends StatelessWidget {
  const _MainDrawer({
    required this.selected,
    required this.onSelect,
    required this.onLogout,
  });

  final MainNavSection selected;
  final ValueChanged<MainNavSection> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OrionDrawerHeader(),
            const SizedBox(height: 8),
            _DrawerTile(
              icon: Icons.route_rounded,
              label: 'Mis Hojas de Ruta',
              subtitle: 'Paradas y entregas',
              selected: selected == MainNavSection.routes,
              onTap: () => onSelect(MainNavSection.routes),
            ),
            _DrawerTile(
              icon: Icons.notifications_active_outlined,
              label: 'Notificaciones',
              subtitle: 'Alertas del operador',
              selected: selected == MainNavSection.notifications,
              onTap: () => onSelect(MainNavSection.notifications),
            ),
            _DrawerTile(
              icon: Icons.build_circle_outlined,
              label: 'Mantenimiento',
              subtitle: 'Historial de solicitudes',
              selected: selected == MainNavSection.maintenance,
              onTap: () => onSelect(MainNavSection.maintenance),
            ),
            _DrawerTile(
              icon: Icons.gps_fixed_rounded,
              label: 'Telemetría GPS',
              subtitle: 'Estado de ubicación',
              selected: selected == MainNavSection.telemetry,
              onTap: () => onSelect(MainNavSection.telemetry),
            ),
            _DrawerTile(
              icon: Icons.report_problem_outlined,
              label: 'Incidentes',
              subtitle: 'Reportes y fallas',
              selected: selected == MainNavSection.incidents,
              onTap: () => onSelect(MainNavSection.incidents),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: OrionColors.error,
                  side: const BorderSide(color: OrionColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected
            ? OrionColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected
                  ? OrionColors.primary
                  : OrionColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: selected ? Colors.white : OrionColors.textSecondary,
              size: 22,
            ),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? OrionColors.primary : OrionColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SyncStatusChip extends StatelessWidget {
  const _SyncStatusChip();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncManagerState>(
      valueListenable: sl.get<SyncManager>().stateNotifier,
      builder: (context, syncState, _) {
        final hasPending = syncState.pendingCount > 0;
        final isOnline = syncState.isOnline;
        final color = !isOnline || hasPending
            ? OrionColors.warning
            : OrionColors.accentSoft;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Tooltip(
            message: !isOnline
                ? 'Sin red'
                : hasPending
                    ? '${syncState.pendingCount} pendientes'
                    : 'Sincronizado',
            child: Icon(
              isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: color,
              size: 22,
            ),
          ),
        );
      },
    );
  }
}
