import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_env.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

class PortfolioApp extends ConsumerStatefulWidget {
  const PortfolioApp({super.key});

  @override
  ConsumerState<PortfolioApp> createState() => _PortfolioAppState();
}

class _PortfolioAppState extends ConsumerState<PortfolioApp> {
  late final GoRouter _router = ref.read(appRouterProvider);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Portfolio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      darkTheme: AppTheme.build(),
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData data = MediaQuery.of(context);
        final Widget app = AuthDeepLinkListener(
          child: child ?? const SizedBox.shrink(),
        );
        return MediaQuery(
          data: data.copyWith(
            // Responsive to OS text size, but capped so phone layouts stay intact.
            textScaler: data.textScaler.clamp(maxScaleFactor: 1.6),
          ),
          // On tablets, desktop and the web build the app keeps a phone-width
          // canvas instead of stretching into a website-like layout.
          child: data.size.width < 620 ? app : _PhoneFrame(child: app),
        );
      },
    );
  }
}

/// Centres the app inside a phone-sized canvas on wide viewports (web/desktop)
/// so the mobile layout is preserved instead of being stretched edge to edge.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  static const double _width = 430;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(30));

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: SizedBox(
            width: _width,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _radius,
                border: Border.all(color: AppColors.borderStrong),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x73000000), blurRadius: 48, spreadRadius: 2),
                ],
              ),
              child: ClipRRect(borderRadius: _radius, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Routes password-recovery links to the "choose a new password" screen.
///
/// Two paths are covered:
///  * the cross-platform signal from Supabase (`passwordRecovery` auth event);
///  * a browser-style recovery fragment, useful on web/desktop targets.
class AuthDeepLinkListener extends ConsumerStatefulWidget {
  const AuthDeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AuthDeepLinkListener> createState() => _AuthDeepLinkListenerState();
}

class _AuthDeepLinkListenerState extends ConsumerState<AuthDeepLinkListener> {
  StreamSubscription<AuthState>? _subscription;
  bool _checkedInitialUri = false;

  @override
  void initState() {
    super.initState();
    if (!SupabaseBootstrap.isReady) return;
    _subscription = SupabaseBootstrap.client.auth.onAuthStateChange.listen(
      (AuthState state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          _openResetFlow();
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _openResetFlow() {
    if (!mounted) return;
    ref.read(appRouterProvider).go(AppRoutes.resetPassword);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedInitialUri) {
      _checkedInitialUri = true;
      final String fragment = Uri.base.fragment;
      final bool recoveryFromUri = Uri.base.host == 'auth-callback' ||
          (fragment.contains('type=recovery') && fragment.contains('access_token='));
      if (recoveryFromUri && AppEnv.isConfigured) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openResetFlow());
      }
    }
    return widget.child;
  }
}
