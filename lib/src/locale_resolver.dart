import 'dart:ui' show Locale;

/// Resolves a [Locale] from a list of supported locales using BCP-47 matching rules.
class LocaleResolver {
  LocaleResolver._();

  /// Resolves [requested] against [supported] using BCP-47 matching priority:
  ///
  /// 1. Exact match (language + script + country)
  /// 2. Language + script
  /// 3. Language + country
  /// 4. Language only
  /// 5. [fallback]
  static Locale resolve(
    Locale requested,
    List<Locale> supported,
    Locale fallback,
  ) {
    for (final l in supported) {
      if (_isExact(l, requested)) {
        return l;
      }
    }
    if (requested.scriptCode != null) {
      for (final l in supported) {
        if (l.languageCode == requested.languageCode &&
            l.scriptCode == requested.scriptCode) {
          return l;
        }
      }
    }
    if (requested.countryCode != null) {
      for (final l in supported) {
        if (l.languageCode == requested.languageCode &&
            l.countryCode == requested.countryCode) {
          return l;
        }
      }
    }
    for (final l in supported) {
      if (l.languageCode == requested.languageCode) {
        return l;
      }
    }
    return fallback;
  }

  /// Returns the resolved locale only if [requested] matches something in
  /// [supported] (at any level of specificity). Returns `null` when there is
  /// no match whatsoever, without falling back.
  static Locale? resolveOrNull(Locale requested, List<Locale> supported) {
    for (final l in supported) {
      if (_isExact(l, requested)) {
        return l;
      }
    }
    if (requested.scriptCode != null) {
      for (final l in supported) {
        if (l.languageCode == requested.languageCode &&
            l.scriptCode == requested.scriptCode) {
          return l;
        }
      }
    }
    if (requested.countryCode != null) {
      for (final l in supported) {
        if (l.languageCode == requested.languageCode &&
            l.countryCode == requested.countryCode) {
          return l;
        }
      }
    }
    for (final l in supported) {
      if (l.languageCode == requested.languageCode) {
        return l;
      }
    }
    return null;
  }

  /// Parses a BCP-47 language tag into a [Locale].
  ///
  /// Handles tags like `en`, `pt-BR`, `zh-Hans`, `zh-Hans-CN`, `sr-Latn`.
  static Locale parseTag(String tag) {
    final parts = tag.split('-');
    if (parts.length == 1) {
      return Locale(parts[0]);
    }
    if (parts.length == 2) {
      // A 4-character second segment with an uppercase first letter is a script code.
      final sub = parts[1];
      if (sub.length == 4 &&
          sub[0] == sub[0].toUpperCase() &&
          sub[0] != sub[0].toLowerCase()) {
        return Locale.fromSubtags(
          languageCode: parts[0],
          scriptCode: sub,
        );
      }
      return Locale.fromSubtags(
        languageCode: parts[0],
        countryCode: sub,
      );
    }
    if (parts.length >= 3) {
      return Locale.fromSubtags(
        languageCode: parts[0],
        scriptCode: parts[1],
        countryCode: parts[2],
      );
    }
    return Locale(parts[0]);
  }

  static bool _isExact(Locale a, Locale b) =>
      a.languageCode == b.languageCode &&
      a.scriptCode == b.scriptCode &&
      a.countryCode == b.countryCode;
}
