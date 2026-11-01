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
      // Browsers only implement the platform-default mode (which opens a new
      // tab); asking for `externalApplication` there throws on some versions.
      final LaunchMode mode = external && !kIsWeb
          ? LaunchMode.externalApplication
          : LaunchMode.platformDefault;
      final bool launched = await launchUrl(uri, mode: mode);
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
        return openWhatsApp(link.url);
      default:
        return openUrl(link.url);
    }
  }

  /// Opens a WhatsApp chat.
  ///
  /// Accepts a `wa.me` / `api.whatsapp.com` link, a `whatsapp://send` deep link
  /// or a plain number such as `+92 347 0563895`. Plain numbers are normalised
  /// to digits only, which is what wa.me expects (no `+`, no spaces).
  Future<bool> openWhatsApp(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const AppFailure(
        'No WhatsApp number has been published yet.',
        code: 'missing_whatsapp',
      );
    }
    if (trimmed.startsWith('http') || trimmed.startsWith('whatsapp:')) {
      return openUrl(trimmed);
    }
    final String digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8) {
      throw const AppFailure(
        'That WhatsApp number looks incomplete.',
        code: 'bad_whatsapp',
      );
    }
    return openUrl('https://wa.me/$digits');
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
