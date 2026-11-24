// ignore_for_file: avoid_print
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:langswitch/src/cli/android_setup.dart';
import 'package:langswitch/src/cli/file_edit.dart';
import 'package:langswitch/src/cli/ios_setup.dart';
import 'package:langswitch/src/cli/locale_discovery.dart';
import 'package:langswitch/src/cli/setup_command.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Directory _createFixtureProject(String tempBase) {
  final root = Directory(p.join(tempBase, 'project'))
    ..createSync(recursive: true);

  // Android manifest
  final manifestDir = Directory(
    p.join(root.path, 'android', 'app', 'src', 'main'),
  )..createSync(recursive: true);
  File(p.join(manifestDir.path, 'AndroidManifest.xml')).writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="example"
        android:name="\${applicationName}">
    </application>
</manifest>
''');

  // iOS Info.plist
  final iosDir = Directory(p.join(root.path, 'ios', 'Runner'))
    ..createSync(recursive: true);
  File(p.join(iosDir.path, 'Info.plist'))
      .writeAsStringSync('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CFBundleName</key>
\t<string>example</string>
</dict>
</plist>
''');

  return root;
}

void _addL10nYaml(Directory root, String arbDir) {
  File(p.join(root.path, 'l10n.yaml')).writeAsStringSync('''
arb-dir: $arbDir
template-arb-file: app_en.arb
''');
}

void _addArbFiles(Directory root, String arbDir, Map<String, String> locales) {
  final dir = Directory(p.join(root.path, arbDir))..createSync(recursive: true);
  for (final entry in locales.entries) {
    File(p.join(dir.path, 'app_${entry.key}.arb'))
        .writeAsStringSync('{"@@locale": "${entry.value}"}');
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('langswitch_cli_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('LocaleDiscovery', () {
    test('fromFlag parses comma-separated tags', () {
      expect(LocaleDiscovery.fromFlag('en,ur,ar,es'), ['en', 'ur', 'ar', 'es']);
    });

    test('fromFlag trims whitespace', () {
      expect(LocaleDiscovery.fromFlag(' en , ur '), ['en', 'ur']);
    });

    test('fromFlag throws on invalid tag', () {
      expect(
        () => LocaleDiscovery.fromFlag('en,123'),
        throwsArgumentError,
      );
    });

    test('fromFlag accepts 3-letter language code', () {
      expect(LocaleDiscovery.fromFlag('zho'), ['zho']);
    });

    test('fromFlag accepts language-country (pt-BR)', () {
      expect(LocaleDiscovery.fromFlag('pt-BR'), ['pt-BR']);
    });

    test('fromFlag accepts language-script (zh-Hans)', () {
      expect(LocaleDiscovery.fromFlag('zh-Hans'), ['zh-Hans']);
    });

    test('fromFlag accepts language-script-country (zh-Hans-CN)', () {
      expect(LocaleDiscovery.fromFlag('zh-Hans-CN'), ['zh-Hans-CN']);
    });

    test('fromFlag throws on invalid script subtag', () {
      expect(() => LocaleDiscovery.fromFlag('zh-hans'), throwsArgumentError);
    });

    test('fromFlag throws on invalid region subtag', () {
      expect(() => LocaleDiscovery.fromFlag('pt-br'), throwsArgumentError);
    });

    test('fromFlag throws on too many subtags', () {
      expect(() => LocaleDiscovery.fromFlag('en-Latn-US-extra'),
          throwsArgumentError);
    });

    test('fromProject detects locales from l10n.yaml + ARBs', () {
      final root = _createFixtureProject(tempDir.path);
      _addL10nYaml(root, 'lib/l10n');
      _addArbFiles(root, 'lib/l10n', {
        'en': 'en',
        'ur': 'ur',
        'ar': 'ar',
      });

      final locales = LocaleDiscovery.fromProject(root.path);
      expect(locales, isNotNull);
      expect(locales, containsAll(['en', 'ur', 'ar']));
    });

    test('fromProject falls back to lib/l10n when no l10n.yaml', () {
      final root = _createFixtureProject(tempDir.path);
      _addArbFiles(root, 'lib/l10n', {'en': 'en', 'es': 'es'});

      final locales = LocaleDiscovery.fromProject(root.path);
      expect(locales, containsAll(['en', 'es']));
    });

    test('fromProject returns null when no ARBs found', () {
      final root = _createFixtureProject(tempDir.path);
      expect(LocaleDiscovery.fromProject(root.path), isNull);
    });

    test('fromProject detects pt-BR from filename suffix', () {
      final root = _createFixtureProject(tempDir.path);
      // ARB with no @@locale key — detection falls back to filename.
      final arbDir = Directory(p.join(root.path, 'lib', 'l10n'))
        ..createSync(recursive: true);
      File(p.join(arbDir.path, 'app_pt_BR.arb')).writeAsStringSync('{}');
      File(p.join(arbDir.path, 'app_en.arb')).writeAsStringSync('{}');

      final locales = LocaleDiscovery.fromProject(root.path);
      expect(locales, isNotNull);
      expect(locales, containsAll(['pt-BR', 'en']));
    });
  });

  group('FileEditor', () {
    test('transform on existing file applies function', () {
      final file = File(p.join(tempDir.path, 'sample.txt'));
      file.writeAsStringSync('hello');
      final editor = FileEditor();
      final result = editor.transform(file.path, (s) => s.toUpperCase());
      expect(result.changed, isTrue);
      expect(file.readAsStringSync(), 'HELLO');
    });

    test('transform on missing file without create returns unchanged', () {
      final editor = FileEditor();
      final result = editor.transform(
        p.join(tempDir.path, 'nonexistent.txt'),
        (s) => s,
      );
      expect(result.changed, isFalse);
    });

    test('transform on missing file with create writes empty-transformed', () {
      final editor = FileEditor();
      final path = p.join(tempDir.path, 'new.txt');
      final result = editor.transform(path, (s) => 'created', create: true);
      expect(result.changed, isTrue);
      expect(File(path).readAsStringSync(), 'created');
    });

    test('write with longer before than after covers decreasing-diff branch',
        () {
      final file = File(p.join(tempDir.path, 'long.txt'));
      file.writeAsStringSync('line1\nline2\nline3\n');
      final editor = FileEditor(verbose: true);
      final result = editor.write(file.path, 'line1\n');
      expect(result.changed, isTrue);
    });
  });

  group('AndroidSetup', () {
    test('fresh project: creates locales_config.xml and patches manifest', () {
      final root = _createFixtureProject(tempDir.path);
      final editor = FileEditor();
      final setup = AndroidSetup(root.path, editor: editor);

      final results = setup.run(['en', 'ur', 'ar']);

      expect(
          results,
          everyElement(
            isA<SetupActionResult>()
                .having((r) => r.exitCode, 'exitCode', SetupExitCode.ok),
          ));

      final xmlPath = p.join(
        root.path,
        'android',
        'app',
        'src',
        'main',
        'res',
        'xml',
        'locales_config.xml',
      );
      expect(File(xmlPath).existsSync(), isTrue);
      expect(File(xmlPath).readAsStringSync(),
          contains('<locale android:name="ur"/>'));

      final manifest = File(
        p.join(
            root.path, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'),
      ).readAsStringSync();
      expect(manifest, contains('android:localeConfig="@xml/locales_config"'));
    });

    test('idempotent: running twice produces no changes on second run', () {
      final root = _createFixtureProject(tempDir.path);
      final editor = FileEditor();
      final setup = AndroidSetup(root.path, editor: editor);

      setup.run(['en', 'ur']);

      final results2 = setup.run(['en', 'ur']);
      for (final r in results2) {
        expect(r.message, contains('already'));
      }
    });

    test(
        'foreign locales_config.xml is not overwritten (exit manualActionNeeded)',
        () {
      final root = _createFixtureProject(tempDir.path);
      final xmlDir = Directory(
        p.join(root.path, 'android', 'app', 'src', 'main', 'res', 'xml'),
      )..createSync(recursive: true);
      File(p.join(xmlDir.path, 'locales_config.xml'))
          .writeAsStringSync('<locale-config><!-- custom --></locale-config>');

      final editor = FileEditor();
      final results = AndroidSetup(root.path, editor: editor).run(['en', 'ur']);

      expect(
        results.any((r) => r.exitCode == SetupExitCode.manualActionNeeded),
        isTrue,
      );
      // Verify file was NOT overwritten.
      expect(
        File(p.join(xmlDir.path, 'locales_config.xml')).readAsStringSync(),
        contains('custom'),
      );
    });
  });

  group('IosSetup', () {
    test('adds CFBundleLocalizations to fresh plist', () {
      final root = _createFixtureProject(tempDir.path);
      final result =
          IosSetup(root.path, editor: FileEditor()).run(['en', 'ur', 'ar']);

      expect(result.exitCode, SetupExitCode.ok);

      final plist = File(
        p.join(root.path, 'ios', 'Runner', 'Info.plist'),
      ).readAsStringSync();
      expect(plist, contains('<string>ur</string>'));
    });

    test('idempotent: does not add duplicates on second run', () {
      final root = _createFixtureProject(tempDir.path);
      final setup = IosSetup(root.path, editor: FileEditor());

      setup.run(['en', 'ur']);
      final result2 = setup.run(['en', 'ur']);

      expect(result2.message, contains('already'));
    });
  });

  group('--dry-run', () {
    test('dry-run writes nothing to disk', () async {
      final root = _createFixtureProject(tempDir.path);
      _addArbFiles(root, 'lib/l10n', {'en': 'en', 'ur': 'ur'});
      _addL10nYaml(root, 'lib/l10n');

      final code = await runSetupCommand([
        '--dry-run',
        '--project',
        root.path,
        '--yes',
      ]);

      expect(code, ExitCodes.ok);

      // The XML file should NOT have been created.
      final xmlPath = p.join(
        root.path,
        'android',
        'app',
        'src',
        'main',
        'res',
        'xml',
        'locales_config.xml',
      );
      expect(File(xmlPath).existsSync(), isFalse);
    });
  });

  group('--check', () {
    test('--check returns 3 when setup is missing', () async {
      final root = _createFixtureProject(tempDir.path);

      final code = await runSetupCommand([
        '--check',
        '--locales',
        'en,ur',
        '--project',
        root.path,
      ]);

      expect(code, ExitCodes.checkFailed);
    });

    test('--check returns 0 when setup is complete', () async {
      final root = _createFixtureProject(tempDir.path);

      // Run actual setup first.
      await runSetupCommand([
        '--locales',
        'en,ur',
        '--project',
        root.path,
        '--yes',
      ]);

      final code = await runSetupCommand([
        '--check',
        '--locales',
        'en,ur',
        '--project',
        root.path,
      ]);

      expect(code, ExitCodes.ok);
    });
  });

  group('invalid tag', () {
    test('invalid locale tag exits with error code', () async {
      final root = _createFixtureProject(tempDir.path);

      final code = await runSetupCommand([
        '--locales',
        'en,123invalid',
        '--project',
        root.path,
      ]);

      expect(code, ExitCodes.error);
    });
  });
}
