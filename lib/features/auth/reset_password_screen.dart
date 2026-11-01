import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/router/app_router.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';
import 'auth_scaffold.dart';

/// Shown after a recovery deep link. Supabase creates a short-lived session
/// from the link; this screen sets a new password while that session is valid.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _hasRecoverySession =>
      SupabaseBootstrap.isReady && SupabaseBootstrap.client.auth.currentSession != null;

  Future<void> _save() async {
    dismissKeyboard(context);
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).updatePassword(_password.text);
      if (!mounted) return;
      Haptics.success();
      setState(() {
        _loading = false;
        _done = true;
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
    if (!_hasRecoverySession) {
      return AuthScaffold(
        eyebrow: 'Password reset',
        title: 'Link expired',
        subtitle:
            'This reset link is no longer valid or was already used. Request a fresh link to continue.',
        child: Column(
          children: <Widget>[
            PrimaryActionButton(
              label: 'Request a new link',
              icon: Icons.refresh_rounded,
              onPressed: () => context.go(AppRoutes.forgotPassword),
            ),
            const SizedBox(height: 10),
            SecondaryActionButton(
              label: 'Back to sign in',
              onPressed: () => context.go(AppRoutes.signIn),
            ),
          ],
        ),
      );
    }

    return AuthScaffold(
      eyebrow: 'Password reset',
      title: _done ? 'Password updated' : 'Choose a new password',
      subtitle: _done
          ? 'Your password has been changed and the recovery session closed.'
          : 'Pick something you have not used before. You will stay signed in on this device.',
      child: _done
          ? SuccessCard(
              title: 'All set',
              message: 'Use your new password the next time you sign in.',
              actionLabel: 'Open admin area',
              onAction: () => context.go(AppRoutes.admin),
            )
          : GlassCard(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppTextField(
                      controller: _password,
                      label: 'New password',
                      hint: 'At least 8 characters',
                      obscure: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.newPassword],
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: (String? value) => Validators.password(value, signUp: true),
                      enabled: !_loading,
                    ),
                    PasswordStrength(password: _password.text),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _confirm,
                      label: 'Confirm new password',
                      hint: 'Repeat the password',
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.lock_reset_rounded,
                      validator: (String? value) =>
                          Validators.confirmPassword(value, _password.text),
                      onSubmitted: (_) => _loading ? null : _save(),
                      enabled: !_loading,
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      InlineErrorCard(message: _error!),
                    ],
                    const SizedBox(height: 16),
                    PrimaryActionButton(
                      label: 'Update password',
                      icon: Icons.check_rounded,
                      isLoading: _loading,
                      onPressed: _loading ? null : _save,
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () async {
                              try {
                                await ref.read(authControllerProvider).signOut();
                              } on AppFailure catch (_) {}
                              if (context.mounted) context.go(AppRoutes.signIn);
                            },
                      child: const Text('Cancel and sign out'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Signed in as ${SupabaseBootstrap.client.auth.currentUser?.email ?? 'unknown'}',
                      style: AppType.labelSmall(color: const Color(0xFF7A849C)),
                    ),
                  ],
                ),
              ),
            ),
      footer: const SizedBox.shrink(),
    );
  }
}
