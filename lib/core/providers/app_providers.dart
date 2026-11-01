import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/contact_repository.dart';
import '../../data/repositories/portfolio_repository.dart';
import '../supabase/supabase_bootstrap.dart';

final Provider<PortfolioRepository> portfolioRepositoryProvider =
    Provider<PortfolioRepository>((Ref ref) => PortfolioRepository());

final Provider<AdminRepository> adminRepositoryProvider =
    Provider<AdminRepository>((Ref ref) => AdminRepository());

final Provider<ContactRepository> contactRepositoryProvider =
    Provider<ContactRepository>((Ref ref) => ContactRepository());

/// Current auth user (null when browsing as a visitor).
final StreamProvider<User?> authUserProvider = StreamProvider<User?>((Ref ref) async* {
  if (!SupabaseBootstrap.isReady) {
    yield null;
    return;
  }
  final GoTrueClient auth = SupabaseBootstrap.client.auth;
  yield auth.currentUser;
  yield* auth.onAuthStateChange.map((AuthState state) => state.session?.user);
});

final Provider<Session?> sessionProvider = Provider<Session?>((Ref ref) {
  if (!SupabaseBootstrap.isReady) return null;
  return SupabaseBootstrap.client.auth.currentSession;
});

/// Whether the signed-in user is the portfolio owner.
final FutureProvider<bool> isAdminProvider = FutureProvider<bool>((Ref ref) async {
  final User? user = ref.watch(authUserProvider).value;
  if (user == null) return false;
  return ref.watch(adminRepositoryProvider).isAdmin();
});

/// Local, non-sensitive flags (onboarding seen, last tab, ...).
class Preferences {
  Preferences(this._prefs);

  final SharedPreferences _prefs;

  static const String _onboardingKey = 'app.onboarding_completed.v1';
  static const String _lastTabKey = 'app.last_tab';

  bool get hasSeenOnboarding => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> markOnboardingSeen() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  Future<void> resetOnboarding() async {
    await _prefs.remove(_onboardingKey);
  }

  int get lastTab => _prefs.getInt(_lastTabKey) ?? 0;

  Future<void> setLastTab(int index) async {
    await _prefs.setInt(_lastTabKey, index);
  }
}

final Provider<Preferences> preferencesProvider = Provider<Preferences>((Ref ref) {
  throw UnimplementedError('preferencesProvider must be overridden at bootstrap');
});
