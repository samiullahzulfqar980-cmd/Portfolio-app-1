import 'package:flutter/material.dart';

/// Spacing / radius / elevation tokens. One source of truth for the layout
/// rhythm used across every screen.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 44;

  /// Horizontal page gutter that stays comfortable on small phones.
  static double gutter(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 16;
    if (width < 420) return 20;
    return 24;
  }
}

class AppRadius {
  const AppRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 26;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(xl));
}
