import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_env.dart';
import 'core/providers/app_providers.dart';
import 'core/supabase/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF06080F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // A privileged key must never ship in a client binary — fail closed.
  if (AppEnv.hasPrivilegedKey) {
    runApp(const _FatalConfigApp(
      message: 'A Supabase service_role key was supplied to this app. '
          'Remove it and use the anon (public) key, which is safe with Row Level Security.',
    ));
    return;
  }

  try {
    await SupabaseBootstrap.initialize();
  } catch (error) {
    runApp(_FatalConfigApp(message: 'Supabase could not start: $error'));
    return;
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: <Override>[preferencesProvider.overrideWithValue(Preferences(prefs))],
      child: const PortfolioApp(),
    ),
  );
}

/// Rendered when configuration is invalid, so the failure is obvious in dev
/// builds instead of a blank screen or a silent crash.
class _FatalConfigApp extends StatelessWidget {
  const _FatalConfigApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF06080F),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.gpp_maybe_rounded, color: Color(0xFFFF6B81), size: 42),
                const SizedBox(height: 16),
                const Text(
                  'Configuration error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(message, style: const TextStyle(color: Color(0xFFACB4C8), height: 1.5)),
                const SizedBox(height: 20),
                const Text(
                  'See README.md → "Supabase configuration" for the exact steps.',
                  style: TextStyle(color: Color(0xFF7A849C), height: 1.5, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
