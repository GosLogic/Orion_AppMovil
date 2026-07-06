import 'package:flutter_test/flutter_test.dart';
import 'package:orion_app/core/location/device_location_service.dart';
import 'package:orion_app/features/dispatch/data/models/delivery_model.dart';

void main() {
  group('DeviceLocation', () {
    test('toApiFields incluye null cuando no hay fix', () {
      const location = DeviceLocation();
      expect(location.toApiFields(), {
        'latitude': null,
        'longitude': null,
      });
    });

    test('toApiFields serializa decimales', () {
      const location = DeviceLocation(latitude: 4.6105, longitude: -74.0825);
      expect(location.toApiFields(), {
        'latitude': 4.6105,
        'longitude': -74.0825,
      });
    });
  });

  group('DeliveryModel.toApiPayload', () {
    test('incluye latitude y longitude opcionales', () {
      const model = DeliveryModel(
        id: 'del-stop-001-1',
        tripStopId: 'stop-001',
        customerName: 'Cliente 1',
        isCompleted: true,
        latitude: 4.6098,
        longitude: -74.0819,
      );

      final payload = model.toApiPayload();

      expect(payload['latitude'], 4.6098);
      expect(payload['longitude'], -74.0819);
      expect(payload['is_completed'], true);
      expect(payload['synced'], false);
    });

    test('permite coords nulas si no hay GPS', () {
      const model = DeliveryModel(
        id: 'del-stop-001-1',
        tripStopId: 'stop-001',
        customerName: 'Cliente 1',
        isCompleted: true,
      );

      final payload = model.toApiPayload();

      expect(payload['latitude'], isNull);
      expect(payload['longitude'], isNull);
    });
  });
}
