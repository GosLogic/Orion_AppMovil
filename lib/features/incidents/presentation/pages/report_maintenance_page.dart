import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orion_app/features/incidents/domain/entities/maintenance_request.dart';
import 'package:orion_app/features/incidents/domain/utils/maintenance_id_generator.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_event.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_state.dart';
import 'package:orion_app/features/incidents/presentation/pages/maintenance_history_page.dart';
import 'package:path_provider/path_provider.dart';

/// Formulario de solicitud de mantenimiento (POST /maintenance/requests).
class ReportMaintenancePage extends StatefulWidget {
  final String vehicleId;

  const ReportMaintenancePage({
    super.key,
    required this.vehicleId,
  });

  @override
  State<ReportMaintenancePage> createState() => _ReportMaintenancePageState();
}

class _ReportMaintenancePageState extends State<ReportMaintenancePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  MaintenanceSeverity _severity = MaintenanceSeverity.medium;
  String? _photoFileName;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 70);
    if (file == null || !mounted) return;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'maintenance_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = File('${dir.path}/$fileName');
    await File(file.path).copy(saved.path);

    setState(() => _photoFileName = fileName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto guardada localmente'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (widget.vehicleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay vehículo asignado en la hoja de ruta'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    final request = MaintenanceRequest(
      id: generateMaintenanceRequestId(),
      vehicleId: widget.vehicleId,
      description: _descriptionController.text.trim(),
      severity: _severity,
      reportedAt: DateTime.now(),
      photoEvidencePath: _photoFileName,
    );

    context.read<IncidentsBloc>().add(SubmitMaintenanceRequest(request));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: const Text(
          'Reportar mantenimiento',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MaintenanceHistoryPage(),
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<IncidentsBloc, IncidentsState>(
        listener: (context, state) {
          if (state.status == IncidentsStatus.success && state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message!),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            _descriptionController.clear();
            setState(() {
              _photoFileName = null;
              _severity = MaintenanceSeverity.medium;
            });
          }
          if (state.status == IncidentsStatus.failure &&
              state.errorMessage != null) {
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
        builder: (context, state) {
          final isLoading = state.isLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Vehículo: ${widget.vehicleId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF455A64),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Severidad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...MaintenanceSeverity.values.map((s) {
                    final label = switch (s) {
                      MaintenanceSeverity.low => 'Bajo (LOW)',
                      MaintenanceSeverity.medium => 'Medio (MEDIUM)',
                      MaintenanceSeverity.high => 'Alto (HIGH)',
                      MaintenanceSeverity.critical => 'Crítico (CRITICAL)',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<MaintenanceSeverity>(
                        value: s,
                        groupValue: _severity,
                        onChanged:
                            isLoading ? null : (v) => setState(() => _severity = v!),
                        title: Text(label),
                        activeColor: const Color(0xFF1A237E),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Descripción del problema',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'La descripción es obligatoria';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => _pickPhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Cámara'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => _pickPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galería'),
                        ),
                      ),
                    ],
                  ),
                  if (_photoFileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Foto: $_photoFileName',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Enviar solicitud',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
