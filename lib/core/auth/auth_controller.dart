import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';
import '../errors/app_failure.dart';
import '../supabase/supabase_bootstrap.dart';

/// Thin, testable wrapper around Supabase Auth.
///
/// Screens own their own loading state; every method throws [AppFailure] with
/// a user-facing message so errors can be rendered inline.
class AuthController {
  AuthController({GoTrueClient? auth}) : _auth = auth;

  final GoTrueClient? _auth;

  GoTrueClient get _client => _auth ?? SupabaseBootstrap.client.auth;

  bool get isSupported => _auth != null || SupabaseBootstrap.isReady;

  User? get currentUser => isSupported ? _client.currentUser : null;

  void _ensureSupported() {
    if (!isSupported) {
      throw const AppFailure(
        'Authentication needs a Supabase project. Add SUPABASE_URL and SUPABASE_ANON_KEY, '
        'then restart the app.',
        code: 'not_configured',
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _ensureSupported();
    try {
      await _client.signInWithPassword(email: email.trim(), password: password);
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[Auth.signIn] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not sign you in. Please try again.');
    }
  }

  /// Returns `true` when the account needs email confirmation before sign-in.
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _ensureSupported();
    try {
      final AuthResponse response = await _client.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{
          if (fullName != null && fullName.trim().isNotEmpty) 'full_name': fullName.trim(),
        },
        emailRedirectTo: AppEnv.authRedirectUrl,
      );
      return response.session == null;
    } on AuthException catch (error, stack) {
      if (kDebugMode) debugPrint('[Auth.signUp] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not create your account.');
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[Auth.signUp] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not create your account.');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _ensureSupported();
    try {
      await _client.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppEnv.authRedirectUrl,
      );
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[Auth.resetPassword] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not send the reset email.');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    _ensureSupported();
    try {
      await _client.updateUser(UserAttributes(password: newPassword));
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[Auth.updatePassword] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not update your password.');
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    _ensureSupported();
    try {
      await _client.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: AppEnv.authRedirectUrl,
      );
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[Auth.resend] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not resend the verification email.');
    }
  }

  Future<void> signOut() async {
    if (!isSupported) return;
    try {
      await _client.signOut();
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[Auth.signOut] $error\n$stack');
      throw ErrorMapper.map(error, fallback: 'Could not sign out. Please try again.');
    }
  }
}

final Provider<AuthController> authControllerProvider =
    Provider<AuthController>((Ref ref) => AuthController());
