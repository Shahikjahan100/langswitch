import 'langswitch_platform.dart';

/// Dart-only plugin registration for platforms without native support
/// (Linux, macOS, Windows).
///
/// In-app locale switching and persistence still work on these platforms;
/// only the OS per-app language screen integration is unavailable.
class LangswitchDartOnly {
  /// Called by the Flutter plugin system to register this platform
  /// implementation.
  static void registerWith() {
    LangSwitchPlatform.instance = NoOpLangSwitchPlatform();
  }
}
