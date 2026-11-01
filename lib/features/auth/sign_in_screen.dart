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

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.nextLocation});

  final String? nextLocation;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _emailNotConfirmed = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    dismissKeyboard(context);
    setState(() {
      _error = null;
      _emailNotConfirmed = false;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).signIn(
            email: _email.text,
            password: _password.text,
          );
      if (!mounted) return;
      Haptics.success();
      final bool admin = await ref.read(isAdminProvider.future);
      if (!mounted) return;
      if (widget.nextLocation != null && widget.nextLocation!.isNotEmpty) {
        context.go(Uri.decodeComponent(widget.nextLocation!));
      } else if (admin) {
        context.go(AppRoutes.admin);
      } else {
        Toast.show(
          context,
          'Signed in — this account does not have admin access.',
          tone: ToastTone.info,
        );
        context.go(AppRoutes.home);
      }
    } catch (error) {
      if (!mounted) return;
      Haptics.error();
      final AppFailure failure = ErrorMapper.map(error);
      setState(() {
        _loading = false;
        _error = failure.message;
        _emailNotConfirmed = failure.code == 'email_not_confirmed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool configured = ref.read(authControllerProvider).isSupported;

    return AuthScaffold(
      eyebrow: 'Welcome back',
      title: 'Sign in',
      subtitle:
          'Signing in unlocks the admin area. Visitors never need an account to browse the portfolio.',
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!configured) ...<Widget>[
                const InlineErrorCard(
                  message:
                      'Supabase is not configured yet. Add SUPABASE_URL and SUPABASE_ANON_KEY to .env, then restart.',
                ),
                const SizedBox(height: 14),
              ],
              AppTextField(
                controller: _email,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.username, AutofillHints.email],
                prefixIcon: Icons.alternate_email_rounded,
                validator: Validators.email,
                enabled: !_loading,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _password,
                label: 'Password',
                hint: 'Your password',
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.password],
                prefixIcon: Icons.lock_outline_rounded,
                validator: (String? value) =>
                    (value ?? '').isEmpty ? 'Password is required.' : null,
                onSubmitted: (_) => _loading ? null : _signIn(),
                enabled: !_loading,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : () => context.push(AppRoutes.forgotPassword),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Forgot password?'),
                ),
              ),
              if (_error != null) ...<Widget>[
                InlineErrorCard(message: _error!),
                if (_emailNotConfirmed) ...<Widget>[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push(
                      '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(_email.text.trim())}',
                    ),
                    icon: const Icon(Icons.mark_email_unread_outlined, size: 16),
                    label: const Text('Resend the confirmation email'),
                  ),
                ],
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 6),
              PrimaryActionButton(
                label: 'Sign in',
                icon: Icons.login_rounded,
                isLoading: _loading,
                onPressed: _loading ? null : _signIn,
              ),
              const SizedBox(height: 14),
              const AuthNote(
                text:
                    'Sessions are stored in the device keychain and refreshed automatically. You can sign out at any time.',
                icon: Icons.verified_user_outlined,
              ),
            ],
          ),
        ),
      ),
      footer: Column(
        children: <Widget>[
          Text('First time here?', style: AppType.labelSmall(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _loading
                ? null
                : () => context.push(
                      widget.nextLocation == null
                          ? AppRoutes.signUp
                          : '${AppRoutes.signUp}?next=${Uri.encodeComponent(widget.nextLocation!)}',
                    ),
            child: const Text('Create the owner account'),
          ),
        ],
      ),
    );
  }
}
