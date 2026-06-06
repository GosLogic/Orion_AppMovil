int parseOrionNumericId(String? value, {int fallback = 1}) {
  if (value == null || value.isEmpty) return fallback;
  final digits = RegExp(r'\d+').allMatches(value).map((m) => m.group(0)!).join();
  if (digits.isEmpty) return value.hashCode.abs() % 1000000;
  return int.tryParse(digits) ?? fallback;
}
