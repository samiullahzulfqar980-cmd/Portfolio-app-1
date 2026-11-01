import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography built on bundled variable fonts (Sora / Inter / JetBrains Mono).
/// Variable-axis weights keep the APK small while allowing every weight.
class AppType {
  const AppType._();

  static const String display = 'Sora';
  static const String body = 'Inter';
  static const String mono = 'JetBrainsMono';

  static TextStyle _style({
    required String family,
    required double size,
    required double weight,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      shadows: shadows,
      fontVariations: <FontVariation>[FontVariation('wght', weight)],
    );
  }

  // Display -------------------------------------------------------------------
  static TextStyle displayLarge({Color color = AppColors.textPrimary}) =>
      _style(family: display, size: 36, weight: 600, color: color, height: 1.1, letterSpacing: -1.0);

  static TextStyle displayMedium({Color color = AppColors.textPrimary}) =>
      _style(family: display, size: 30, weight: 600, color: color, height: 1.15, letterSpacing: -0.8);

  static TextStyle headlineLarge({Color color = AppColors.textPrimary}) =>
      _style(family: display, size: 24, weight: 600, color: color, height: 1.2, letterSpacing: -0.4);

  static TextStyle headlineMedium({Color color = AppColors.textPrimary}) =>
      _style(family: display, size: 20, weight: 600, color: color, height: 1.25, letterSpacing: -0.2);

  static TextStyle titleLarge({Color color = AppColors.textPrimary}) =>
      _style(family: display, size: 17, weight: 600, color: color, height: 1.3);

  // Body ----------------------------------------------------------------------
  static TextStyle bodyLarge({Color color = AppColors.textSecondary}) =>
      _style(family: body, size: 15, weight: 400, color: color, height: 1.6);

  static TextStyle bodyMedium({Color color = AppColors.textSecondary}) =>
      _style(family: body, size: 14, weight: 400, color: color, height: 1.55);

  static TextStyle bodySmall({Color color = AppColors.textMuted}) =>
      _style(family: body, size: 12.5, weight: 400, color: color, height: 1.45);

  static TextStyle labelLarge({Color color = AppColors.textPrimary}) =>
      _style(family: body, size: 14.5, weight: 600, color: color, height: 1.2, letterSpacing: 0.1);

  static TextStyle labelSmall({Color color = AppColors.textMuted}) =>
      _style(family: body, size: 11.5, weight: 500, color: color, height: 1.2, letterSpacing: 0.4);

  static TextStyle overline({Color color = AppColors.accent}) => _style(
        family: body,
        size: 11,
        weight: 600,
        color: color,
        height: 1.2,
        letterSpacing: 1.6,
      );

  static TextStyle mono({Color color = AppColors.textSecondary, double size = 12.5}) =>
      _style(family: mono, size: size, weight: 400, color: color, height: 1.5);
}
