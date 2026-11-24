import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'langswitch_platform.dart';
import 'locale_resolver.dart';
import 'storage.dart';

/// Per-app language controller.
///
/// Call [LangSwitch.init] once in `main()` before `runApp()`, then access the
/// singleton via [LangSwitch.instance].
///
/// [LangSwitch] is a [ChangeNotifier] and a [ValueListenable<Locale?>] so it
/// integrates directly with [ValueListenableBuilder] and [AnimatedBuilder].
class LangSwitch extends ChangeNotifier implements ValueListenable<Locale?> {
  LangSwitch._({
    required List<Locale> supportedLocales,
    Locale? fallbackLocale,
    required bool persist,
    required LangSwitchStorage? storage,
  })  : _supportedLocales = List<Locale>.unmodifiable(supportedLocales),
        _fallbackLocale = fallbackLocale,
        _persist = persist,
        _storage = storage;

  static LangSwitch? _instance;
  static _LangSwitchLifecycleObserver? _observer;

  final List<Locale> _supportedLocales;
  final Locale? _fallbackLocale;
  final bool _persist;
  final LangSwitchStorage? _storage;

  Locale? _override;

  // The value of getAppLocale() captured right after the last setLocale call.
  // Used to detect out-of-process OS language changes.
  String? _nativeAtSet;

  Locale get _effectiveFallback => _fallbackLocale ?? _supportedLocales.first;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Initializes the [LangSwitch] singleton.
  ///
  /// Must be called once in `main()` after [WidgetsFlutterBinding.ensureInitialized]
  /// and before [runApp]. Subsequent calls return the existing instance unchanged.
  ///
  /// - [supportedLocales]: the locales your app supports (must be non-empty).
  /// - [fallbackLocale]: used when no match is found; defaults to the first entry.
  /// - [persist]: when `false`, language choice is in-memory only.
  ///
  /// Throws [ArgumentError] if [supportedLocales] is empty.
  static Future<LangSwitch> init({
    required List<Locale> supportedLocales,
    Locale? fallbackLocale,
    bool persist = true,
  }) async {
    if (_instance != null) return _instance!;

    if (supportedLocales.isEmpty) {
      throw ArgumentError.value(
        supportedLocales,
        'supportedLocales',
        'Must contain at least one locale.',
      );
    }

    final storage = persist ? await LangSwitchStorage.create() : null;
    final instance = LangSwitch._(
      supportedLocales: supportedLocales,
      fallbackLocale: fallbackLocale,
      persist: persist,
      storage: storage,
    );
    _instance = instance;

    if (storage != null) {
      final savedTag = storage.override;
      if (savedTag != null) {
        final parsed = LocaleResolver.parseTag(savedTag);
        final resolved = LocaleResolver.resolveOrNull(parsed, supportedLocales);
        if (resolved != null) {
          instance._override = parsed;
        }
        // If resolved == null: locale no longer supported, drop the override.
      }
      instance._nativeAtSet = storage.nativeAtSet;
    }

    final obs = _LangSwitchLifecycleObserver(instance);
    _observer = obs;
    WidgetsBinding.instance.addObserver(obs);
    await instance.syncWithSystem();
    return instance;
  }

  /// The [LangSwitch] singleton.
  ///
  /// Throws [StateError] if [init] has not been called.
  static LangSwitch get instance {
    if (_instance == null) {
      throw StateError(
        'LangSwitch.init() must be called and awaited before accessing '
        'LangSwitch.instance. Call it in main() after '
        'WidgetsFlutterBinding.ensureInitialized().',
      );
    }
    return _instance!;
  }

  /// Resets the singleton for use in unit tests.
  ///
  /// Removes the lifecycle observer and clears the stored instance.
  /// Not intended for production use.
  @visibleForTesting
  static void resetForTesting() {
    if (_observer != null) {
      WidgetsBinding.instance.removeObserver(_observer!);
      _observer = null;
    }
    _instance?.dispose();
    _instance = null;
  }

  // ---------------------------------------------------------------------------
  // ValueListenable<Locale?>
  // ---------------------------------------------------------------------------

  /// The locale currently applied to the app, or `null` to follow the device.
  ///
  /// Pass this to `MaterialApp.locale`. When `null`, Flutter resolves the
  /// locale from the device's (or per-app) language settings.
  @override
  Locale? get value => _override;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Alias for [value]; convenient for `MaterialApp.locale`.
  Locale? get locale => _override;

  /// The locale actually used by the app after resolving [value] against
  /// [supportedLocales]. Never `null`.
  ///
  /// When [value] is `null`, this is resolved from the device's current locales.
  Locale get resolvedLocale {
    if (_override != null) {
      return LocaleResolver.resolve(
          _override!, _supportedLocales, _effectiveFallback);
    }
    final systemLocales = PlatformDispatcher.instance.locales;
    if (systemLocales.isEmpty) return _effectiveFallback;
    return LocaleResolver.resolve(
        systemLocales.first, _supportedLocales, _effectiveFallback);
  }

  /// The locales this app was initialised with.
  List<Locale> get supportedLocales => _supportedLocales;

  /// `true` when the user has explicitly chosen a language in-app or the OS
  /// has set a per-app language. `false` when following the device language.
  bool get hasOverride => _override != null;

  /// Sets the app language to [locale], or clears the override when `null`.
  ///
  /// - Persists the choice (unless [persist] was `false`).
  /// - On Android 13+, also updates the OS per-app language setting so the
  ///   system language screen stays in sync.
  /// - Notifies listeners.
  ///
  /// Throws [ArgumentError] if [locale] is not `null` and does not resolve to
  /// any of the [supportedLocales].
  Future<void> setLocale(Locale? locale) async {
    if (locale != null) {
      final resolved = LocaleResolver.resolveOrNull(locale, _supportedLocales);
      if (resolved == null) {
        throw ArgumentError(
          "Locale '${locale.toLanguageTag()}' cannot be resolved to any "
          'supported locale. Supported: '
          '${_supportedLocales.map((l) => l.toLanguageTag()).join(', ')}',
        );
      }
    }

    final platform = LangSwitchPlatform.instance;
    final tag = locale?.toLanguageTag();

    await platform.setAppLocale(tag);
    final native = await platform.getAppLocale();
    _nativeAtSet = native;

    _override = locale;

    if (_persist && _storage != null) {
      await _storage.setOverride(tag);
      await _storage.setNativeAtSet(native);
    }

    notifyListeners();
  }

  /// Whether the OS has a per-app language settings screen.
  ///
  /// `true` on Android 13+ and iOS, `false` on older Android and desktop.
  Future<bool> get isSystemSettingSupported =>
      LangSwitchPlatform.instance.isSystemSettingSupported();

  /// Opens the OS per-app language settings screen.
  ///
  /// Returns `true` on success. On Android 13+, opens
  /// `ACTION_APP_LOCALE_SETTINGS`. On iOS, opens the app's Settings page.
  /// Returns `false` when the platform does not support this.
  Future<bool> openSystemLanguageSettings() =>
      LangSwitchPlatform.instance.openSystemLanguageSettings();

  /// Re-reads the OS language and reconciles it with the in-app override.
  ///
  /// Called automatically on [AppLifecycleState.resumed] and locale changes.
  /// You can also call it manually after returning from a custom settings flow.
  Future<void> syncWithSystem() async {
    final native = await LangSwitchPlatform.instance.getAppLocale();

    if (_override != null && native != _nativeAtSet) {
      // The OS per-app language was changed externally (e.g. Settings app).
      final nativeLocale =
          native != null ? LocaleResolver.parseTag(native) : null;
      final resolved = nativeLocale != null
          ? LocaleResolver.resolveOrNull(nativeLocale, _supportedLocales)
          : null;

      _override = resolved != null ? nativeLocale : null;
      _nativeAtSet = native;

      if (_persist && _storage != null) {
        await _storage.setOverride(_override?.toLanguageTag());
        await _storage.setNativeAtSet(native);
      }

      notifyListeners();
    }
  }
}

/// Listens for app lifecycle and locale changes and delegates to [LangSwitch].
class _LangSwitchLifecycleObserver extends WidgetsBindingObserver {
  _LangSwitchLifecycleObserver(this._controller);

  final LangSwitch _controller;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.syncWithSystem();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    _controller.syncWithSystem();
  }
}
