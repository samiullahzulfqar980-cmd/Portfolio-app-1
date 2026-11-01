import 'dart:async';

import 'package:flutter/widgets.dart';

/// Value notifier that flips to `true` after [delay].
///
/// Used to avoid flashing skeletons on fast connections while still showing
/// a loading state for genuinely slow work.
class DelayedFlag extends ValueNotifier<bool> {
  DelayedFlag({Duration delay = const Duration(milliseconds: 220)}) : super(false) {
    _timer = Timer(delay, () {
      if (!_disposed) value = true;
    });
  }

  late final Timer _timer;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _timer.cancel();
    super.dispose();
  }
}

/// Small utility to run async work with a minimum on-screen loading time so
/// spinners do not flicker for sub-150ms responses.
Future<T> withMinimumDelay<T>(Future<T> future, {int ms = 320}) async {
  final DateTime started = DateTime.now();
  final T result = await future;
  final int elapsed = DateTime.now().difference(started).inMilliseconds;
  if (elapsed < ms) {
    await Future<void>.delayed(Duration(milliseconds: ms - elapsed));
  }
  return result;
}
