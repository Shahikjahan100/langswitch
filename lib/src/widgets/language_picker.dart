import 'package:flutter/material.dart';

import '../langswitch_controller.dart';
import '../language_names.dart';

/// A ready-made language picker widget.
///
/// Shows a "System default" option (when [includeSystemDefault] is true) and
/// each supported locale with its name in that language (endonym). The current
/// selection is highlighted. Selecting an item calls [LangSwitch.instance.setLocale].
///
/// ```dart
/// showLangSwitchSheet(context);
/// // — or embed directly —
/// const LanguagePicker()
/// ```
class LanguagePicker extends StatelessWidget {
  /// Creates a [LanguagePicker].
  const LanguagePicker({
    this.includeSystemDefault = true,
    this.displayNames,
    this.systemDefaultLabel = 'System default',
    this.onChanged,
    super.key,
  });

  /// Whether to show a "System default" option that clears the override.
  final bool includeSystemDefault;

  /// Optional display-name overrides keyed by BCP-47 tag (e.g. `{'ur': 'Urdu'}`).
  final Map<String, String>? displayNames;

  /// Label shown for the "follow device language" option.
  final String systemDefaultLabel;

  /// Called after [LangSwitch.instance.setLocale] when the user selects an item.
  final void Function(Locale? locale)? onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LangSwitch.instance,
      builder: (context, currentLocale, _) {
        final supported = LangSwitch.instance.supportedLocales;
        return ListView(
          shrinkWrap: true,
          children: <Widget>[
            if (includeSystemDefault)
              _PickerTile(
                label: systemDefaultLabel,
                isSelected: currentLocale == null,
                onTap: () => _select(null),
              ),
            for (final locale in supported)
              _PickerTile(
                label: _displayName(locale),
                isSelected: currentLocale != null &&
                    currentLocale.toLanguageTag() == locale.toLanguageTag(),
                onTap: () => _select(locale),
              ),
          ],
        );
      },
    );
  }

  void _select(Locale? locale) {
    LangSwitch.instance.setLocale(locale);
    onChanged?.call(locale);
  }

  String _displayName(Locale locale) {
    final tag = locale.toLanguageTag();
    if (displayNames != null && displayNames!.containsKey(tag)) {
      return displayNames![tag]!;
    }
    return LanguageNames.nameFor(locale) ?? tag;
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(
        label,
        style: isSelected
            ? TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              )
            : null,
      ),
      trailing:
          isSelected ? Icon(Icons.check, color: colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}
