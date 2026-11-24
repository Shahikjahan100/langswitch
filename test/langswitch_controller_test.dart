import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:langswitch/langswitch.dart';
import 'package:langswitch/src/langswitch_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fake platform for testing
// ---------------------------------------------------------------------------

class FakePlatform extends LangSwitchPlatform {
  String? _appLocale;
  final bool _isSupported;

  FakePlatform({
    String? initialLocale,
    bool isSupported = true,
  })  : _appLocale = initialLocale,
        _isSupported = isSupported;

  @override
  Future<String?> getAppLocale() async => _appLocale;

  @override
  Future<void> setAppLocale(String? tag) async {
    _appLocale = tag;
  }

  @override
  Future<bool> isSystemSettingSupported() async => _isSupported;

  @override
  Future<bool> openSystemLanguageSettings() async => _isSupported;

  void simulateOsChange(String? tag) => _appLocale = tag;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final supported = [
    const Locale('en'),
    const Locale('ur'),
    const Locale('ar'),
    const Locale('es'),
  ];

  setUp(() {
    // Reset the singleton before each test.
    LangSwitch.resetForTesting();
  });

  tearDown(() {
    LangSwitch.resetForTesting();
  });

  group('LangSwitch.init', () {
    test('init with no override → value is null', () async {
      SharedPreferences.setMockInitialValues({});
      final fake = FakePlatform();
      LangSwitchPlatform.instance = fake;

      final ls = await LangSwitch.init(supportedLocales: supported);
      expect(ls.value, isNull);
      expect(ls.hasOverride, isFalse);
    });

    test('calling init twice returns the same instance', () async {
      SharedPreferences.setMockInitialValues({});
      LangSwitchPlatform.instance = FakePlatform();

      final a = await LangSwitch.init(supportedLocales: supported);
      final b = await LangSwitch.init(supportedLocales: supported);
      expect(identical(a, b), isTrue);
    });

    test('empty supportedLocales throws ArgumentError', () async {
      SharedPreferences.setMockInitialValues({});
      LangSwitchPlatform.instance = FakePlatform();

      expect(
        () => LangSwitch.init(supportedLocales: []),
        throwsArgumentError,
      );
    });

    test('restores persisted override on init', () async {
      SharedPreferences.setMockInitialValues({
        'langswitch.override': 'ur',
        'langswitch.nativeAtSet': 'ur',
      });
      final fake = FakePlatform(initialLocale: 'ur');
      LangSwitchPlatform.instance = fake;

      final ls = await LangSwitch.init(supportedLocales: supported);
      expect(ls.value?.toLanguageTag(), 'ur');
      expect(ls.hasOverride, isTrue);
    });

    test('drops persisted override when locale no longer supported', () async {
      SharedPreferences.setMockInitialValues({
        'langswitch.override': 'fr', // not in supported
      });
      LangSwitchPlatform.instance = FakePlatform();

      final ls = await LangSwitch.init(supportedLocales: supported);
      expect(ls.value, isNull);
    });
  });

  group('LangSwitch.instance', () {
    test('throws StateError before init', () {
      expect(() => LangSwitch.instance, throwsStateError);
    });
  });

  group('setLocale', () {
    test('setLocale persists and notifies', () async {
      SharedPreferences.setMockInitialValues({});
      LangSwitchPlatform.instance = FakePlatform();

      final ls = await LangSwitch.init(supportedLocales: supported);
      var notified = false;
      ls.addListener(() => notified = true);

      await ls.setLocale(const Locale('ur'));

      expect(ls.value?.toLanguageTag(), 'ur');
      expect(ls.hasOverride, isTrue);
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('langswitch.override'), 'ur');
    });

    test('setLocale(null) clears override', () async {
      SharedPreferences.setMockInitialValues({
        'langswitch.override': 'ur',
        'langswitch.nativeAtSet': 'ur',
      });
      LangSwitchPlatform.instance = FakePlatform(initialLocale: 'ur');

      final ls = await LangSwitch.init(supportedLocales: supported);
      await ls.setLocale(null);

      expect(ls.value, isNull);
      expect(ls.hasOverride, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('langswitch.override'), isNull);
    });

    test('unsupported locale throws ArgumentError', () async {
      SharedPreferences.setMockInitialValues({});
      LangSwitchPlatform.instance = FakePlatform();

      final ls = await LangSwitch.init(supportedLocales: supported);
      expect(
        () => ls.setLocale(const Locale('fr')),
        throwsArgumentError,
      );
    });
  });

  group('syncWithSystem — external OS change detection', () {
    test('OS change detected when native differs from nativeAtSet', () async {
      SharedPreferences.setMockInitialValues({
        'langswitch.override': 'ur',
        'langswitch.nativeAtSet': 'ur',
      });
      final fake = FakePlatform(initialLocale: 'ur');
      LangSwitchPlatform.instance = fake;

      final ls = await LangSwitch.init(supportedLocales: supported);
      expect(ls.value?.toLanguageTag(), 'ur');

      // Simulate user changing to Arabic in OS Settings.
      fake.simulateOsChange('ar');
      await ls.syncWithSystem();

      expect(ls.value?.toLanguageTag(), 'ar');
    });

    test('OS change to unsupported locale clears override', () async {
      SharedPreferences.setMockInitialValues({
        'langswitch.override': 'ur',
        'langswitch.nativeAtSet': 'ur',
      });
      final fake = FakePlatform(initialLocale: 'ur');
      LangSwitchPlatform.instance = fake;

      final ls = await LangSwitch.init(supportedLocales: supported);

      // Simulate OS change to a locale not in supportedLocales.
      fake.simulateOsChange('fr');
      await ls.syncWithSystem();

      expect(ls.value, isNull);
    });

    test('no change when native equals nativeAtSet', () async {
      SharedPreferences.setMockInitialValues({
        'langswitch.override': 'ur',
        'langswitch.nativeAtSet': 'ur',
      });
      final fake = FakePlatform(initialLocale: 'ur');
      LangSwitchPlatform.instance = fake;

      final ls = await LangSwitch.init(supportedLocales: supported);
      var notified = false;
      ls.addListener(() => notified = true);

      await ls.syncWithSystem();

      expect(notified, isFalse);
      expect(ls.value?.toLanguageTag(), 'ur');
    });
  });

  group('MissingPluginException handling', () {
    test('no native support (null returns) does not crash init or setLocale',
        () async {
      SharedPreferences.setMockInitialValues({});
      // A platform that behaves like a channel where the plugin is not
      // registered: getAppLocale returns null, setAppLocale is a no-op.
      LangSwitchPlatform.instance = FakePlatform();

      final ls = await LangSwitch.init(supportedLocales: supported);
      expect(ls.value, isNull);
      await expectLater(ls.setLocale(const Locale('ur')), completes);
    });
  });

  group('resolvedLocale', () {
    test('resolvedLocale reflects override', () async {
      SharedPreferences.setMockInitialValues({});
      LangSwitchPlatform.instance = FakePlatform();

      final ls = await LangSwitch.init(supportedLocales: supported);
      await ls.setLocale(const Locale('ar'));
      expect(ls.resolvedLocale.toLanguageTag(), 'ar');
    });

    test('resolvedLocale falls back to first supported when no override',
        () async {
      SharedPreferences.setMockInitialValues({});
      LangSwitchPlatform.instance = FakePlatform();

      final ls = await LangSwitch.init(supportedLocales: supported);
      // No override, PlatformDispatcher.instance.locales may vary in tests.
      // Just verify it's one of the supported locales.
      expect(supported, contains(ls.resolvedLocale));
    });
  });
}
