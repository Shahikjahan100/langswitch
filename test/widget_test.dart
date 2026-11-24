import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langswitch/langswitch.dart';
import 'package:langswitch/src/langswitch_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'langswitch_controller_test.dart' show FakePlatform;

void main() {
  final supported = [
    const Locale('en'),
    const Locale('ur'),
    const Locale('ar'),
  ];

  setUp(() => LangSwitch.resetForTesting());
  tearDown(() => LangSwitch.resetForTesting());

  Future<LangSwitch> init(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    LangSwitchPlatform.instance = FakePlatform();
    late LangSwitch ls;
    await tester.runAsync(() async {
      ls = await LangSwitch.init(supportedLocales: supported);
    });
    return ls;
  }

  group('LangSwitchBuilder', () {
    testWidgets('rebuilds when locale changes', (tester) async {
      final ls = await init(tester);

      final buildLocales = <Locale?>[];

      await tester.pumpWidget(
        MaterialApp(
          home: LangSwitchBuilder(
            builder: (context, locale, _) {
              buildLocales.add(locale);
              return Text(locale?.toLanguageTag() ?? 'null');
            },
          ),
        ),
      );

      expect(find.text('null'), findsOneWidget);

      await tester.runAsync(() => ls.setLocale(const Locale('ur')));
      await tester.pump();

      expect(find.text('ur'), findsOneWidget);
      expect(buildLocales.length, greaterThanOrEqualTo(2));
    });
  });

  group('showLangSwitchSheet', () {
    testWidgets('opens bottom sheet on narrow screen', (tester) async {
      await init(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showLangSwitchSheet(ctx),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // LanguagePicker is rendered inside the sheet.
      expect(find.text('System default'), findsOneWidget);
    });

    testWidgets('opens dialog on wide screen (>= 600 dp)', (tester) async {
      await init(tester);

      // Force a wide layout.
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showLangSwitchSheet(ctx, title: 'Pick'),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The AlertDialog title should be shown.
      expect(find.text('Pick'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });
  });

  group('LanguagePicker', () {
    testWidgets('shows system default and each supported locale',
        (tester) async {
      await init(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguagePicker(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('System default'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('اردو'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
    });

    testWidgets('selecting a locale calls setLocale', (tester) async {
      final ls = await init(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguagePicker(),
          ),
        ),
      );
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('اردو'));
      });
      await tester.pump();

      expect(ls.value?.toLanguageTag(), 'ur');
    });

    testWidgets('selecting system default clears override', (tester) async {
      SharedPreferences.setMockInitialValues({
        'langswitch.override': 'ur',
        'langswitch.nativeAtSet': 'ur',
      });
      LangSwitchPlatform.instance = FakePlatform(initialLocale: 'ur');
      late LangSwitch ls;
      await tester.runAsync(() async {
        ls = await LangSwitch.init(supportedLocales: supported);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LanguagePicker(),
          ),
        ),
      );
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('System default'));
      });
      await tester.pump();

      expect(ls.value, isNull);
    });
  });
}
