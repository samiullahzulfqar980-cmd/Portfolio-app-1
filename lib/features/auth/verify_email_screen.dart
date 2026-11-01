import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';

/// "Check your inbox" screen shown after sign-up.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _loading = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 45);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    final String? email = widget.email;
    if (email == null || email.isEmpty) {
      Toast.error(context, 'No email address available. Please sign up again.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).resendVerificationEmail(email);
      if (!mounted) return;
      Haptics.success();
      setState(() => _loading = false);
      _startCooldown();
      Toast.success(context, 'Verification email sent.');
    } catch (error) {
      if (!mounted) return;
      Haptics.error();
      setState(() => _loading = false);
      Toast.error(context, ErrorMapper.map(error).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String email = widget.email?.trim() ?? '';

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
              onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.signIn),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSpacing.gutter(context), 8, AppSpacing.gutter(context), 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.primary.withValues(alpha: 0.35),
                      AppColors.accent.withValues(alpha: 0.18),
                    ],
                  ),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: const Icon(Icons.mark_email_unread_outlined, size: 28, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Check your inbox', style: AppType.displayMedium()),
              const SizedBox(height: 10),
              Text(
                email.isEmpty
                    ? 'A verification link is on its way. Open it to activate the account, then sign in.'
                    : 'We sent a verification link to $email. Open it to activate the account, then sign in.',
                style: AppType.bodyLarge(),
              ),
              const SizedBox(height: AppSpacing.xl),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Step(index: 1, text: 'Open the email from your Supabase project.'),
                    _Step(index: 2, text: 'Tap the confirmation link — it reopens this app.'),
                    _Step(index: 3, text: 'Sign in with the password you just created.'),
                    const SizedBox(height: 8),
                    const AuthNoteText(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryActionButton(
                label: _cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend email',
                icon: Icons.refresh_rounded,
                isLoading: _loading,
                onPressed: _loading || _cooldown > 0 ? null : _resend,
              ),
              const SizedBox(height: 10),
              SecondaryActionButton(
                label: 'I have verified — sign in',
                onPressed: () => context.go(AppRoutes.signIn),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  'Wrong address? Sign up again with the correct email.',
                  style: AppType.labelSmall(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Text(
              '$index',
              style: AppType.labelSmall(color: AppColors.primarySoft).copyWith(fontSize: 10.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppType.bodySmall(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class AuthNoteText extends StatelessWidget {
  const AuthNoteText({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Emails arrive from your own Supabase project. In local development, use the link printed '
            'in the Supabase CLI logs instead.',
            style: AppType.labelSmall(color: AppColors.textMuted).copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}
