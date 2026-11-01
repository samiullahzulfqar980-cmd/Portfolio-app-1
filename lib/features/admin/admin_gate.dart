import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/state_views.dart';

/// Wraps every admin screen: requires a session *and* the admin role.
///
/// Row Level Security is the real enforcement; this gate only prevents a
/// confusing UI for signed-in non-admins.
class AdminGate extends ConsumerWidget {
  const AdminGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<User?> auth = ref.watch(authUserProvider);

    return auth.when(
      loading: () => const _GateScaffold(child: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stack) => _GateScaffold(
        child: ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(authUserProvider),
        ),
      ),
      data: (User? user) {
        if (user == null) {
          return _GateScaffold(child: const _SignInRequired());
        }
        final AsyncValue<bool> admin = ref.watch(isAdminProvider);
        return admin.when(
          loading: () => const _GateScaffold(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking access…'),
                ],
              ),
            ),
          ),
          error: (Object error, StackTrace stack) => _GateScaffold(
            child: ErrorStateView(
              error: error,
              onRetry: () => ref.invalidate(isAdminProvider),
            ),
          ),
          data: (bool isAdmin) {
            if (!isAdmin) {
              return _GateScaffold(child: _NotAdmin(email: user.email ?? ''));
            }
            return child;
          },
        );
      },
    );
  }
}

class _GateScaffold extends StatelessWidget {
  const _GateScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: RoundIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
            ),
          ),
        ),
        title: Text('Admin', style: AppType.headlineMedium()),
      ),
      body: AppBackground(child: child),
    );
  }
}

class _SignInRequired extends StatelessWidget {
  const _SignInRequired();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Owner sign in required', style: AppType.headlineMedium(), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'The admin area manages content and inquiries. Visitors can keep browsing everything else.',
            style: AppType.bodyMedium(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PrimaryActionButton(
            label: 'Sign in',
            icon: Icons.login_rounded,
            onPressed: () => context.push(
              '${AppRoutes.signIn}?next=${Uri.encodeComponent(AppRoutes.admin)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _NotAdmin extends ConsumerWidget {
  const _NotAdmin({required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.gpp_maybe_outlined, size: 42, color: AppColors.warning),
          const SizedBox(height: 16),
          Text('No admin access', style: AppType.headlineMedium(), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            email.isEmpty
                ? 'This account is not the portfolio owner.'
                : 'This account ($email) is not the portfolio owner.',
            style: AppType.bodyMedium(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Admin rights are granted in the database — see the README section “Grant admin access”.',
            style: AppType.labelSmall(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PrimaryActionButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            onPressed: () async {
              try {
                await ref.read(authControllerProvider).signOut();
                if (context.mounted) context.go(AppRoutes.home);
              } on AppFailure catch (failure) {
                if (context.mounted) Toast.error(context, failure.message);
              }
            },
          ),
          const SizedBox(height: 10),
          SecondaryActionButton(
            label: 'Back to portfolio',
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
