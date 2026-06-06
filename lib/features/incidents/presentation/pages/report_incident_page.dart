import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/features/incidents/domain/entities/maintenance_request.dart';
import 'package:orion_app/features/incidents/domain/entities/route_incident.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_event.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_state.dart';

class ReportIncidentPage extends StatefulWidget {
  final String? stopId;
  final String vehicleId;

  const ReportIncidentPage({
    super.key,
    this.stopId,
    this.vehicleId = 'vehicle-001',
  });

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  RouteIncidentType _selectedType = RouteIncidentType.traffic;
  MaintenanceSeverity _selectedSeverity = MaintenanceSeverity.medium;
  final _routeDescriptionController = TextEditingController();
  final _maintenanceDescriptionController = TextEditingController();
  String? _photoPath;

  final _routeFormKey = GlobalKey<FormState>();
  final _maintenanceFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _routeDescriptionController.dispose();
    _maintenanceDescriptionController.dispose();
    super.dispose();
  }

  void _attachPhoto() {
    setState(() {
      _photoPath =
          'maintenance_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fotografía adjuntada (ruta local simulada)'),
        backgroundColor: Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submitRouteIncident() {
    if (!_routeFormKey.currentState!.validate()) return;

    final incident = RouteIncident(
      id: 'inc-${DateTime.now().millisecondsSinceEpoch}',
      stopId: widget.stopId,
      type: _selectedType,
      description: _routeDescriptionController.text.trim(),
      reportedAt: DateTime.now(),
    );

    context.read<IncidentsBloc>().add(SubmitRouteIncident(incident));
  }

  void _submitMaintenanceRequest() {
    if (!_maintenanceFormKey.currentState!.validate()) return;

    final request = MaintenanceRequest(
      id: 'maint-${DateTime.now().millisecondsSinceEpoch}',
      vehicleId: widget.vehicleId,
      description: _maintenanceDescriptionController.text.trim(),
      severity: _selectedSeverity,
      reportedAt: DateTime.now(),
      photoEvidencePath: _photoPath,
    );

    context.read<IncidentsBloc>().add(SubmitMaintenanceRequest(request));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: const Text(
          'Reportar Incidente',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Problema en Ruta'),
            Tab(text: 'Falla Mecánica'),
          ],
        ),
      ),
      body: BlocConsumer<IncidentsBloc, IncidentsState>(
        listener: (context, state) {
          if (state.status == IncidentsStatus.success &&
              state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message!),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            _routeDescriptionController.clear();
            _maintenanceDescriptionController.clear();
            setState(() {
              _photoPath = null;
              _selectedType = RouteIncidentType.traffic;
              _selectedSeverity = MaintenanceSeverity.medium;
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

          return TabBarView(
            controller: _tabController,
            children: [
              _RouteIncidentTab(
                formKey: _routeFormKey,
                selectedType: _selectedType,
                descriptionController: _routeDescriptionController,
                isLoading: isLoading,
                onTypeChanged: (type) => setState(() => _selectedType = type),
                onSubmit: _submitRouteIncident,
              ),
              _MaintenanceTab(
                formKey: _maintenanceFormKey,
                selectedSeverity: _selectedSeverity,
                descriptionController: _maintenanceDescriptionController,
                photoPath: _photoPath,
                isLoading: isLoading,
                onSeverityChanged: (s) =>
                    setState(() => _selectedSeverity = s),
                onAttachPhoto: _attachPhoto,
                onSubmit: _submitMaintenanceRequest,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RouteIncidentTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final RouteIncidentType selectedType;
  final TextEditingController descriptionController;
  final bool isLoading;
  final ValueChanged<RouteIncidentType> onTypeChanged;
  final VoidCallback onSubmit;

  const _RouteIncidentTab({
    required this.formKey,
    required this.selectedType,
    required this.descriptionController,
    required this.isLoading,
    required this.onTypeChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tipo de problema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: RouteIncidentType.values.map((type) {
                final label = switch (type) {
                  RouteIncidentType.traffic => 'Tráfico',
                  RouteIncidentType.vehicleFailure => 'Falla vehículo',
                  RouteIncidentType.clientAbsent => 'Cliente ausente',
                  RouteIncidentType.other => 'Otro',
                };
                final isSelected = selectedType == type;
                return FilterChip(
                  label: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF263238),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: isLoading ? null : (_) => onTypeChanged(type),
                  selectedColor: const Color(0xFF1A237E),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF1A237E)
                          : const Color(0xFFB0BEC5),
                      width: 2,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Descripción del incidente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: descriptionController,
              maxLines: 5,
              enabled: !isLoading,
              style: const TextStyle(fontSize: 17),
              decoration: InputDecoration(
                hintText: 'Describe qué ocurrió en la ruta...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'La descripción es obligatoria';
                }
                if (v.trim().length < 10) {
                  return 'Mínimo 10 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            _GiantGreenButton(
              label: 'Guardar Reporte',
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final MaintenanceSeverity selectedSeverity;
  final TextEditingController descriptionController;
  final String? photoPath;
  final bool isLoading;
  final ValueChanged<MaintenanceSeverity> onSeverityChanged;
  final VoidCallback onAttachPhoto;
  final VoidCallback onSubmit;

  const _MaintenanceTab({
    required this.formKey,
    required this.selectedSeverity,
    required this.descriptionController,
    required this.photoPath,
    required this.isLoading,
    required this.onSeverityChanged,
    required this.onAttachPhoto,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nivel de severidad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 12),
            _SeveritySelector(
              selected: selectedSeverity,
              isLoading: isLoading,
              onChanged: onSeverityChanged,
            ),
            const SizedBox(height: 24),
            const Text(
              'Descripción de la falla',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              enabled: !isLoading,
              style: const TextStyle(fontSize: 17),
              decoration: InputDecoration(
                hintText: 'Describe la falla mecánica...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'La descripción es obligatoria';
                }
                if (v.trim().length < 10) {
                  return 'Mínimo 10 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 58,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  side: const BorderSide(color: Color(0xFF1565C0), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isLoading ? null : onAttachPhoto,
                icon: const Icon(Icons.camera_alt, size: 28),
                label: Text(
                  photoPath != null
                      ? 'Fotografía adjuntada ✓'
                      : 'Adjuntar Fotografía',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _GiantGreenButton(
              label: 'Solicitar Mantenimiento',
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SeveritySelector extends StatelessWidget {
  final MaintenanceSeverity selected;
  final bool isLoading;
  final ValueChanged<MaintenanceSeverity> onChanged;

  const _SeveritySelector({
    required this.selected,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        MaintenanceSeverity.low,
        'Bajo',
        const Color(0xFF9E9E9E),
      ),
      (
        MaintenanceSeverity.medium,
        'Medio',
        const Color(0xFFFFC107),
      ),
      (
        MaintenanceSeverity.high,
        'Alto',
        const Color(0xFFE65100),
      ),
      (
        MaintenanceSeverity.critical,
        'Crítico',
        const Color(0xFFD50000),
      ),
    ];

    return Column(
      children: options.map((option) {
        final (severity, label, color) = option;
        final isSelected = selected == severity;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? color : Colors.white,
                foregroundColor:
                    isSelected ? Colors.white : const Color(0xFF263238),
                elevation: isSelected ? 4 : 0,
                side: BorderSide(color: color, width: 2.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isLoading ? null : () => onChanged(severity),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GiantGreenButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _GiantGreenButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C853),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
