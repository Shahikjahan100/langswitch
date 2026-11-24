/// One-command per-app language switching for Flutter.
///
/// ## Quick start
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await LangSwitch.init(supportedLocales: AppLocalizations.supportedLocales);
///   runApp(const MyApp());
/// }
/// ```
///
/// Then wrap your app widget:
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
///
/// And show the picker anywhere:
///
/// ```dart
/// ElevatedButton(
///   onPressed: () => showLangSwitchSheet(context),
///   child: const Text('Language'),
/// );
/// ```
library;

export 'src/langswitch_controller.dart' show LangSwitch;
export 'src/langswitch_dart_only.dart' show LangswitchDartOnly;
export 'src/language_names.dart' show LanguageNames;
export 'src/locale_resolver.dart' show LocaleResolver;
export 'src/widgets/language_picker.dart' show LanguagePicker;
export 'src/widgets/language_sheet.dart' show showLangSwitchSheet;
export 'src/widgets/langswitch_scope.dart' show LangSwitchBuilder;
