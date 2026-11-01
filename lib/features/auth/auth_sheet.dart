import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_buttons.dart';

/// Entry point for optional owner authentication from anywhere in the app.
class AuthSheet {
  const AuthSheet._();

  static void showSignIn(BuildContext context, {String? next}) {
    _show(context, next: next);
  }

  static void _show(BuildContext context, {String? next}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (BuildContext sheetContext) {
        final String query = next == null ? '' : '?next=${Uri.encodeComponent(next)}';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Owner access', style: AppType.headlineMedium()),
                const SizedBox(height: 6),
                Text(
                  'Signing in is only needed to manage content and read inquiries. '
                  'Everything else stays open to visitors.',
                  style: AppType.bodySmall(color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                PrimaryActionButton(
                  label: 'Sign in',
                  icon: Icons.lock_open_rounded,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push('${AppRoutes.signIn}$query');
                  },
                ),
                const SizedBox(height: 10),
                SecondaryActionButton(
                  label: 'Create an account',
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push('${AppRoutes.signUp}$query');
                  },
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.push(AppRoutes.forgotPassword);
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
