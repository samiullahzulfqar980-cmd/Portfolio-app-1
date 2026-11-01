import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    dismissKeyboard(context);
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).sendPasswordReset(_email.text);
      if (!mounted) return;
      Haptics.success();
      setState(() {
        _loading = false;
        _sent = true;
      });
    } catch (error) {
      if (!mounted) return;
      Haptics.error();
      setState(() {
        _loading = false;
        _error = ErrorMapper.map(error).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'Password reset',
      title: 'Forgot your password?',
      subtitle:
          'Enter the email for your account and Supabase will send a single-use reset link. '
          'The link opens this app directly.',
      child: _sent
          ? SuccessCard(
              title: 'Check your inbox',
              message:
                  'If an account exists for ${_email.text.trim()}, a reset link is on its way. '
                  'Links expire after a short while — request a new one if needed.',
              actionLabel: 'Back to sign in',
              onAction: () => context.go(AppRoutes.signIn),
            )
          : GlassCard(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.email],
                      prefixIcon: Icons.alternate_email_rounded,
                      validator: Validators.email,
                      onSubmitted: (_) => _loading ? null : _send(),
                      enabled: !_loading,
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      InlineErrorCard(message: _error!),
                    ],
                    const SizedBox(height: 16),
                    PrimaryActionButton(
                      label: 'Send reset link',
                      icon: Icons.outgoing_mail,
                      isLoading: _loading,
                      onPressed: _loading ? null : _send,
                    ),
                    const SizedBox(height: 12),
                    const AuthNote(
                      text:
                          'For security, we show the same confirmation whether or not the address exists.',
                      icon: Icons.shield_outlined,
                    ),
                  ],
                ),
              ),
            ),
      footer: Text(
        'The reset link uses the portfolioapp:// URL scheme. If it does not open the app, '
        'check the deep-link setup in the README.',
        style: AppType.labelSmall(color: AppColors.textMuted).copyWith(height: 1.4),
        textAlign: TextAlign.center,
      ),
    );
  }
}
