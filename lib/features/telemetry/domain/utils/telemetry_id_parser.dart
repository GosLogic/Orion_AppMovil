/// Convierte IDs externos de Orion (string o int del JSON) al entero que
/// espera telemetry-service en POST batch.
///
/// Ejemplos alineados con el backend:
/// - `"vehicle-001"` → `1`
/// - `"route-demo-001"` → `1`
/// - `5` (int en JSON) → `5`
///
/// Devuelve `null` si no puede resolver — **sin fallback hardcodeado**.
int? tryParseOrionNumericId(dynamic value) {
  if (value == null) return null;

  if (value is int) return value;
  if (value is num) return value.toInt();

  if (value is! String || value.isEmpty) return null;

  final direct = int.tryParse(value);
  if (direct != null) return direct;

  final digits =
      RegExp(r'\d+').allMatches(value).map((m) => m.group(0)!).join();
  if (digits.isEmpty) return null;

  return int.tryParse(digits);
}

@Deprecated('Usar tryParseOrionNumericId; no hay fallback silencioso')
int parseOrionNumericId(String? value, {int fallback = 1}) {
  return tryParseOrionNumericId(value) ?? fallback;
}
