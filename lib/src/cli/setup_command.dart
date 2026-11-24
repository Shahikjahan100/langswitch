// ignore_for_file: avoid_print
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'android_setup.dart';
import 'file_edit.dart';
import 'ios_setup.dart';
import 'locale_discovery.dart';

/// Exit codes for the setup CLI.
class ExitCodes {
  ExitCodes._();

  /// Setup succeeded or was already up to date.
  static const int ok = 0;

  /// An error prevented setup from completing.
  static const int error = 1;

  /// A file conflict requires manual intervention.
  static const int manualActionNeeded = 2;

  /// Setup is missing or outdated (returned only by `--check`).
  static const int checkFailed = 3;
}

/// Runs the `langswitch:setup` command.
///
/// Returns the process exit code (see [ExitCodes]).
Future<int> runSetupCommand(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'locales',
      abbr: 'l',
      help: 'Comma-separated BCP-47 locale tags (e.g. en,ur,ar,es,pt-BR).',
    )
    ..addOption(
      'project',
      abbr: 'p',
      help: 'Path to the Flutter project root.',
      defaultsTo: '.',
    )
    ..addFlag(
      'android-only',
      negatable: false,
      help: 'Only run Android setup.',
    )
    ..addFlag(
      'ios-only',
      negatable: false,
      help: 'Only run iOS setup.',
    )
    ..addFlag(
      'dry-run',
      negatable: false,
      help: 'Print what would change; write nothing.',
    )
    ..addFlag(
      'check',
      negatable: false,
      help: 'Exit with code 3 if setup is missing or outdated.',
    )
    ..addFlag(
      'yes',
      abbr: 'y',
      negatable: false,
      help: "Don't prompt for confirmation.",
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this help message.',
    );

  ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    _error('${e.message}\n\nUsage:\n${parser.usage}');
    return ExitCodes.error;
  }

  if (results['help'] as bool) {
    _printUsage(parser);
    return ExitCodes.ok;
  }

  final projectRoot = p.absolute(results['project'] as String);
  final dryRun = results['dry-run'] as bool;
  final check = results['check'] as bool;
  final androidOnly = results['android-only'] as bool;
  final iosOnly = results['ios-only'] as bool;

  if (dryRun) _info('Dry run — no files will be written.');

  // Warn if not under git.
  if (!Directory(p.join(projectRoot, '.git')).existsSync()) {
    _warn(
      'The project does not appear to be under git. '
      'Manual backup recommended before running setup.',
    );
  }

  // Discover locales.
  List<String> locales;
  final rawLocales = results['locales'] as String?;
  if (rawLocales != null) {
    try {
      locales = LocaleDiscovery.fromFlag(rawLocales);
    } on ArgumentError catch (e) {
      _error('Invalid locale: ${e.message}');
      return ExitCodes.error;
    }
  } else {
    final discovered = LocaleDiscovery.fromProject(projectRoot);
    if (discovered == null || discovered.isEmpty) {
      _error(
        'Could not auto-detect locales. '
        'Pass them with --locales, e.g. --locales en,ur,ar,es',
      );
      return ExitCodes.error;
    }
    locales = discovered;
    _info('Auto-detected locales: ${locales.join(', ')}');
  }

  final editor = FileEditor(dryRun: dryRun || check, verbose: dryRun);
  var overallCode = ExitCodes.ok;
  var setupMissing = false;

  if (!iosOnly) {
    final androidSetup = AndroidSetup(projectRoot, editor: editor);
    for (final result in androidSetup.run(locales)) {
      _printResult(result);
      if (result.exitCode == SetupExitCode.error) {
        return ExitCodes.error;
      }
      if (result.exitCode == SetupExitCode.manualActionNeeded) {
        overallCode = ExitCodes.manualActionNeeded;
      }
      if (result.didChange(isDryRun: dryRun)) setupMissing = true;
    }
  }

  if (!androidOnly) {
    final iosSetup = IosSetup(projectRoot, editor: editor);
    final result = iosSetup.run(locales);
    _printResult(result);
    if (result.exitCode == SetupExitCode.error) {
      return ExitCodes.error;
    }
    if (result.exitCode == SetupExitCode.manualActionNeeded) {
      overallCode = ExitCodes.manualActionNeeded;
    }
    if (result.didChange(isDryRun: dryRun)) setupMissing = true;
  }

  if (check && setupMissing) {
    _warn('Setup is missing or outdated (--check failed).');
    return ExitCodes.checkFailed;
  }

  if (overallCode == ExitCodes.ok && !check) {
    _success(
      'Next: wrap MaterialApp with LangSwitchBuilder (see README).',
    );
  }

  return overallCode;
}

void _printUsage(ArgParser parser) {
  print('''
dart run langswitch:setup [options]

Configures your Flutter app to appear in the OS per-app language screen.

Options:
${parser.usage}

Example:
  dart run langswitch:setup --locales en,ur,ar,es
''');
}

void _printResult(SetupActionResult result) {
  switch (result.exitCode) {
    case SetupExitCode.ok:
      _success(result.message);
    case SetupExitCode.error:
      _error(result.message);
    case SetupExitCode.manualActionNeeded:
      _warn(result.message);
  }
}

bool _useAnsi() {
  return stdout.hasTerminal && Platform.environment['TERM'] != 'dumb';
}

void _success(String message) {
  if (_useAnsi()) {
    print('\x1B[32m✔\x1B[0m $message');
  } else {
    print('✔ $message');
  }
}

void _warn(String message) {
  if (_useAnsi()) {
    print('\x1B[33m⚠\x1B[0m $message');
  } else {
    print('⚠ $message');
  }
}

void _error(String message) {
  if (_useAnsi()) {
    stderr.writeln('\x1B[31m✖\x1B[0m $message');
  } else {
    stderr.writeln('✖ $message');
  }
}

void _info(String message) {
  print('  $message');
}
