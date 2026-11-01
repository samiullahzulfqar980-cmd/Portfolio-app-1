import 'package:flutter/material.dart';

/// Human-readable, non-leaky error text for the UI.
///
/// Internal details are logged in debug builds only; users always get an
/// actionable sentence plus a stable [code] they can quote to support.
class AppFailure implements Exception {
  const AppFailure(this.message, {this.code, this.isOffline = false});

  final String message;
  final String? code;
  final bool isOffline;

  @override
  String toString() => 'AppFailure($code): $message';
}

class ErrorMapper {
  const ErrorMapper._();

  static const String _generic =
      'Something went wrong on our side. Please try again in a moment.';

  /// Maps any thrown object (PostgrestException, AuthException, SocketException,
  /// PlatformException...) to a friendly [AppFailure].
  static AppFailure map(Object error, {String? fallback}) {
    if (error is AppFailure) return error;

    final String raw = error.toString();
    final String lower = raw.toLowerCase();

    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('clientexception') ||
        lower.contains('xmlhttprequest')) {
      return const AppFailure(
        'No connection. Check your network and try again.',
        code: 'offline',
        isOffline: true,
      );
    }

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return const AppFailure(
        'The request took too long. Please try again.',
        code: 'timeout',
        isOffline: true,
      );
    }

    if (lower.contains('invalid login credentials')) {
      return const AppFailure(
        'That email and password combination is not recognised.',
        code: 'invalid_credentials',
      );
    }

    if (lower.contains('email not confirmed')) {
      return const AppFailure(
        'Please confirm your email address first — check your inbox for the link.',
        code: 'email_not_confirmed',
      );
    }

    if (lower.contains('user already registered') || lower.contains('already been registered')) {
      return const AppFailure(
        'An account with this email already exists. Try signing in instead.',
        code: 'user_exists',
      );
    }

    if (lower.contains('password should be at least')) {
      return const AppFailure(
        'Please choose a stronger password (at least 8 characters).',
        code: 'weak_password',
      );
    }

    if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return const AppFailure(
        'Too many attempts. Please wait a minute and try again.',
        code: 'rate_limited',
      );
    }

    if (lower.contains('row-level security') || lower.contains('permission denied')) {
      return const AppFailure(
        'You do not have permission to do that.',
        code: 'permission_denied',
      );
    }

    if (lower.contains('jwt') || lower.contains('invalid api key')) {
      return const AppFailure(
        'The app is not connected to Supabase correctly. Check your configuration.',
        code: 'bad_config',
      );
    }

    return AppFailure(fallback ?? _generic);
  }

  /// Short text for inline field-level validation.
  static String? short(Object error) {
    final AppFailure f = map(error);
    return f.message;
  }
}
