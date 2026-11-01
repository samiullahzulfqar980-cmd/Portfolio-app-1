import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/app_profile.dart';
import '../errors/app_failure.dart';
import '../utils/storage_urls.dart';

/// Opens external links (socials, email, phone, résumé) safely.
class LauncherService {
  const LauncherService();

  Future<bool> openUrl(String url, {bool external = true}) async {
    final String trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw const AppFailure('This link is not available yet.', code: 'missing_link');
    }
    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      throw const AppFailure('This link looks invalid.', code: 'bad_link');
    }
    try {
      final bool launched = await launchUrl(
        uri,
        mode: external ? LaunchMode.externalApplication : LaunchMode.platformDefault,
      );
      if (!launched) {
        throw const AppFailure(
          'No app on this device can open that link.',
          code: 'no_handler',
        );
      }
      return true;
    } catch (error, stack) {
      if (kDebugMode) debugPrint('[LauncherService.openUrl] $error\n$stack');
      if (error is AppFailure) rethrow;
      throw const AppFailure('Could not open that link.', code: 'launch_failed');
    }
  }

  Future<bool> openSocial(SocialLink link) {
    switch (link.key) {
      case 'email':
        return openEmail(link.url);
      case 'whatsapp':
        if (link.url.startsWith('http')) return openUrl(link.url);
        final String digits = link.url.replaceAll(RegExp(r'[^0-9]'), '');
        return openUrl('https://wa.me/$digits');
      default:
        return openUrl(link.url);
    }
  }

  Future<bool> openEmail(String address, {String? subject}) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: address.trim(),
      queryParameters: subject == null || subject.trim().isEmpty ? null : <String, String>{'subject': subject},
    );
    return openUrl(uri.toString(), external: false);
  }

  Future<bool> openPhone(String number) {
    final String cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    return openUrl('tel:$cleaned', external: false);
  }

  /// Résumé lives in Supabase Storage; opens the PDF in the platform viewer.
  Future<bool> openResume(String? path) {
    final String url = StorageUrl.resume(path);
    if (url.isEmpty) {
      throw const AppFailure(
        'No résumé has been published yet. Check back soon.',
        code: 'missing_resume',
      );
    }
    return openUrl(url);
  }
}

/// Icon mapping for social keys (kept UI-agnostic for reuse in admin).
const Map<String, String> socialGlyph = <String, String>{
  'github': 'GH',
  'linkedin': 'in',
  'whatsapp': 'WA',
  'x': 'X',
  'website': 'WWW',
  'dribbble': 'Dr',
};
