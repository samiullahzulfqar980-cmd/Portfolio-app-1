/// Field-level validation shared by every form in the app.
///
/// Every validator returns `null` when valid, otherwise a short, human message
/// that is shown inline under the field.
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
    r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static final RegExp _url = RegExp(r'^https?://[\w.-]+(?::\d+)?(?:/[^\s]*)?$');

  static final RegExp _slug = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

  static const int nameMin = 2;
  static const int nameMax = 80;
  static const int messageMin = 12;
  static const int messageMax = 2000;
  static const int passwordMin = 8;

  static String? email(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Email address is required.';
    if (v.length > 254) return 'That email address is too long.';
    if (!_email.hasMatch(v)) return 'Enter a valid email address, e.g. you@example.com.';
    return null;
  }

  static String? password(String? value, {bool signUp = false}) {
    final String v = value ?? '';
    if (v.isEmpty) return 'Password is required.';
    if (signUp) {
      if (v.length < passwordMin) return 'Use at least $passwordMin characters.';
      if (v.length > 72) return 'Use at most 72 characters.';
      if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'[0-9]').hasMatch(v)) {
        return 'Mix letters and numbers for a stronger password.';
      }
    } else if (v.length < 1) {
      return 'Password is required.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  static String? name(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Please tell me your name.';
    if (v.length < nameMin) return 'That name looks too short.';
    if (v.length > nameMax) return 'Please use $nameMax characters or fewer.';
    if (RegExp(r'^(.)\1+$').hasMatch(v)) return 'Please enter a real name.';
    return null;
  }

  static String? message(String? value, {int min = messageMin, int max = messageMax}) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'A short message helps me reply usefully.';
    if (v.length < min) return 'Add a little more detail (at least $min characters).';
    if (v.length > max) return 'Please keep it under $max characters.';
    final int linkCount = RegExp(r'https?://').allMatches(v).length;
    if (linkCount > 3) return 'Too many links — please remove some.';
    if (RegExp(r'(.)\1{14,}').hasMatch(v)) return 'Please write a normal message.';
    return null;
  }

  static String? optionalSubject(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (v.length > 120) return 'Keep the subject under 120 characters.';
    return null;
  }

  static String? url(String? value, {bool required = false}) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return required ? 'A link is required.' : null;
    if (!_url.hasMatch(v)) return 'Use a full link starting with https://.';
    return null;
  }

  static String? slug(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'A slug is required.';
    if (!_slug.hasMatch(v)) return 'Use lowercase letters, numbers and dashes only.';
    return null;
  }

  static String? requiredText(String? value, {String label = 'This field', int max = 200}) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return '$label is required.';
    if (v.length > max) return 'Keep it under $max characters.';
    return null;
  }

  /// Derives a URL-safe slug from arbitrary text.
  static String slugify(String input) {
    final String base = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return base.isEmpty ? 'project' : base;
  }

  /// True when the text contains only whitespace or zero-width characters.
  static bool isBlank(String? value) {
    if (value == null) return true;
    return value.replaceAll(RegExp(r'[\s\u200B\u200C\u200D\uFEFF]'), '').isEmpty;
  }
}

/// Strips control characters and clamps length before anything is sent to
/// the database. The server re-validates everything; this keeps payloads tidy.
class Sanitizer {
  const Sanitizer._();

  static String clean(String input, {int maxLength = 500}) {
    final String withoutControl = input
        .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]'), '')
        .replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF]'), '');
    final String collapsed = withoutControl.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
    return collapsed.length > maxLength ? collapsed.substring(0, maxLength) : collapsed;
  }

  /// Keeps newlines but normalises everything else (used for long messages).
  static String multiline(String input, {int maxLength = 2000}) {
    final String withoutControl =
        input.replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]'), '');
    final String normalised = withoutControl
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return normalised.length > maxLength ? normalised.substring(0, maxLength) : normalised;
  }

  static String? cleanOptional(String? input, {int maxLength = 500}) {
    if (input == null) return null;
    final String value = clean(input, maxLength: maxLength);
    return value.isEmpty ? null : value;
  }

  /// Compact, non-reversible-ish signal for lightweight spam heuristics.
  static bool looksLikeSpam(String message) {
    final String lower = message.toLowerCase();
    final int links = RegExp(r'https?://').allMatches(lower).length;
    final bool promo = RegExp(
      r'\b(seo services|backlinks|guest post|crypto giveaway|casino|viagra|loan offer|click here to win)\b',
    ).hasMatch(lower);
    return links > 3 || promo || RegExp(r'(.)\1{14,}').hasMatch(lower);
  }
}
