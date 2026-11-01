import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/motion.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/feedback.dart';

/// Three short, skippable slides. Shown once, then never again unless the user
/// resets it from the About screen.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_Slide> _slides = <_Slide>[
    _Slide(
      eyebrow: 'Welcome',
      title: 'A portfolio built\nlike a product',
      body:
          'Explore selected mobile and web work, the stack behind it and the thinking that shaped it — all without creating an account.',
      icon: Icons.auto_awesome_rounded,
      colors: <Color>[Color(0xFF7C5CFF), Color(0xFF2EE6D6)],
    ),
    _Slide(
      eyebrow: 'Projects',
      title: 'Search the work,\nopen the details',
      body:
          'Filter by platform or technology, then open a project for the problem, the approach and the links to the live build and source.',
      icon: Icons.grid_view_rounded,
      colors: <Color>[Color(0xFF2EE6D6), Color(0xFF66A3FF)],
    ),
    _Slide(
      eyebrow: 'Contact',
      title: 'Start a project\nin under a minute',
      body:
          'Send a short brief from the Contact tab and it lands in a private inbox. Signing in is only for the owner’s admin tools.',
      icon: Icons.send_rounded,
      colors: <Color>[Color(0xFFFFB86B), Color(0xFFFF7C9C)],
    ),
  ];

  Future<void> _finish() async {
    await ref.read(preferencesProvider).markOnboardingSeen();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _next() {
    if (_index == _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: Motion.duration(context, Motion.normal),
      curve: Motion.standard,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _index == _slides.length - 1;
    final double gutter = AppSpacing.gutter(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, 8, gutter - 8, 0),
                child: Row(
                  children: <Widget>[
                    Text('PORTFOLIO', style: AppType.overline(color: AppColors.textMuted)),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (int index) => setState(() => _index = index),
                  itemBuilder: (BuildContext context, int index) {
                    return _SlideView(slide: _slides[index], index: index);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 16),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(_slides.length, (int i) {
                        final bool active = i == _index;
                        return AnimatedContainer(
                          duration: Motion.duration(context, Motion.normal),
                          curve: Motion.standard,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: active ? 26 : 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: active
                                ? const LinearGradient(colors: AppColors.auraGradient)
                                : null,
                            color: active ? null : Colors.white.withValues(alpha: 0.18),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        'Step ${_index + 1} of ${_slides.length}',
                        style: AppType.labelSmall(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PrimaryActionButton(
                      label: isLast ? 'Explore the portfolio' : 'Next',
                      icon: isLast ? Icons.arrow_forward_rounded : null,
                      onPressed: _next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () {
                        Toast.show(context, 'You can find this guide again in About.');
                        _finish();
                      },
                      child: Text(
                        'Browse as a visitor',
                        style: AppType.labelSmall(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.index});

  final _Slide slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    final double gutter = AppSpacing.gutter(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AnimatedEntry(
            index: 0,
            child: Center(child: _Illustration(slide: slide, index: index)),
          ),
          const SizedBox(height: AppSpacing.xl),
          AnimatedEntry(
            index: 1,
            child: Text(slide.eyebrow.toUpperCase(), style: AppType.overline()),
          ),
          const SizedBox(height: 10),
          AnimatedEntry(
            index: 2,
            child: Text(slide.title, style: AppType.displayMedium()),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedEntry(
            index: 3,
            child: Text(slide.body, style: AppType.bodyLarge()),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.slide, required this.index});

  final _Slide slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.sizeOf(context).width.clamp(240.0, 420.0).toDouble() * 0.62;
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  slide.colors.first.withValues(alpha: 0.30),
                  slide.colors.last.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  slide.colors.first.withValues(alpha: 0.26),
                  slide.colors.last.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(color: AppColors.borderStrong),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: slide.colors.first.withValues(alpha: 0.28),
                  blurRadius: 46,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: (index.isEven ? 1 : -1) * 0.08,
              child: Icon(slide.icon, size: size * 0.22, color: Colors.white),
            ),
          ),
          Positioned(
            top: size * 0.08,
            right: size * 0.04,
            child: _Orb(color: slide.colors.last, size: 22),
          ),
          Positioned(
            bottom: size * 0.12,
            left: size * 0.02,
            child: _Orb(color: slide.colors.first, size: 14),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.5),
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 18, spreadRadius: 2),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    required this.colors,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final List<Color> colors;
}
