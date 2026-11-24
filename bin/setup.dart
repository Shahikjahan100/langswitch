import 'dart:io';

import 'package:langswitch/src/cli/setup_command.dart';

Future<void> main(List<String> args) async {
  final exitCode = await runSetupCommand(args);
  exit(exitCode);
}
