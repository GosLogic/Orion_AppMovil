import 'package:flutter/material.dart';

/// Paleta de marca Orion Driver.
abstract final class OrionColors {
  static const primary = Color(0xFF1A237E);
  static const primaryLight = Color(0xFF3949AB);
  static const primaryDark = Color(0xFF0D1642);
  static const accent = Color(0xFF00BFA5);
  static const accentSoft = Color(0xFF64FFDA);

  static const surface = Color(0xFFF5F7FA);
  static const surfaceCard = Colors.white;
  static const background = Color(0xFFECEFF1);

  static const textPrimary = Color(0xFF263238);
  static const textSecondary = Color(0xFF607D8B);
  static const textMuted = Color(0xFF90A4AE);

  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFFF8F00);
  static const error = Color(0xFFC62828);

  static const gradientStart = Color(0xFF0D1642);
  static const gradientMid = Color(0xFF1A237E);
  static const gradientEnd = Color(0xFF283593);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFEDE7F6),
      Color(0xFFECEFF1),
      Color(0xFFE3F2FD),
    ],
  );
}
