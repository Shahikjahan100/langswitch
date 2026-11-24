// ignore_for_file: avoid_print
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Locale tag validation and discovery from project artifacts.
class LocaleDiscovery {
  LocaleDiscovery._();

  /// Parses [rawTags], a comma-separated list of BCP-47 tags (e.g. `"en,ur,ar"`).
  ///
  /// Throws [ArgumentError] on the first invalid tag.
  static List<String> fromFlag(String rawTags) {
    final tags = rawTags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    for (final tag in tags) {
      _validateTag(tag);
    }
    return tags;
  }

  /// Auto-detects supported locales from [projectRoot].
  ///
  /// Detection order:
  /// 1. `l10n.yaml` → `arb-dir` → `@@locale` or filename suffix in each ARB.
  /// 2. Direct scan of `lib/l10n/*.arb`.
  ///
  /// Returns `null` if no locales could be discovered.
  static List<String>? fromProject(String projectRoot) {
    final l10nFile = File(p.join(projectRoot, 'l10n.yaml'));
    String arbDir = p.join(projectRoot, 'lib', 'l10n');

    if (l10nFile.existsSync()) {
      final yaml = loadYaml(l10nFile.readAsStringSync());
      if (yaml is YamlMap) {
        final rawDir = yaml['arb-dir'];
        if (rawDir is String) {
          arbDir = p.isAbsolute(rawDir) ? rawDir : p.join(projectRoot, rawDir);
        }
      }
    }

    return _scanArbDir(arbDir);
  }

  static List<String>? _scanArbDir(String arbDir) {
    final dir = Directory(arbDir);
    if (!dir.existsSync()) return null;

    final tags = <String>{};
    for (final entry in dir.listSync()) {
      if (entry is File && entry.path.endsWith('.arb')) {
        final tag = _tagFromArb(entry);
        if (tag != null) tags.add(tag);
      }
    }
    if (tags.isEmpty) return null;
    final result = tags.toList()..sort();
    return result;
  }

  static String? _tagFromArb(File arb) {
    try {
      final content = arb.readAsStringSync();
      // Check @@locale key first.
      final localeMatch =
          RegExp(r'"@@locale"\s*:\s*"([^"]+)"').firstMatch(content);
      if (localeMatch != null) {
        final tag = localeMatch.group(1)!;
        try {
          _validateTag(tag);
          return tag;
        } on ArgumentError {
          // Skip invalid tag.
        }
      }
    } catch (_) {
      return null;
    }

    // Fall back to filename suffix: app_ur.arb → ur, app_pt_BR.arb → pt-BR.
    final name = p.basenameWithoutExtension(arb.path);
    final parts = name.split('_');
    if (parts.length >= 2) {
      // Try last two segments as lang_COUNTRY (e.g. pt_BR → pt-BR).
      final last = parts.last;
      final penultimate = parts[parts.length - 2];
      if (_isCountryCode(last)) {
        final candidate = '$penultimate-$last';
        try {
          _validateTag(candidate);
          return candidate;
        } on ArgumentError {
          // Fall through to single-segment.
        }
      }
      final langOnly = parts.last;
      try {
        _validateTag(langOnly);
        return langOnly;
      } on ArgumentError {
        return null;
      }
    }
    return null;
  }

  /// Validates [tag] as a BCP-47 language tag.
  ///
  /// Throws [ArgumentError] with an explanatory message on failure.
  static void _validateTag(String tag) {
    if (tag.isEmpty) {
      throw ArgumentError.value(tag, 'tag', 'Must not be empty.');
    }

    final parts = tag.split('-');
    final lang = parts[0];

    // Language code: 2–3 lowercase ASCII letters.
    if (!RegExp(r'^[a-z]{2,3}$').hasMatch(lang)) {
      throw ArgumentError.value(
        tag,
        'tag',
        "'$lang' is not a valid BCP-47 language subtag "
            '(expected 2–3 lowercase letters, e.g. "en", "pt").',
      );
    }

    if (parts.length == 2) {
      final sub = parts[1];
      // Script: 4 letters, first uppercase.
      final isScript = RegExp(r'^[A-Z][a-z]{3}$').hasMatch(sub);
      // Country/region: 2 uppercase letters or 3 digits.
      final isRegion = RegExp(r'^[A-Z]{2}$|^\d{3}$').hasMatch(sub);
      if (!isScript && !isRegion) {
        throw ArgumentError.value(
          tag,
          'tag',
          "'$sub' is not a valid BCP-47 script (e.g. 'Hans') "
              'or region (e.g. "BR") subtag.',
        );
      }
    }
    if (parts.length == 3) {
      final script = parts[1];
      final region = parts[2];
      if (!RegExp(r'^[A-Z][a-z]{3}$').hasMatch(script)) {
        throw ArgumentError.value(
          tag,
          'tag',
          "'$script' is not a valid script subtag.",
        );
      }
      if (!RegExp(r'^[A-Z]{2}$|^\d{3}$').hasMatch(region)) {
        throw ArgumentError.value(
          tag,
          'tag',
          "'$region' is not a valid region subtag.",
        );
      }
    }
    if (parts.length > 3) {
      throw ArgumentError.value(
        tag,
        'tag',
        "Too many subtags in '$tag'. "
            'Supported: language, language-script, language-country, '
            'language-script-country.',
      );
    }
  }

  /// Validates all [tags], throwing [ArgumentError] on the first invalid one.
  static void validateAll(List<String> tags) {
    for (final tag in tags) {
      _validateTag(tag);
    }
  }

  static bool _isCountryCode(String s) =>
      RegExp(r'^[A-Z]{2}$|^\d{3}$').hasMatch(s);
}
