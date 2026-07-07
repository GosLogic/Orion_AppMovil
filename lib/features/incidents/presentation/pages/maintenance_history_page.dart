import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/widgets/orion_list_ui.dart';
import 'package:orion_app/features/incidents/domain/entities/maintenance_request.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_event.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_state.dart';

class MaintenanceHistoryPage extends StatefulWidget {
  const MaintenanceHistoryPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MaintenanceHistoryPage> createState() => _MaintenanceHistoryPageState();
}

class _MaintenanceHistoryPageState extends State<MaintenanceHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<IncidentsBloc>().add(const LoadMaintenanceHistory());
  }

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<IncidentsBloc, IncidentsState>(
      builder: (context, state) {
        if (state.isLoading && state.maintenanceHistory.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.maintenanceHistory.isEmpty) {
          return const OrionEmptyState(
            icon: Icons.build_circle_outlined,
            title: 'Sin solicitudes de mantenimiento',
            subtitle: 'Reporta una falla desde Incidentes o una hoja en curso',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: state.maintenanceHistory.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return OrionSectionHeader(
                icon: Icons.build_outlined,
                title: 'Historial',
                subtitle: '${state.maintenanceHistory.length} solicitud(es)',
                count: state.maintenanceHistory.length,
              );
            }
            final item = state.maintenanceHistory[index - 1];
            return _MaintenanceCard(request: item);
          },
        );
      },
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial mantenimiento'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              context.read<IncidentsBloc>().add(const SyncMaintenancePending());
            },
          ),
        ],
      ),
      body: body,
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final MaintenanceRequest request;

  const _MaintenanceCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final syncLabel = request.synced ? 'Enviada' : 'Pendiente sync';
    final syncColor =
        request.synced ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: OrionColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: OrionColors.textSecondary,
                    ),
                  ),
                ),
                OrionStatusChip(label: syncLabel, color: syncColor),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              request.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: OrionColors.warning),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${request.severityLabel} · ${request.vehicleId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (request.serverStatus != null) ...[
              const SizedBox(height: 4),
              Text(
                'Estado: ${request.serverStatus}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
