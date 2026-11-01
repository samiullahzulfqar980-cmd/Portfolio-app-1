import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_env.dart';
import '../../core/errors/app_failure.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../../core/utils/validators.dart';
import '../models/contact_message.dart';

class ContactSubmission {
  const ContactSubmission({
    required this.name,
    required this.email,
    required this.message,
    this.subject,
    this.serviceInterest,
    this.budgetRange,
    this.honeypot,
    this.formOpenedAt,
  });

  final String name;
  final String email;
  final String message;
  final String? subject;
  final String? serviceInterest;
  final String? budgetRange;

  /// Hidden field humans never fill; bots usually do.
  final String? honeypot;

  /// Used for a minimum-fill-time check.
  final DateTime? formOpenedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': Sanitizer.clean(name, maxLength: 80),
        'email': Sanitizer.clean(email, maxLength: 254).toLowerCase(),
        'message': Sanitizer.multiline(message, maxLength: 2000),
        'subject': Sanitizer.cleanOptional(subject, maxLength: 120),
        'service_interest': Sanitizer.cleanOptional(serviceInterest, maxLength: 80),
        'budget_range': Sanitizer.cleanOptional(budgetRange, maxLength: 40),
      };
}

class ContactRepository {
  ContactRepository({SupabaseClient? client, bool? useBackend})
      : _client = client,
        _useBackend = useBackend ?? (AppEnv.isConfiguredHttp && SupabaseBootstrap.isReady);

  final SupabaseClient? _client;
  final bool _useBackend;

  static const String _lastSubmitKey = 'contact.last_submit_at';
  static const Duration _cooldown = Duration(seconds: 45);
  static const Duration _minimumFillTime = Duration(seconds: 2);

  bool _sending = false;
  bool get isSending => _sending;

  /// Validates + submits an inquiry. Throws [AppFailure] with a friendly
  /// message when the submission is rejected.
  Future<void> submit(ContactSubmission submission) async {
    if (_sending) return;

    // 1. Client-side spam heuristics (server re-checks everything).
    if (!Validators.isBlank(submission.honeypot)) {
      throw const AppFailure(
        'Your submission was flagged. Please remove extra links and try again.',
        code: 'spam',
      );
    }

    final Duration? filledIn = submission.formOpenedAt == null
        ? null
        : DateTime.now().difference(submission.formOpenedAt!);
    if (filledIn != null && filledIn < _minimumFillTime) {
      throw const AppFailure('That was a little fast — please try again.', code: 'spam');
    }

    if (Sanitizer.looksLikeSpam(submission.message)) {
      throw const AppFailure(
        'Your message looks like spam. Please remove repeated links and try again.',
        code: 'spam',
      );
    }

    final String? nameError = Validators.name(submission.name);
    if (nameError != null) throw AppFailure(nameError, code: 'validation');
    final String? emailError = Validators.email(submission.email);
    if (emailError != null) throw AppFailure(emailError, code: 'validation');
    final String? messageError = Validators.message(submission.message);
    if (messageError != null) throw AppFailure(messageError, code: 'validation');

    // 2. Throttle repeated submissions from the same device.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? last = prefs.getInt(_lastSubmitKey);
    if (last != null) {
      final DateTime lastAt = DateTime.fromMillisecondsSinceEpoch(last);
      final Duration since = DateTime.now().difference(lastAt);
      if (since < _cooldown) {
        final int remaining = (_cooldown.inSeconds - since.inSeconds).clamp(1, 60).toInt();
        throw AppFailure(
          'You just sent a message. Please wait $remaining seconds before sending another.',
          code: 'cooldown',
        );
      }
    }

    _sending = true;
    try {
      if (!_useBackend) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (kDebugMode) {
          debugPrint('[ContactRepository] preview mode — payload ${jsonEncode(submission.toJson())}');
        }
        await prefs.setInt(_lastSubmitKey, DateTime.now().millisecondsSinceEpoch);
        return;
      }

      await (_client ?? SupabaseBootstrap.client).from('contact_messages').insert(
            submission.toJson(),
          );
      await prefs.setInt(_lastSubmitKey, DateTime.now().millisecondsSinceEpoch);
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[ContactRepository.submit] $error\n$stack');
      throw ErrorMapper.map(
        error,
        fallback: 'We could not send your message. Please try again, or email me directly.',
      );
    } finally {
      _sending = false;
    }
  }
}
