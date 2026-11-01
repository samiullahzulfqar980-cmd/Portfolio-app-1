import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_buttons.dart';

/// Consistent chrome for admin screens (back, title, optional actions).
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.child,
    this.eyebrow = 'Admin',
    this.actions,
    this.floatingActionButton,
    this.bottomBar,
  });

  final String title;
  final Widget child;
  final String eyebrow;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.92),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: RoundIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.admin);
                }
              },
            ),
          ),
        ),
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(eyebrow.toUpperCase(), style: AppType.overline(color: AppColors.accentSoft)),
            Text(title, style: AppType.headlineMedium()),
          ],
        ),
        actions: actions,
      ),
      body: AppBackground(child: SafeArea(top: false, child: child)),
    );
  }
}

/// Reusable "no Supabase connected" notice for admin screens.
class AdminOfflineNotice extends StatelessWidget {
  const AdminOfflineNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.26)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, size: 17, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Admin tools need a Supabase project. Add your keys to .env and reinstall the app — '
              'see README → Supabase configuration.',
              style: AppType.bodySmall(color: AppColors.warning).copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Row action used in admin list items.
class AdminIconAction extends StatelessWidget {
  const AdminIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.tone = AppColors.textSecondary,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 19,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      icon: Icon(icon, color: onPressed == null ? AppColors.textMuted : tone),
    );
  }
}
