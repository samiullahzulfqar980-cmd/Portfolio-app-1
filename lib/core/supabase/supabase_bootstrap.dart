import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';

/// Session storage backed by the OS keychain / keystore.
///
/// Supabase's default persistence uses SharedPreferences (plain text on
/// Android). This implementation keeps the refresh token in secure storage.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() => _storage.read(key: supabasePersistSessionKey);

  @override
  Future<bool> hasAccessToken() async =>
      (await _storage.read(key: supabasePersistSessionKey)) != null;

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: supabasePersistSessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: supabasePersistSessionKey);
}

class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static bool _ready = false;

  /// True when a Supabase client has been successfully created.
  static bool get isReady => _ready;

  /// Configures Supabase once. When credentials are missing or still
  /// placeholders the app continues in clearly-labelled preview mode.
  static Future<void> initialize() async {
    if (_ready) return;

    if (!AppEnv.isConfiguredHttp) {
      if (kDebugMode) {
        debugPrint(
          '[Supabase] Not configured — running in preview mode. '
          'Pass --dart-define-from-file=.env to connect your project.',
        );
      }
      return;
    }

    if (AppEnv.hasPrivilegedKey) {
      // Defensive: never allow a service-role key to ship inside the binary.
      throw StateError(
        'A Supabase service_role key was supplied to the app. '
        'Use the anon (public) key only and keep the service key on the server.',
      );
    }

    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
      debug: kDebugMode,
      // Sessions persist in the OS keychain/keystore instead of plain prefs.
      // Token refresh and deep-link handling use the library defaults.
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(),
      ),
    );

    _ready = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
