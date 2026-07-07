import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/widgets/orion_decorations.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_bloc.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_event.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_state.dart';

class ProofOfDeliveryPage extends StatelessWidget {
  const ProofOfDeliveryPage({
    super.key,
    required this.deliveryId,
    required this.customerName,
    this.packageDescription = '',
  });

  final String deliveryId;
  final String customerName;
  final String packageDescription;

  void _submit(BuildContext context) {
    context.read<DispatchBloc>().add(
          SubmitProofOfDelivery(deliveryId: deliveryId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return OrionPageScaffold(
      title: 'Confirmar entrega',
      body: BlocListener<DispatchBloc, DispatchState>(
        listenWhen: (previous, current) =>
            current.successMessage != null &&
            previous.successMessage != current.successMessage,
        listener: (context, state) => Navigator.of(context).pop(),
        child: BlocBuilder<DispatchBloc, DispatchState>(
          builder: (context, state) {
            final isSubmitting = state.status == DispatchStatus.submitting;
            final theme = Theme.of(context);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              OrionColors.success.withValues(alpha: 0.15),
                              OrionColors.accent.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: OrionColors.success.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 36,
                                color: OrionColors.success,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '¿Entregaste el paquete?',
                              style: theme.textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Verifica los datos antes de confirmar',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      OrionSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OrionDetailRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Cliente',
                              value: customerName,
                            ),
                            if (packageDescription.isNotEmpty) ...[
                              const Divider(height: 24),
                              OrionDetailRow(
                                icon: Icons.inventory_2_outlined,
                                label: 'Paquete',
                                value: packageDescription,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: OrionColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_sync_outlined,
                              color: OrionColors.primary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Se sincronizará con operaciones al confirmar.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                OrionBottomActionBar(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: OrionColors.success,
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: isSubmitting ? null : () => _submit(context),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirmar entrega'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
