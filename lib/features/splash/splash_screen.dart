import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_env.dart';
import '../../core/motion/motion.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_background.dart';

/// Brand splash. Decides between onboarding and home, and warms up the
/// portfolio query in the background.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.hasSeenOnboarding});

  final bool hasSeenOnboarding;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  Timer? _navigateTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navigateTimer != null) return;
    final Duration wait = Motion.reduced(context)
        ? const Duration(milliseconds: 250)
        : const Duration(milliseconds: 1500);
    _navigateTimer = Timer(wait, _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    context.go(widget.hasSeenOnboarding ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        showGrid: true,
        child: Center(
          child: Semantics(
            label: 'Portfolio app loading',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) {
                    final double t = Curves.easeOutCubic.transform(_controller.value);
                    return Opacity(
                      opacity: t.clamp(0.0, 1.0).toDouble(),
                      child: Transform.scale(scale: 0.88 + 0.12 * t, child: child),
                    );
                  },
                  child: const _Monogram(size: 96),
                ),
                const SizedBox(height: 22),
                Text('PORTFOLIO', style: AppType.overline(color: AppColors.accentSoft)),
                const SizedBox(height: 10),
                Text(
                  'Design-minded engineering',
                  style: AppType.bodySmall(color: AppColors.textMuted),
                ),
                const SizedBox(height: 34),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                if (!AppEnv.isConfigured) ...<Widget>[
                  const SizedBox(height: 28),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.science_outlined, size: 15, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Preview mode — connect Supabase in .env',
                            style: AppType.labelSmall(color: AppColors.warning)
                                .copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF211742), Color(0xFF0C2230)],
        ),
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          ShaderMask(
            shaderCallback: (Rect bounds) => const LinearGradient(
              colors: AppColors.auraGradient,
            ).createShader(bounds),
            child: Text(
              'S',
              style: AppType.displayLarge(color: Colors.white).copyWith(
                fontSize: size * 0.46,
                letterSpacing: -1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
