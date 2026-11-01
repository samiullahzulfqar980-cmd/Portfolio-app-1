import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared dart-define aware helper for haptics that silently no-ops on
/// platforms without a haptic engine.
class Haptics {
  const Haptics._();

  static Future<void> tap() => _run(HapticFeedback.selectionClick);

  static Future<void> light() => _run(HapticFeedback.lightImpact);

  static Future<void> success() => _run(HapticFeedback.mediumImpact);

  static Future<void> error() => _run(HapticFeedback.heavyImpact);

  static Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Haptics are an enhancement, never a requirement.
    }
  }
}

/// Unfocus the keyboard, e.g. before submitting a form.
void dismissKeyboard(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
}
