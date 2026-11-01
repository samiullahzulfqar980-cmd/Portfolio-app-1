import 'dart:convert';

/// Compile-time configuration.
///
/// Values are injected with `--dart-define-from-file=.env` (or individual
/// `--dart-define` flags). Nothing secret is ever bundled: the Supabase anon
/// key is a *public* key that is protected by Row Level Security, and the app
/// refuses to boot if a service-role key is detected.
class AppEnv {
  const AppEnv._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String appUrlScheme = String.fromEnvironment(
    'APP_URL_SCHEME',
    defaultValue: 'portfolioapp',
  );

  /// Deep link that Supabase redirects to after password reset / email confirm.
  static String get authRedirectUrl => '$appUrlScheme://auth-callback';

  /// True when URL + key are present and still placeholders.
  static bool get hasValues =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static bool get hasPlaceholders =>
      supabaseUrl.contains('YOUR-') || supabaseAnonKey.contains('YOUR_');

  /// A usable Supabase configuration exists.
  static bool get isConfigured => hasValues && !hasPlaceholders;

  static bool get isConfiguredHttp =>
      isConfigured && (supabaseUrl.startsWith('https://') || supabaseUrl.startsWith('http://'));

  /// Decodes the `role` claim of the configured JWT without verifying it.
  /// Used only to stop a service-role key from ever shipping in the app.
  static String? get anonKeyRole {
    if (!hasValues) return null;
    final parts = supabaseAnonKey.split('.');
    if (parts.length != 3) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (payload is Map<String, dynamic>) return payload['role'] as String?;
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Blocks boot when a privileged key was accidentally shipped.
  static bool get hasPrivilegedKey => anonKeyRole == 'service_role';
}
