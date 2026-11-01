import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_colors.dart';

/// Ambient aurora background: layered radial gradients + a faint dot grid.
///
/// Purely decorative, so it is excluded from semantics and does not repaint
/// on scroll (it lives behind the scroll view).
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    this.child,
    this.intensity = 1.0,
    this.showGrid = true,
  });

  final Widget child;
  final double intensity;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _AuroraPainter(intensity: intensity, showGrid: showGrid),
                  isComplex: false,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.intensity, required this.showGrid});

  final double intensity;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;

    // Base vertical wash.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppColors.backgroundElevated, AppColors.background],
        ).createShader(bounds),
    );

    void glow(Offset center, double radius, Color color, double opacity) {
      final Rect rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: <Color>[
              color.withValues(alpha: (opacity * intensity).clamp(0.0, 1.0).toDouble()),
              color.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }

    glow(
      Offset(size.width * 0.12, -size.height * 0.05),
      size.width * 0.95,
      AppColors.primary,
      0.30,
    );
    glow(
      Offset(size.width * 1.02, size.height * 0.28),
      size.width * 0.85,
      AppColors.accent,
      0.13,
    );
    glow(
      Offset(size.width * 0.75, size.height * 1.05),
      size.width * 0.9,
      const Color(0xFF4B2FA8),
      0.22,
    );

    if (showGrid) {
      final Paint dot = Paint()..color = Colors.white.withValues(alpha: 0.035);
      const double step = 26;
      final double maxY = math.min(size.height, 640);
      for (double y = 0; y < maxY; y += step) {
        for (double x = 0; x < size.width; x += step) {
          final double fade = 1 - (y / maxY);
          if (fade <= 0.02) continue;
          dot.color = Colors.white.withValues(alpha: 0.05 * fade * intensity);
          canvas.drawCircle(Offset(x, y), 0.9, dot);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.intensity != intensity || oldDelegate.showGrid != showGrid;
}

/// Standard page scaffold with the aurora background and a translucent app bar.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.body,
    this.appBar,
    this.bottomBar,
    this.floatingActionButton,
    this.showGrid = true,
    this.safeArea = true,
    this.intensity = 1.0,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final bool showGrid;
  final bool safeArea;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: bottomBar,
      floatingActionButton: floatingActionButton,
      body: AppBackground(
        showGrid: showGrid,
        intensity: intensity,
        // The app bar is translucent and overlays the background, so reserve
        // its height (plus any bottom bar) before laying out the page body.
        child: Padding(
          padding: EdgeInsets.only(
            top: appBar == null ? 0 : appBar!.preferredSize.height,
          ),
          child: safeArea ? SafeArea(bottom: false, child: body) : body,
        ),
      ),
    );
  }
}

/// Constrains content width on tablets and keeps gutters comfortable on phones.
class ContentColumn extends StatelessWidget {
  const ContentColumn({
    super.key,
    required this.child,
    this.maxWidth = 640,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Blurred app bar used by tab screens (content scrolls underneath).
class AuroraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AuroraAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.height = kToolbarHeight,
    this.bottom,
    this.showBackButton = true,
    this.titleSpacing,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;
  final double? titleSpacing;

  @override
  Size get preferredSize => Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBackButton,
      leading: leading,
      titleSpacing: titleSpacing ?? (showBackButton ? 4 : 20),
      title: title,
      actions: actions,
      bottom: bottom,
      backgroundColor: AppColors.background.withValues(alpha: 0.72),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Small helper that animates a child in when it first appears.
class EntryFade extends StatelessWidget {
  const EntryFade({super.key, required this.child, this.index = 0, this.offsetY = 14});

  final Widget child;
  final int index;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return child;
    return AnimatedEntry(index: index, offsetY: offsetY, child: child);
  }
}
