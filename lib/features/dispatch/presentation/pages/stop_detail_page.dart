import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/widgets/orion_decorations.dart';
import 'package:orion_app/core/widgets/orion_list_ui.dart';
import 'package:orion_app/features/dispatch/domain/entities/delivery.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_bloc.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_event.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_state.dart';
import 'package:orion_app/features/dispatch/presentation/pages/proof_of_delivery_page.dart';
import 'package:orion_app/features/dispatch/presentation/utils/waze_navigation_launcher.dart';
import 'package:orion_app/features/dispatch/presentation/widgets/delivery_card.dart';
import 'package:orion_app/features/dispatch/presentation/widgets/stop_status_badge.dart';

class StopDetailPage extends StatelessWidget {
  const StopDetailPage({super.key, required this.tripStop});

  final TripStop tripStop;

  @override
  Widget build(BuildContext context) {
    return OrionPageScaffold(
      title: 'Parada ${tripStop.sequence}',
      body: BlocListener<DispatchBloc, DispatchState>(
        listenWhen: (previous, current) =>
            previous.successMessage != current.successMessage ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: OrionColors.success,
                ),
              );
          }
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
            final isSubmitting = state.status == DispatchStatus.submitting;
            final jornadaActive = state.isJornadaActive;
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      OrionSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: OrionColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${currentStop.sequence}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentStop.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      const SizedBox(height: 6),
                                      StopStatusBadge(status: currentStop.status),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  color: OrionColors.primary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    currentStop.address,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                            if (jornadaActive &&
                                currentStop.status !=
                                    TripStopStatus.completed &&
                                currentStop.status !=
                                    TripStopStatus.skipped) ...[
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: OrionColors.accent,
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                onPressed: () =>
                                    openWazeNavigation(context, currentStop),
                                icon: const Icon(Icons.navigation_rounded),
                                label: const Text('Abrir en Waze'),
                              ),
                            ],
                            if (currentStop.status ==
                                    TripStopStatus.pending &&
                                jornadaActive) ...[
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: OrionColors.primary,
                                  side: BorderSide(
                                    color: OrionColors.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () => context
                                        .read<DispatchBloc>()
                                        .add(MarkStopArrived(currentStop.id)),
                                icon: const Icon(Icons.place_rounded),
                                label: const Text('Marcar llegada'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      OrionSectionHeader(
                        icon: Icons.local_shipping_outlined,
                        title: 'Entregas',
                        subtitle: '${deliveries.length} en esta parada',
                        count: deliveries.length,
                      ),
                      if (deliveries.isEmpty)
                        OrionSurfaceCard(
                          child: Row(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                color: OrionColors.textMuted,
                                size: 32,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Sin entregas en esta parada',
                                  style:
                                      Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...deliveries.map(
                          (d) => DeliveryCard(delivery: d),
                        ),
                    ],
                  ),
                ),
                _ActionButtons(
                  pendingDelivery:
                      deliveries.where((d) => !d.isCompleted).firstOrNull,
                  isSubmitting: isSubmitting,
                  jornadaActive: jornadaActive,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.pendingDelivery,
    required this.isSubmitting,
    required this.jornadaActive,
  });

  final Delivery? pendingDelivery;
  final bool isSubmitting;
  final bool jornadaActive;

  @override
  Widget build(BuildContext context) {
    return OrionBottomActionBar(
      child: FilledButton.icon(
        onPressed: isSubmitting || pendingDelivery == null || !jornadaActive
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProofOfDeliveryPage(
                      deliveryId: pendingDelivery!.id,
                      customerName: pendingDelivery!.customerName,
                      packageDescription: pendingDelivery!.packageDescription,
                    ),
                  ),
                );
              },
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text('Registrar entrega'),
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
