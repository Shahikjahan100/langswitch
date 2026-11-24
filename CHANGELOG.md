## 0.1.0

Initial release.

- `LangSwitch.init()` / `LangSwitch.instance` — singleton controller, `ChangeNotifier` and
  `ValueListenable<Locale?>`.
- Persistence via `SharedPreferences` with keys `langswitch.override` and
  `langswitch.nativeAtSet`.
- Android 13+ integration: `LocaleManager.setApplicationLocales` / `getApplicationLocales` via
  method channel `dev.langswitch/native`.
- iOS integration: `Bundle.main.preferredLocalizations` read-back; opens Settings via
  `UIApplication.openSettingsURLString`.
- External OS change detection: compares `getAppLocale()` to the `nativeAtSet` sentinel on
  resume and locale-change callbacks. The OS wins when they diverge.
- `LangSwitchBuilder` — `StatelessWidget` wrapping `ValueListenableBuilder<Locale?>`.
- `LanguagePicker` — embeddable list widget with endonym labels and selection indicator.
- `showLangSwitchSheet()` — bottom sheet on narrow screens, `AlertDialog` on wide.
- `LanguageNames.nameFor()` — native-language-name map for ~65 languages.
- `LocaleResolver` — pure BCP-47 resolution (exact → script → country → language → fallback).
- CLI `dart run langswitch:setup`: auto-detects locales from `l10n.yaml`/ARBs, writes
  `locales_config.xml`, patches `AndroidManifest.xml` and `Info.plist`. Supports `--dry-run`,
  `--check`, `--locales`, `--android-only`, `--ios-only`, `--yes`.
- Example app with `gen_l10n`, four locales (en, ur RTL, ar RTL, es), debug panel.
- Full unit, widget, and CLI test suite (47 tests).
- Dart-only fallback for Linux, macOS, Windows (no-op platform, in-app switching still works).
