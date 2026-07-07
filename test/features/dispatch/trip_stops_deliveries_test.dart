import 'package:flutter_test/flutter_test.dart';
import 'package:orion_app/features/dispatch/data/models/delivery_model.dart';
import 'package:orion_app/features/dispatch/data/models/trip_stop_model.dart';

void main() {
  group('DeliveryModel.fromJson (GET trip-stops nested)', () {
    test('parsea entrega con status PENDING del backend', () {
      final delivery = DeliveryModel.fromJson({
        'id': 'del-stop-001-1',
        'trip_stop_id': 'stop-001',
        'customer_name': 'Cliente 1',
        'package_description': 'Paquete estándar #1',
        'status': 'PENDING',
        'proof_type': null,
        'photo_path': null,
        'signature_path': null,
        'notes': null,
        'delivered_at': null,
        'latitude': null,
        'longitude': null,
      });

      expect(delivery.id, 'del-stop-001-1');
      expect(delivery.isCompleted, false);
      expect(delivery.proof, isNull);
    });

    test('parsea entrega DELIVERED como completada', () {
      final delivery = DeliveryModel.fromJson({
        'id': 'del-stop-001-1',
        'trip_stop_id': 'stop-001',
        'customer_name': 'Cliente 1',
        'status': 'DELIVERED',
      });

      expect(delivery.isCompleted, true);
    });
  });

  group('TripStopModel + deliveries[]', () {
    test('fromJson ignora deliveries anidadas (las parsea el datasource)', () {
      final stop = TripStopModel.fromJson({
        'id': 'stop-001',
        'route_sheet_id': 'route-demo-001',
        'sequence': 1,
        'stop_order': 1,
        'address': 'Av. Test',
        'status': 'PENDING',
        'deliveries': [
          {
            'id': 'del-stop-001-1',
            'trip_stop_id': 'stop-001',
            'customer_name': 'Cliente 1',
            'status': 'PENDING',
          },
        ],
      });

      expect(stop.id, 'stop-001');
      expect(stop.sequence, 1);
    });

    test('fromJson parsea latitude y longitude de parada', () {
      final stop = TripStopModel.fromJson({
        'id': 'stop-201',
        'route_sheet_id': 'route-demo-002',
        'sequence': 1,
        'address': 'Av. Javier Prado 1000',
        'latitude': -12.0983,
        'longitude': -77.0323,
        'status': 'PENDING',
      });

      expect(stop.hasCoordinates, isTrue);
      expect(stop.latitude, -12.0983);
      expect(stop.longitude, -77.0323);
    });
  });
}
