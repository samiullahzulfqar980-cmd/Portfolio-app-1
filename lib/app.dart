import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_env.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
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
    // Follow the OS reduced-motion + high-contrast intent.
    final MediaQueryData media = MediaQuery.maybeOf(context) ?? const MediaQueryData();

    return MaterialApp.router(
      title: 'Portfolio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      darkTheme: AppTheme.build(),
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            // Keep text responsive to OS settings but avoid layouts breaking
            // past 160% — the largest setting that still fits a phone screen.
            textScaler: data.textScaler.clamp(maxScaleFactor: 1.6),
          ),
          child: _DeepLinkListener(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

/// Routes password-recovery deep links to the "set a new password" screen.
class _DeepLinkListener extends ConsumerStatefulWidget {
  const _DeepLinkListener({required this.child});

  final Widget child;

  @override
  ConsumerState<_DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<_DeepLinkListener> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    if (!_handled) {
      _handled = true;
      // supabase_flutter parses tokens from the incoming deep link before the
      // first frame; detect that here and send the user to the reset flow.
      final String? fragment = Uri.base.fragment;
      final bool hasRecoveryToken = Uri.base.host == 'auth-callback' ||
          (fragment.contains('type=recovery') && fragment.contains('access_token='));
      if (hasRecoveryToken && AppEnv.isConfigured) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go(AppRoutes.resetPassword);
        });
      }
    }
    return widget.child;
  }
}
