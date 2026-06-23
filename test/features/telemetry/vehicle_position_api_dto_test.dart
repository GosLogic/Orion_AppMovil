import 'package:flutter_test/flutter_test.dart';
import 'package:orion_app/features/telemetry/data/models/vehicle_position_api_dto.dart';
import 'package:orion_app/features/telemetry/domain/entities/vehicle_position.dart';

void main() {
  group('VehiclePositionApiDto', () {
    test('toJson usa snake_case sin campo synced', () {
      final dto = VehiclePositionApiDto(
        time: DateTime.utc(2026, 6, 22, 15, 30),
        vehicleId: 1,
        latitude: -12.0464,
        longitude: -77.0428,
        speedKmh: 45.5,
        heading: 180,
        routeSheetId: 5,
        isMocked: false,
      );

      final json = dto.toJson();

      expect(json.containsKey('synced'), isFalse);
      expect(json['vehicle_id'], 1);
      expect(json['speed_kmh'], 45.5);
      expect(json['route_sheet_id'], 5);
      expect(json['is_mocked'], false);
      expect(json['latitude'], -12.0464);
      expect(json['longitude'], -77.0428);
      expect(json['heading'], 180);
      expect(json['time'], isA<String>());
    });

    test('fromPosition mapea entidad correctamente', () {
      final position = VehiclePosition(
        time: DateTime(2026, 6, 22, 10, 30),
        vehicleId: 42,
        latitude: -12.0,
        longitude: -77.0,
        speedKmh: 30,
        heading: 90,
        routeSheetId: 7,
        isMocked: true,
      );

      final dto = VehiclePositionApiDto.fromPosition(position);

      expect(dto.vehicleId, 42);
      expect(dto.routeSheetId, 7);
      expect(dto.isMocked, isTrue);
    });

    test('formatIso8601WithOffset incluye offset', () {
      final formatted = VehiclePositionApiDto.formatIso8601WithOffset(
        DateTime(2026, 6, 22, 10, 30),
      );

      expect(formatted, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}')));
      expect(formatted.contains('+') || formatted.contains('-'), isTrue);
    });
  });
}
