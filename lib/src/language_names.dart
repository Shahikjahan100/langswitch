import 'dart:ui' show Locale;

/// Native language names keyed by BCP-47 language tag.
///
/// These names are written in the language itself (endonyms), so a user can
/// identify their own language even when the UI is in an unfamiliar language.
class LanguageNames {
  LanguageNames._();

  /// Map from BCP-47 language tag to the language's name in that language.
  static const Map<String, String> _names = {
    'af': 'Afrikaans',
    'am': 'አማርኛ',
    'ar': 'العربية',
    'az': 'Azərbaycan',
    'be': 'Беларуская',
    'bg': 'Български',
    'bn': 'বাংলা',
    'bs': 'Bosanski',
    'ca': 'Català',
    'cs': 'Čeština',
    'cy': 'Cymraeg',
    'da': 'Dansk',
    'de': 'Deutsch',
    'el': 'Ελληνικά',
    'en': 'English',
    'es': 'Español',
    'et': 'Eesti',
    'eu': 'Euskara',
    'fa': 'فارسی',
    'fi': 'Suomi',
    'fil': 'Filipino',
    'fr': 'Français',
    'gl': 'Galego',
    'gu': 'ગુજરાતી',
    'ha': 'Hausa',
    'he': 'עברית',
    'hi': 'हिन्दी',
    'hr': 'Hrvatski',
    'hu': 'Magyar',
    'hy': 'Հայերեն',
    'id': 'Indonesia',
    'is': 'Íslenska',
    'it': 'Italiano',
    'ja': '日本語',
    'ka': 'ქართული',
    'kk': 'Қазақ',
    'km': 'ខ្មែរ',
    'kn': 'ಕನ್ನಡ',
    'ko': '한국어',
    'lt': 'Lietuvių',
    'lv': 'Latviešu',
    'mk': 'Македонски',
    'ml': 'മലയാളം',
    'mn': 'Монгол',
    'mr': 'मराठी',
    'ms': 'Melayu',
    'my': 'မြန်မာ',
    'nb': 'Norsk bokmål',
    'ne': 'नेपाली',
    'nl': 'Nederlands',
    'or': 'ଓଡ଼ିଆ',
    'pa': 'ਪੰਜਾਬੀ',
    'pl': 'Polski',
    'pt': 'Português',
    'pt-BR': 'Português (Brasil)',
    'pt-PT': 'Português (Portugal)',
    'ro': 'Română',
    'ru': 'Русский',
    'si': 'සිංහල',
    'sk': 'Slovenčina',
    'sl': 'Slovenščina',
    'sq': 'Shqip',
    'sr': 'Српски',
    'sr-Latn': 'Srpski (latinica)',
    'sv': 'Svenska',
    'sw': 'Kiswahili',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'th': 'ภาษาไทย',
    'tr': 'Türkçe',
    'uk': 'Українська',
    'ur': 'اردو',
    'uz': 'O\'zbek',
    'vi': 'Tiếng Việt',
    'yo': 'Yorùbá',
    'zh': '中文',
    'zh-Hans': '中文（简体）',
    'zh-Hant': '中文（繁體）',
    'zh-Hans-CN': '中文（简体，中国）',
    'zh-Hant-TW': '中文（繁體，台灣）',
    'zh-Hant-HK': '中文（繁體，香港）',
    'zu': 'isiZulu',
  };

  /// Returns the native name for [locale], or `null` if not found.
  ///
  /// Lookup order: exact tag → language+script → language+country → language only.
  static String? nameFor(Locale locale) {
    final exact = locale.toLanguageTag();
    if (_names.containsKey(exact)) return _names[exact];

    if (locale.scriptCode != null) {
      final langScript = '${locale.languageCode}-${locale.scriptCode}';
      if (_names.containsKey(langScript)) return _names[langScript];
    }

    if (locale.countryCode != null) {
      final langCountry = '${locale.languageCode}-${locale.countryCode}';
      if (_names.containsKey(langCountry)) return _names[langCountry];
    }

    return _names[locale.languageCode];
  }
}
