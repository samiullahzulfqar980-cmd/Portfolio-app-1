import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_app/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts normal addresses', () {
      expect(Validators.email('dev@example.com'), isNull);
      expect(Validators.email('first.last+tag@sub.example.co'), isNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('a@b.c'), isNotNull);
    });
  });

  group('Validators.whatsapp', () {
    test('accepts a plain international number', () {
      expect(Validators.whatsapp('+923470563895'), isNull);
      expect(Validators.whatsapp('+92 347 0563895'), isNull);
      expect(Validators.whatsapp('+92 (347) 056-3895'), isNull);
      expect(Validators.whatsapp('00923470563895'), isNull);
    });

    test('accepts a wa.me link', () {
      expect(Validators.whatsapp('https://wa.me/923470563895'), isNull);
    });

    test('is optional unless required', () {
      expect(Validators.whatsapp(''), isNull);
      expect(Validators.whatsapp('', required: true), isNotNull);
      expect(Validators.whatsapp(null, required: true), isNotNull);
    });

    test('rejects junk and too-short numbers', () {
      expect(Validators.whatsapp('call me maybe'), isNotNull);
      expect(Validators.whatsapp('12345'), isNotNull);
      expect(Validators.whatsapp('+92 347 0563895 1234567890'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('requires 8+ chars with letters and numbers on sign up', () {
      expect(Validators.password('short1', signUp: true), isNotNull);
      expect(Validators.password('allletters', signUp: true), isNotNull);
      expect(Validators.password('GoodPass123', signUp: true), isNull);
    });

    test('sign in only requires a non-empty value', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('x'), isNull);
    });
  });

  group('Validators.message', () {
    test('enforces length bounds', () {
      expect(Validators.message('short'), isNotNull);
      expect(Validators.message('A' * 2100), isNotNull);
      expect(Validators.message('I would like to build a cross-platform app.'), isNull);
    });

    test('rejects obvious link spam', () {
      expect(
        Validators.message('buy now http://a.co http://b.co http://c.co http://d.co'),
        isNotNull,
      );
    });
  });

  group('Sanitizer', () {
    test('strips control characters and collapses spaces', () {
      expect(Sanitizer.clean('  hello\u0000   world  '), 'hello world');
    });

    test('keeps newlines in multiline text', () {
      expect(Sanitizer.multiline('a\n\n\n\nb'), 'a\n\nb');
    });

    test('flags promo spam', () {
      expect(Sanitizer.looksLikeSpam('cheap seo services and backlinks'), isTrue);
      expect(Sanitizer.looksLikeSpam('Can you help with a Flutter app?'), isFalse);
    });
  });

  group('slugify', () {
    test('produces url-safe slugs', () {
      expect(Validators.slugify('FinPulse — Fintech Wallet'), 'finpulse-fintech-wallet');
      expect(Validators.slugify('   '), 'project');
      expect(Validators.slug('finpulse-fintech-wallet'), isNull);
      expect(Validators.slug('Bad Slug'), isNotNull);
    });
  });
}
