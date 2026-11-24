import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Abstract platform interface for native language-switching operations.
abstract class LangSwitchPlatform extends PlatformInterface {
  /// Constructs a [LangSwitchPlatform].
  LangSwitchPlatform() : super(token: _token);

  static final Object _token = Object();

  static LangSwitchPlatform _instance = MethodChannelLangSwitch();

  /// The current platform implementation.
  ///
  /// Defaults to [MethodChannelLangSwitch]. Tests and Dart-only platforms
  /// replace this with a suitable implementation.
  static LangSwitchPlatform get instance => _instance;

  /// Sets a custom platform implementation.
  static set instance(LangSwitchPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the BCP-47 tag of the OS per-app language, or `null`.
  ///
  /// - Android 13+: first tag from [LocaleManager.getApplicationLocales].
  /// - iOS: first entry in [Bundle.main.preferredLocalizations].
  /// - Android < 13 and others: always `null`.
  Future<String?> getAppLocale();

  /// Sets the OS per-app language to [tag], or clears it when [tag] is `null`.
  ///
  /// No-op (returns without throwing) on platforms that do not support
  /// per-app language settings.
  Future<void> setAppLocale(String? tag);

  /// Returns `true` if the OS has a per-app language settings screen.
  ///
  /// `true` on Android 13+ and iOS; `false` otherwise.
  Future<bool> isSystemSettingSupported();

  /// Opens the OS screen where the user can change this app's language.
  ///
  /// Returns `true` on success, `false` if unsupported or the intent failed.
  Future<bool> openSystemLanguageSettings();
}

/// Default [LangSwitchPlatform] implementation using a [MethodChannel].
class MethodChannelLangSwitch extends LangSwitchPlatform {
  /// The method channel used to call native code.
  @visibleForTesting
  static const MethodChannel channel = MethodChannel('dev.langswitch/native');

  @override
  Future<String?> getAppLocale() async {
    // MissingPluginException is treated as "no native support" and silently
    // ignored — this is the one allowed catch-and-ignore in the codebase.
    try {
      return await channel.invokeMethod<String?>('getAppLocale');
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> setAppLocale(String? tag) async {
    try {
      await channel.invokeMethod<void>('setAppLocale', <String, Object?>{
        'tag': tag,
      });
    } on MissingPluginException {
      // Silently ignored; native support is optional.
    }
  }

  @override
  Future<bool> isSystemSettingSupported() async {
    try {
      return await channel.invokeMethod<bool>('isSystemSettingSupported') ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> openSystemLanguageSettings() async {
    try {
      return await channel.invokeMethod<bool>('openSystemLanguageSettings') ??
          false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// No-op [LangSwitchPlatform] for platforms without native support
/// (Linux, macOS, Windows). In-app locale switching and persistence still work.
class NoOpLangSwitchPlatform extends LangSwitchPlatform {
  /// Constructs a [NoOpLangSwitchPlatform].
  NoOpLangSwitchPlatform();

  @override
  Future<String?> getAppLocale() async => null;

  @override
  Future<void> setAppLocale(String? tag) async {}

  @override
  Future<bool> isSystemSettingSupported() async => false;

  @override
  Future<bool> openSystemLanguageSettings() async => false;
}
