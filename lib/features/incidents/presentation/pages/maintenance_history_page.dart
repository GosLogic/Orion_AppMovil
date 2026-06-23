import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/features/incidents/domain/entities/maintenance_request.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_event.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_state.dart';

class MaintenanceHistoryPage extends StatefulWidget {
  const MaintenanceHistoryPage({super.key});

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
      body: BlocBuilder<IncidentsBloc, IncidentsState>(
        builder: (context, state) {
          if (state.isLoading && state.maintenanceHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.maintenanceHistory.isEmpty) {
            return const Center(
              child: Text('No hay solicitudes registradas'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.maintenanceHistory.length,
            itemBuilder: (context, index) {
              final item = state.maintenanceHistory[index];
              return _MaintenanceCard(request: item);
            },
          );
        },
      ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: syncColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    syncLabel,
                    style: TextStyle(
                      color: syncColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${request.severityLabel} · ${request.vehicleId}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF455A64),
              ),
            ),
            if (request.serverStatus != null) ...[
              const SizedBox(height: 4),
              Text('Estado servidor: ${request.serverStatus}'),
            ],
            const SizedBox(height: 8),
            Text(request.description),
            const SizedBox(height: 6),
            Text(
              'Reportado: ${request.reportedAt.toLocal()}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF78909C)),
            ),
          ],
        ),
      ),
    );
  }
}
