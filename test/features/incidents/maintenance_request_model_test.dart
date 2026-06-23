import 'package:flutter_test/flutter_test.dart';
import 'package:orion_app/features/incidents/data/models/maintenance_request_model.dart';
import 'package:orion_app/features/incidents/domain/entities/maintenance_request.dart';

void main() {
  group('MaintenanceRequestModel.toApiJson', () {
    test('serializa snake_case sin campo synced', () {
      final model = MaintenanceRequestModel(
        id: 'maint-abc-123',
        vehicleId: 'vehicle-001',
        description: 'Fuga de aceite',
        severity: MaintenanceSeverity.high,
        reportedAt: DateTime.utc(2026, 6, 5, 11, 30),
        photoEvidencePath: 'maintenance_photo_1.jpg',
        synced: false,
      );

      final json = model.toApiJson();

      expect(json['id'], 'maint-abc-123');
      expect(json['vehicle_id'], 'vehicle-001');
      expect(json['description'], 'Fuga de aceite');
      expect(json['severity'], 'HIGH');
      expect(json['reported_at'], '2026-06-05T11:30:00.000Z');
      expect(json['photo_evidence_path'], 'maintenance_photo_1.jpg');
      expect(json.containsKey('synced'), isFalse);
    });

    test('omite photo_evidence_path si está vacío', () {
      final model = MaintenanceRequestModel(
        id: 'maint-xyz',
        vehicleId: 'vehicle-001',
        description: 'Ruido en frenos',
        severity: MaintenanceSeverity.low,
        reportedAt: DateTime.utc(2026, 1, 1),
        photoEvidencePath: '',
      );

      final json = model.toApiJson();

      expect(json.containsKey('photo_evidence_path'), isFalse);
      expect(json['severity'], 'LOW');
    });
  });
}
