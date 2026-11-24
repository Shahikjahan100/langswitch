import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:langswitch/langswitch.dart';

void main() {
  group('LocaleResolver.resolve', () {
    final supported = [
      const Locale('en'),
      const Locale('ur'),
      const Locale('ar'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
      const Locale('es'),
    ];
    const fallback = Locale('en');

    test('exact match', () {
      expect(
        LocaleResolver.resolve(const Locale('ur'), supported, fallback),
        const Locale('ur'),
      );
    });

    test('language + script match', () {
      expect(
        LocaleResolver.resolve(
          const Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
          supported,
          fallback,
        ),
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      );
    });

    test('language + country match', () {
      expect(
        LocaleResolver.resolve(
          const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
          supported,
          fallback,
        ),
        const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
      );
    });

    test('language-only match', () {
      expect(
        LocaleResolver.resolve(
          const Locale.fromSubtags(languageCode: 'es', countryCode: 'MX'),
          supported,
          fallback,
        ),
        const Locale('es'),
      );
    });

    test('falls back to fallback locale when no match', () {
      expect(
        LocaleResolver.resolve(
          const Locale('fr'),
          supported,
          fallback,
        ),
        fallback,
      );
    });

    test('sr-Latn does not match sr without script', () {
      final srSupported = [
        const Locale('sr'),
        const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
      ];
      expect(
        LocaleResolver.resolve(
          const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
          srSupported,
          const Locale('sr'),
        ),
        const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
      );
    });
  });

  group('LocaleResolver.resolveOrNull', () {
    final supported = [const Locale('en'), const Locale('ur')];

    test('returns match when found', () {
      expect(
        LocaleResolver.resolveOrNull(const Locale('ur'), supported),
        const Locale('ur'),
      );
    });

    test('returns null when no match', () {
      expect(
        LocaleResolver.resolveOrNull(const Locale('fr'), supported),
        isNull,
      );
    });

    test('script match in resolveOrNull', () {
      final scriptSupported = [
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ];
      final result = LocaleResolver.resolveOrNull(
        const Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
        scriptSupported,
      );
      expect(result,
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
    });

    test('country match in resolveOrNull', () {
      final countrySupported = [
        const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
      ];
      final result = LocaleResolver.resolveOrNull(
        const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
        countrySupported,
      );
      expect(result,
          const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'));
    });

    test('language-only match in resolveOrNull', () {
      final result = LocaleResolver.resolveOrNull(
        const Locale.fromSubtags(languageCode: 'en', countryCode: 'AU'),
        supported,
      );
      expect(result, const Locale('en'));
    });
  });

  group('LanguageNames', () {
    test('known language returns endonym', () {
      expect(LanguageNames.nameFor(const Locale('ar')), 'العربية');
      expect(LanguageNames.nameFor(const Locale('ur')), 'اردو');
      expect(LanguageNames.nameFor(const Locale('en')), 'English');
    });

    test('script fallback: zh-Hans-SG → zh-Hans entry', () {
      // Exact tag 'zh-Hans-SG' is not in the map; fallback to 'zh-Hans'.
      final locale = const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'SG',
      );
      expect(LanguageNames.nameFor(locale), '中文（简体）');
    });

    test('country fallback: pt-Latn-BR → pt-BR entry', () {
      // Exact tag 'pt-Latn-BR' is not in the map; script 'pt-Latn' also not in
      // map; fallback to country key 'pt-BR'.
      final locale = const Locale.fromSubtags(
        languageCode: 'pt',
        scriptCode: 'Latn',
        countryCode: 'BR',
      );
      expect(LanguageNames.nameFor(locale), 'Português (Brasil)');
    });

    test('language-only fallback', () {
      // 'pt-AU' is not in map; falls back to 'pt'.
      final locale =
          const Locale.fromSubtags(languageCode: 'pt', countryCode: 'AU');
      expect(LanguageNames.nameFor(locale), 'Português');
    });

    test('unknown language returns null', () {
      expect(LanguageNames.nameFor(const Locale('xx')), isNull);
    });
  });

  group('LocaleResolver.parseTag', () {
    test('language only', () {
      expect(LocaleResolver.parseTag('en').languageCode, 'en');
      expect(LocaleResolver.parseTag('en').scriptCode, isNull);
      expect(LocaleResolver.parseTag('en').countryCode, isNull);
    });

    test('language-country (pt-BR)', () {
      final l = LocaleResolver.parseTag('pt-BR');
      expect(l.languageCode, 'pt');
      expect(l.countryCode, 'BR');
      expect(l.scriptCode, isNull);
    });

    test('language-script (zh-Hans)', () {
      final l = LocaleResolver.parseTag('zh-Hans');
      expect(l.languageCode, 'zh');
      expect(l.scriptCode, 'Hans');
      expect(l.countryCode, isNull);
    });

    test('language-script-country (zh-Hans-CN)', () {
      final l = LocaleResolver.parseTag('zh-Hans-CN');
      expect(l.languageCode, 'zh');
      expect(l.scriptCode, 'Hans');
      expect(l.countryCode, 'CN');
    });

    test('sr-Latn', () {
      final l = LocaleResolver.parseTag('sr-Latn');
      expect(l.languageCode, 'sr');
      expect(l.scriptCode, 'Latn');
    });
  });
}
