import 'package:flutter/widgets.dart';

import '../langswitch_controller.dart';

/// Rebuilds [builder] whenever the active language changes.
///
/// Place this directly around [MaterialApp] or [CupertinoApp] and pass the
/// [locale] and [supportedLocales] arguments through to the app widget:
///
/// ```dart
/// LangSwitchBuilder(
///   builder: (context, locale, supported) => MaterialApp(
///     locale: locale,
///     supportedLocales: supported,
///     localizationsDelegates: AppLocalizations.localizationsDelegates,
///     home: const HomePage(),
///   ),
/// );
/// ```
class LangSwitchBuilder extends StatelessWidget {
  /// Creates a [LangSwitchBuilder].
  ///
  /// [builder] receives the current [Locale?] (null = follow device) and the
  /// full list of supported locales from [LangSwitch.instance].
  const LangSwitchBuilder({required this.builder, super.key});

  /// Called each time the language changes.
  final Widget Function(
    BuildContext context,
    Locale? locale,
    List<Locale> supportedLocales,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LangSwitch.instance,
      builder: (context, locale, _) => builder(
        context,
        locale,
        LangSwitch.instance.supportedLocales,
      ),
    );
  }
}
