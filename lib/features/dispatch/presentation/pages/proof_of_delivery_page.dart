import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/features/dispatch/domain/entities/proof_of_delivery.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_bloc.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_event.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_state.dart';
import 'package:orion_app/features/dispatch/presentation/widgets/signature_pad.dart';

class ProofOfDeliveryPage extends StatefulWidget {
  final String deliveryId;
  final String customerName;

  const ProofOfDeliveryPage({
    super.key,
    required this.deliveryId,
    required this.customerName,
  });

  @override
  State<ProofOfDeliveryPage> createState() => _ProofOfDeliveryPageState();
}

class _ProofOfDeliveryPageState extends State<ProofOfDeliveryPage> {
  String? _photoPath;
  String? _signaturePath;

  void _capturePhoto() {
    setState(() {
      _photoPath =
          'photo_local_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto capturada (simulada offline)'),
        backgroundColor: Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submit() {
    if (_photoPath == null && _signaturePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toma una foto o registra la firma del cliente'),
          backgroundColor: Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final proofType = _photoPath != null && _signaturePath != null
        ? ProofType.both
        : _photoPath != null
            ? ProofType.photo
            : ProofType.signature;

    context.read<DispatchBloc>().add(
          SubmitProofOfDelivery(
            deliveryId: widget.deliveryId,
            proof: ProofOfDelivery(
              type: proofType,
              photoPath: _photoPath,
              signaturePath: _signaturePath,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: const Text('Prueba de Entrega'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: BlocListener<DispatchBloc, DispatchState>(
        listenWhen: (previous, current) =>
            current.successMessage != null &&
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          Navigator.of(context).pop();
        },
        child: BlocBuilder<DispatchBloc, DispatchState>(
          builder: (context, state) {
            final isSubmitting = state.status == DispatchStatus.submitting;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Cliente: ${widget.customerName}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Foto de entrega',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: isSubmitting ? null : _capturePhoto,
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFB0BEC5),
                              width: 2,
                            ),
                          ),
                          child: _photoPath != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: ColoredBox(
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.image,
                                          size: 64,
                                          color: Color(0xFF1A237E),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Chip(
                                        label: const Text('Foto OK'),
                                        backgroundColor:
                                            const Color(0xFFE8F5E9),
                                      ),
                                    ),
                                  ],
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      size: 48,
                                      color: Color(0xFF90A4AE),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Toca para tomar foto',
                                      style: TextStyle(
                                        color: Color(0xFF90A4AE),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isSubmitting ? null : _capturePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text(
                            'Tomar Foto',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Firma del cliente',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SignaturePad(
                        onChanged: (path) =>
                            setState(() => _signaturePath = path),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      onPressed: isSubmitting ? null : _submit,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 28,
                              width: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirmar Entrega',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
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
