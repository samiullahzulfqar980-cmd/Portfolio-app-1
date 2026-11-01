import 'package:flutter/material.dart';

/// Motion tokens + reduced-motion helpers.
///
/// Every animation in the app goes through here so that the OS "remove
/// animations" / "reduce motion" setting is respected consistently.
class Motion {
  const Motion._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration entrance = Duration(milliseconds: 520);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;

  static bool reduced(BuildContext context) {
    final MediaQueryData data = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    return data.disableAnimations;
  }

  static Duration duration(BuildContext context, Duration preferred) =>
      reduced(context) ? Duration.zero : preferred;

  static Duration stagger(BuildContext context, int index, {Duration step = const Duration(milliseconds: 60)}) {
    if (reduced(context)) return Duration.zero;
    final int capped = index.clamp(0, 8).toInt();
    return step * capped;
  }

  static PageRoute<T> pageRoute<T>(Widget child) {
    return PageRouteBuilder<T>(
      transitionDuration: normal,
      reverseTransitionDuration: fast,
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondary) =>
          child,
      transitionsBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondary, Widget child) {
        if (reduced(context)) return child;
        final CurvedAnimation curved = CurvedAnimation(parent: animation, curve: standard);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

/// Fade + slide entrance used by cards, sections and list items.
///
/// Falls back to a static child when reduced motion is enabled.
class AnimatedEntry extends StatefulWidget {
  const AnimatedEntry({
    super.key,
    required this.child,
    this.index = 0,
    this.offsetY = 14,
    this.duration,
    this.curve = Motion.emphasized,
  });

  final Widget child;
  final int index;
  final double offsetY;
  final Duration? duration;
  final Curve curve;

  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration ?? Motion.entrance,
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: widget.curve);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final Duration delay = Motion.stagger(context, widget.index);
    if (delay == Duration.zero) {
      _controller.value = 1;
    } else {
      Future<void>.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _curve.value.clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(
            offset: Offset(0, (1 - _curve.value) * widget.offsetY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Press feedback that respects reduced motion (no scale when disabled).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.semanticLabel,
    this.behaviour = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final String? semanticLabel;
  final HitTestBehavior behaviour;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool animate = !Motion.reduced(context);
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: widget.behaviour,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed && animate ? widget.scale : 1,
          duration: animate ? Motion.fast : Duration.zero,
          curve: Motion.standard,
          child: widget.child,
        ),
      ),
    );
  }
}
