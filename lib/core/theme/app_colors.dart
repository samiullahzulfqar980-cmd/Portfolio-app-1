import 'package:flutter/material.dart';

/// Midnight-aurora palette: deep navy surfaces, violet → cyan accents.
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF06080F);
  static const Color backgroundElevated = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF0E1425);
  static const Color surfaceAlt = Color(0xFF141C31);
  static const Color surfaceHigh = Color(0xFF1B2440);

  static const Color primary = Color(0xFF7C5CFF);
  static const Color primarySoft = Color(0xFF9B85FF);
  static const Color accent = Color(0xFF2EE6D6);
  static const Color accentSoft = Color(0xFF7CF2E8);
  static const Color warm = Color(0xFFFFB86B);

  static const Color textPrimary = Color(0xFFF5F7FC);
  static const Color textSecondary = Color(0xFFACB4C8);
  static const Color textMuted = Color(0xFF7A849C);

  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFFC46B);
  static const Color danger = Color(0xFFFF6B81);

  static const Color border = Color(0x1FFFFFFF); // white @ 12%
  static const Color borderStrong = Color(0x33FFFFFF); // white @ 20%

  static const List<Color> auraGradient = <Color>[primary, accent];
  static const List<Color> triGradient = <Color>[Color(0xFF7C5CFF), Color(0xFF9F6BFF), Color(0xFF2EE6D6)];
  static const List<Color> warmGradient = <Color>[Color(0xFFFFB86B), Color(0xFFFF8A5B)];

  static Color surfaceWithOpacity(double opacity) =>
      surface.withValues(alpha: opacity.clamp(0.0, 1.0).toDouble());
}
