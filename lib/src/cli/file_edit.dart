// ignore_for_file: avoid_print
import 'dart:io';

/// Result of a file operation.
class FileEditResult {
  /// Creates a [FileEditResult].
  const FileEditResult({
    required this.path,
    required this.changed,
    required this.diff,
  });

  /// Absolute path to the file that was (or would be) written.
  final String path;

  /// Whether the content changed from what was on disk.
  final bool changed;

  /// A human-readable description of the change (may be empty when unchanged).
  final String diff;
}

/// Idempotent, dry-run–capable file helper.
///
/// All write operations are preceded by an in-memory diff. When [dryRun] is
/// `true`, no bytes are written to disk.
class FileEditor {
  /// Creates a [FileEditor].
  ///
  /// Pass [dryRun] to preview changes without writing, or [verbose] to print
  /// each diff to stdout.
  FileEditor({this.dryRun = false, this.verbose = false});

  /// When `true`, diffs are computed and printed but no files are written.
  final bool dryRun;

  /// When `true`, each diff is printed to stdout.
  final bool verbose;

  /// Writes [newContent] to [path].
  ///
  /// Returns immediately without writing when the file already has exactly
  /// [newContent] (idempotent). Creates parent directories as needed.
  FileEditResult write(String path, String newContent) {
    final file = File(path);
    final oldContent = file.existsSync() ? file.readAsStringSync() : '';

    if (oldContent == newContent) {
      return FileEditResult(path: path, changed: false, diff: '');
    }

    final diff = _buildDiff(path, oldContent, newContent);

    if (verbose) {
      print(diff);
    }

    if (!dryRun) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(newContent);
    }

    return FileEditResult(path: path, changed: true, diff: diff);
  }

  /// Applies [transform] to the current content of [path] and writes the result.
  ///
  /// [create] controls whether the file is created when it does not exist.
  /// When [create] is `false` and the file is missing, returns unchanged.
  FileEditResult transform(
    String path,
    String Function(String current) transform, {
    bool create = false,
  }) {
    final file = File(path);
    if (!file.existsSync()) {
      if (!create) {
        return FileEditResult(path: path, changed: false, diff: '');
      }
      return write(path, transform(''));
    }
    return write(path, transform(file.readAsStringSync()));
  }

  /// Returns the current content of [path], or an empty string if it does not exist.
  String read(String path) {
    final file = File(path);
    return file.existsSync() ? file.readAsStringSync() : '';
  }

  String _buildDiff(String path, String before, String after) {
    final beforeLines = before.split('\n');
    final afterLines = after.split('\n');
    final buf = StringBuffer();
    buf.writeln('--- a/$path');
    buf.writeln('+++ b/$path');

    final maxLen = beforeLines.length > afterLines.length
        ? beforeLines.length
        : afterLines.length;
    for (var i = 0; i < maxLen; i++) {
      final b = i < beforeLines.length ? beforeLines[i] : null;
      final a = i < afterLines.length ? afterLines[i] : null;
      if (b == a) {
        buf.writeln('  ${b ?? ''}');
      } else {
        if (b != null) buf.writeln('- $b');
        if (a != null) buf.writeln('+ $a');
      }
    }
    return buf.toString();
  }
}
