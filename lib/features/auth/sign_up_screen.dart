import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/state_views.dart';
import 'auth_scaffold.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.nextLocation});

  final String? nextLocation;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _loading = false;
  bool _accepted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    dismissKeyboard(context);
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_accepted) {
      setState(() => _error = 'Please confirm you understand how this account is used.');
      return;
    }

    setState(() => _loading = true);
    try {
      final bool needsConfirmation = await ref.read(authControllerProvider).signUp(
            email: _email.text,
            password: _password.text,
            fullName: _name.text,
          );
      if (!mounted) return;
      Haptics.success();
      if (needsConfirmation) {
        context.go(
          '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(_email.text.trim())}',
        );
      } else {
        final bool admin = await ref.read(isAdminProvider.future);
        if (!mounted) return;
        if (admin) {
          context.go(AppRoutes.admin);
        } else {
          Toast.show(
            context,
            'Account created. Ask the project owner to grant admin access.',
            tone: ToastTone.info,
          );
          context.go(AppRoutes.home);
        }
      }
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
      eyebrow: 'Owner account',
      title: 'Create account',
      subtitle:
          'Only the portfolio owner needs an account. New accounts start without admin access — '
          'the owner email is granted rights in the database.',
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppTextField(
                controller: _name,
                label: 'Full name',
                hint: 'Your name',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const <String>[AutofillHints.name],
                prefixIcon: Icons.person_outline_rounded,
                maxLength: Validators.nameMax,
                validator: Validators.name,
                enabled: !_loading,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _email,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.email],
                prefixIcon: Icons.alternate_email_rounded,
                validator: Validators.email,
                enabled: !_loading,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _password,
                label: 'Password',
                hint: 'At least 8 characters, letters and numbers',
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
                label: 'Confirm password',
                hint: 'Repeat your password',
                obscure: true,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_reset_rounded,
                validator: (String? value) => Validators.confirmPassword(value, _password.text),
                onSubmitted: (_) => _loading ? null : _signUp(),
                enabled: !_loading,
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                InlineErrorCard(message: _error!),
              ],
              const SizedBox(height: 14),
              InkWell(
                onTap: () => setState(() => _accepted = !_accepted),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _accepted,
                          onChanged: (bool? value) => setState(() => _accepted = value ?? false),
                          activeColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.borderStrong),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'I understand this account is for managing the portfolio and reading inquiries.',
                          style: AppType.bodySmall(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PrimaryActionButton(
                label: 'Create account',
                icon: Icons.person_add_alt_1_rounded,
                isLoading: _loading,
                onPressed: _loading ? null : _signUp,
              ),
              const SizedBox(height: 12),
              const AuthNote(
                text:
                    'A verification email is sent by Supabase. Confirm it before signing in for the first time.',
              ),
            ],
          ),
        ),
      ),
      footer: Column(
        children: <Widget>[
          Text('Already have an account?', style: AppType.labelSmall(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _loading
                ? null
                : () => context.push(
                      widget.nextLocation == null
                          ? AppRoutes.signIn
                          : '${AppRoutes.signIn}?next=${Uri.encodeComponent(widget.nextLocation!)}',
                    ),
            child: const Text('Sign in instead'),
          ),
        ],
      ),
    );
  }
}
