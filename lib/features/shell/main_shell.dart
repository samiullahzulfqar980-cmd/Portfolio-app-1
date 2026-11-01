import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Hosts the four primary tabs with a custom, one-hand-friendly tab bar.
///
/// Branch state (scroll positions, form drafts) is preserved by the
/// [StatefulShellRoute]; only the active branch participates in animations.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<_TabItem> _tabs = <_TabItem>[
    _TabItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    _TabItem(label: 'Projects', icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded),
    _TabItem(label: 'About', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
    _TabItem(label: 'Contact', icon: Icons.mail_outline_rounded, activeIcon: Icons.mail_rounded),
  ];

  void _onTap(int index) {
    if (index == navigationShell.currentIndex) {
      // Re-tapping the active tab returns to its root, like native apps.
      navigationShell.goBranch(index, initialLocation: true);
      return;
    }
    HapticFeedback.selectionClick();
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _TabBar(
        tabs: _tabs,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset > 0 ? bottomInset * 0.7 : 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.surfaceAlt.withValues(alpha: 0.96),
              AppColors.surface.withValues(alpha: 0.98),
            ],
          ),
          border: Border.all(color: AppColors.borderStrong.withValues(alpha: 0.5)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Row(
            children: List<Widget>.generate(tabs.length, (int index) {
              final bool selected = index == currentIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: tabs[index].label,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => onTap(index),
                    borderRadius: BorderRadius.circular(18),
                    splashColor: AppColors.primary.withValues(alpha: 0.10),
                    child: AnimatedContainer(
                      duration: Motion.duration(context, Motion.normal),
                      curve: Motion.standard,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: selected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  AppColors.primary.withValues(alpha: 0.30),
                                  AppColors.accent.withValues(alpha: 0.16),
                                ],
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AnimatedScale(
                            duration: Motion.duration(context, Motion.fast),
                            scale: selected ? 1.06 : 1,
                            child: Icon(
                              selected ? tabs[index].activeIcon : tabs[index].icon,
                              size: 21,
                              color: selected ? AppColors.textPrimary : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tabs[index].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.labelSmall(
                              color: selected ? AppColors.textPrimary : AppColors.textMuted,
                            ).copyWith(fontSize: 10.5, letterSpacing: 0.1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.label, required this.icon, required this.activeIcon});

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Keeps every tab branch alive while animating the active one in.
///
/// Inactive branches are `Offstage` + `TickerMode(enabled: false)` so they cost
/// nothing per frame but keep their scroll offset and form state.
class BranchTransitionStack extends StatefulWidget {
  const BranchTransitionStack({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<BranchTransitionStack> createState() => _BranchTransitionStackState();
}

class _BranchTransitionStackState extends State<BranchTransitionStack> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        for (int i = 0; i < widget.children.length; i++)
          _BranchTransition(
            active: i == widget.currentIndex,
            child: widget.children[i],
          ),
      ],
    );
  }
}

class _BranchTransition extends StatefulWidget {
  const _BranchTransition({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_BranchTransition> createState() => _BranchTransitionState();
}

class _BranchTransitionState extends State<_BranchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: widget.active ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant _BranchTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = Motion.reduced(context);
    if (!widget.active) {
      return Offstage(
        offstage: true,
        child: TickerMode(enabled: false, child: widget.child),
      );
    }
    if (reduceMotion) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: t.clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
        );
      },
      child: widget.child,
    );
  }
}
