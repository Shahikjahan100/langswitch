import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's language choice using [SharedPreferences].
///
/// Keys are prefixed with `langswitch.` to avoid collisions with the host app.
class LangSwitchStorage {
  static const String _keyOverride = 'langswitch.override';
  static const String _keyNativeAtSet = 'langswitch.nativeAtSet';

  final SharedPreferences _prefs;

  LangSwitchStorage._(this._prefs);

  /// Creates a [LangSwitchStorage] backed by [SharedPreferences].
  static Future<LangSwitchStorage> create() async {
    return LangSwitchStorage._(await SharedPreferences.getInstance());
  }

  /// The persisted BCP-47 override tag, or `null` if none is stored.
  String? get override => _prefs.getString(_keyOverride);

  /// The BCP-47 tag that [getAppLocale] returned right after the last
  /// [setLocale] call. Used to detect out-of-process OS changes.
  String? get nativeAtSet => _prefs.getString(_keyNativeAtSet);

  /// Persists [tag] as the override, or removes it when [tag] is `null`.
  Future<void> setOverride(String? tag) async {
    if (tag != null) {
      await _prefs.setString(_keyOverride, tag);
    } else {
      await _prefs.remove(_keyOverride);
    }
  }

  /// Persists [tag] as the last-known native locale, or removes it when
  /// [tag] is `null`.
  Future<void> setNativeAtSet(String? tag) async {
    if (tag != null) {
      await _prefs.setString(_keyNativeAtSet, tag);
    } else {
      await _prefs.remove(_keyNativeAtSet);
    }
  }
}
