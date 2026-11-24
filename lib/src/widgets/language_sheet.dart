import 'package:flutter/material.dart';

import 'language_picker.dart';

/// Shows [LanguagePicker] in a modal bottom sheet (or a dialog on wide screens).
///
/// Wide screens are defined as `MediaQuery` width ≥ 600 dp.
///
/// ```dart
/// ElevatedButton(
///   onPressed: () => showLangSwitchSheet(context),
///   child: const Text('Language'),
/// );
/// ```
Future<void> showLangSwitchSheet(
  BuildContext context, {
  String? title,
  Map<String, String>? displayNames,
}) async {
  final isWide = MediaQuery.of(context).size.width >= 600;

  if (isWide) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title ?? 'Language'),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: 360,
          child: LanguagePicker(displayNames: displayNames),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (title != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const Divider(),
            ] else
              const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: LanguagePicker(displayNames: displayNames),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
