import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_buttons.dart';

/// Shared layout for every authentication screen: back affordance, brand mark,
/// headline and a card for the form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.showBack = true,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final double gutter = AppSpacing.gutter(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        safeArea: false,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (showBack)
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.home);
                          }
                        },
                      )
                    else
                      const SizedBox(width: 44),
                    const Spacer(),
                    Text('OWNER ACCESS', style: AppType.overline(color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(eyebrow.toUpperCase(), style: AppType.overline()),
                const SizedBox(height: 8),
                Text(title, style: AppType.displayMedium()),
                const SizedBox(height: 10),
                Text(subtitle, style: AppType.bodyLarge(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xl),
                child,
                if (footer != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xl),
                  footer!,
                ],
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: Text(
                      'Continue browsing as a visitor',
                      style: AppType.labelSmall(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small inline note used under auth forms.
class AuthNote extends StatelessWidget {
  const AuthNote({super.key, required this.text, this.icon = Icons.info_outline_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: AppType.labelSmall(color: AppColors.textMuted).copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}

/// Password strength meter (4 segments) with an accessible description.
class PasswordStrength extends StatelessWidget {
  const PasswordStrength({super.key, required this.password});

  final String password;

  int get _score {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score.clamp(0, 4).toInt();
  }

  String get _label => switch (_score) {
        0 => 'Too short',
        1 => 'Weak',
        2 => 'Fair',
        3 => 'Good',
        _ => 'Strong',
      };

  Color get _color => switch (_score) {
        0 => AppColors.danger,
        1 => AppColors.danger,
        2 => AppColors.warning,
        3 => AppColors.accent,
        _ => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: 'Password strength: $_label',
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < 4; i++) ...<Widget>[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: i < _score ? _color : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 10),
            Text(
              _label,
              style: AppType.labelSmall(color: _color).copyWith(fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}
