// ignore_for_file: avoid_print
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'android_setup.dart' show SetupActionResult, SetupExitCode;
import 'file_edit.dart';

/// Performs the iOS per-app language setup on a Flutter project.
class IosSetup {
  /// Creates an [IosSetup] for the project at [projectRoot].
  IosSetup(this.projectRoot, {required this.editor});

  /// Absolute path to the Flutter project root.
  final String projectRoot;

  /// File editor (may be a dry-run editor).
  final FileEditor editor;

  /// Adds or merges [locales] into `CFBundleLocalizations` in Info.plist.
  SetupActionResult run(List<String> locales) {
    return _setupInfoPlist(locales);
  }

  SetupActionResult _setupInfoPlist(List<String> locales) {
    final plistPath = p.join(projectRoot, 'ios', 'Runner', 'Info.plist');

    final file = File(plistPath);
    if (!file.existsSync()) {
      return const SetupActionResult(
        exitCode: SetupExitCode.error,
        message: 'Could not find ios/Runner/Info.plist. '
            'Run from the Flutter project root.',
      );
    }

    final content = file.readAsStringSync();
    XmlDocument doc;
    try {
      doc = XmlDocument.parse(content);
    } on XmlParserException catch (e) {
      return SetupActionResult(
        exitCode: SetupExitCode.error,
        message: 'Failed to parse Info.plist: $e',
      );
    }

    // The plist root is <plist><dict>…</dict></plist>.
    final dictElements = doc.findAllElements('dict').toList();
    if (dictElements.isEmpty) {
      return const SetupActionResult(
        exitCode: SetupExitCode.error,
        message: 'No <dict> element found in Info.plist.',
      );
    }
    final rootDict = dictElements.first;

    // Find existing CFBundleLocalizations key.
    XmlElement? arrayNode;
    final children = rootDict.children.whereType<XmlElement>().toList();
    for (var i = 0; i < children.length - 1; i++) {
      final child = children[i];
      if (child.name.local == 'key' &&
          child.innerText == 'CFBundleLocalizations') {
        final next = children[i + 1];
        if (next.name.local == 'array') {
          arrayNode = next;
        }
        break;
      }
    }

    final existingTags = <String>{};
    if (arrayNode != null) {
      for (final child in arrayNode.children.whereType<XmlElement>()) {
        if (child.name.local == 'string') {
          existingTags.add(child.innerText);
        }
      }
    }

    final toAdd = locales.where((tag) => !existingTags.contains(tag)).toList();
    if (toAdd.isEmpty) {
      return const SetupActionResult(
        exitCode: SetupExitCode.ok,
        message: 'iOS: Info.plist CFBundleLocalizations already up to date.',
      );
    }

    if (arrayNode == null) {
      // Create the key+array pair.
      final keyNode = XmlElement(
          XmlName.parts('key'), [], [XmlText('CFBundleLocalizations')]);
      final newArray = _buildArray([...locales]);
      rootDict.children.add(XmlText('\n\t'));
      rootDict.children.add(keyNode);
      rootDict.children.add(XmlText('\n\t'));
      rootDict.children.add(newArray);
    } else {
      for (final tag in toAdd) {
        arrayNode.children.add(XmlText('\n\t\t'));
        arrayNode.children.add(
          XmlElement(XmlName.parts('string'), [], [XmlText(tag)]),
        );
      }
    }

    final newContent = doc.toXmlString(pretty: false);
    final result = editor.write(plistPath, newContent);
    if (!result.changed) {
      return const SetupActionResult(
        exitCode: SetupExitCode.ok,
        message: 'iOS: Info.plist already up to date.',
      );
    }

    final totalCount = existingTags.length + toAdd.length;
    return SetupActionResult(
      exitCode: SetupExitCode.ok,
      message: 'iOS: ${editor.dryRun ? 'would update' : 'updated'} Info.plist '
          'CFBundleLocalizations ($totalCount locales).',
    );
  }

  XmlElement _buildArray(List<String> locales) {
    final children = <XmlNode>[];
    for (final tag in locales) {
      children
        ..add(XmlText('\n\t\t'))
        ..add(XmlElement(XmlName.parts('string'), [], [XmlText(tag)]));
    }
    children.add(XmlText('\n\t'));
    return XmlElement(XmlName.parts('array'), [], children);
  }
}
