import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/features/dispatch/domain/entities/delivery.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_bloc.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_event.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_state.dart';
import 'package:orion_app/features/dispatch/presentation/pages/proof_of_delivery_page.dart';
import 'package:orion_app/features/dispatch/presentation/widgets/stop_status_badge.dart';
import 'package:orion_app/features/incidents/presentation/pages/report_incident_page.dart';

class StopDetailPage extends StatelessWidget {
  final TripStop tripStop;

  const StopDetailPage({super.key, required this.tripStop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: Text('Parada ${tripStop.sequence}'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<DispatchBloc, DispatchState>(
        builder: (context, state) {
          final isSubmitting = state.status == DispatchStatus.submitting;
          final currentStop = state.tripStops
                  .where((s) => s.id == tripStop.id)
                  .firstOrNull ??
              tripStop;
          final deliveries = state.deliveries
              .where((d) => d.tripStopId == tripStop.id)
              .toList();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    currentStop.locationName.isNotEmpty
                                        ? currentStop.locationName
                                        : 'Parada ${currentStop.sequence}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF263238),
                                    ),
                                  ),
                                ),
                                StopStatusBadge(status: currentStop.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF1A237E),
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    currentStop.address,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF455A64),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (currentStop.status == TripStopStatus.pending) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1565C0),
                                    side: const BorderSide(
                                      color: Color(0xFF1565C0),
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: isSubmitting
                                      ? null
                                      : () => context.read<DispatchBloc>().add(
                                            MarkStopArrived(currentStop.id),
                                          ),
                                  icon: const Icon(Icons.place),
                                  label: const Text(
                                    'Marcar Llegada',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Entregas en esta parada',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (deliveries.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Sin entregas pendientes',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ...deliveries.map(
                        (delivery) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              delivery.isCompleted
                                  ? Icons.check_circle
                                  : Icons.inventory_2_outlined,
                              color: delivery.isCompleted
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF1A237E),
                              size: 32,
                            ),
                            title: Text(
                              delivery.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(delivery.packageDescription),
                            trailing: delivery.isCompleted
                                ? const Text(
                                    'Entregado',
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _ActionButtons(
                tripStop: currentStop,
                pendingDelivery: deliveries
                    .where((d) => !d.isCompleted)
                    .firstOrNull,
                isSubmitting: isSubmitting,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final TripStop tripStop;
  final Delivery? pendingDelivery;
  final bool isSubmitting;

  const _ActionButtons({
    required this.tripStop,
    required this.pendingDelivery,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              onPressed: isSubmitting || pendingDelivery == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProofOfDeliveryPage(
                            deliveryId: pendingDelivery!.id,
                            customerName: pendingDelivery!.customerName,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.camera_alt, size: 28),
              label: const Text(
                'Registrar Entrega (Cámara/Firma)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE65100),
                side: const BorderSide(color: Color(0xFFE65100), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReportIncidentPage(stopId: tripStop.id),
                  ),
                );
              },
              icon: const Icon(Icons.report_problem, size: 26),
              label: const Text(
                'Reportar Incidente',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _DeliveryFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
