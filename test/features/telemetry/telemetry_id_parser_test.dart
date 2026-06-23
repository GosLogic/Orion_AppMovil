import 'package:flutter_test/flutter_test.dart';
import 'package:orion_app/features/telemetry/domain/utils/telemetry_id_parser.dart';

void main() {
  group('tryParseOrionNumericId', () {
    test('parsea int directo del JSON', () {
      expect(tryParseOrionNumericId(5), 5);
      expect(tryParseOrionNumericId(5.0), 5);
    });

    test('parsea string numérico puro', () {
      expect(tryParseOrionNumericId('42'), 42);
    });

    test('extrae dígitos de external id Orion', () {
      expect(tryParseOrionNumericId('vehicle-001'), 1);
      expect(tryParseOrionNumericId('route-demo-001'), 1);
    });

    test('devuelve null sin fallback silencioso', () {
      expect(tryParseOrionNumericId(null), isNull);
      expect(tryParseOrionNumericId(''), isNull);
      expect(tryParseOrionNumericId('sin-digitos'), isNull);
      expect(tryParseOrionNumericId('user-abc'), isNull);
    });
  });
}
