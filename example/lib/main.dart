import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:langswitch/langswitch.dart';

import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LangSwitch.init(
    supportedLocales: AppLocalizations.supportedLocales,
  );
  runApp(const LangSwitchDemoApp());
}

class LangSwitchDemoApp extends StatelessWidget {
  const LangSwitchDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LangSwitchBuilder(
      builder: (context, locale, supportedLocales) => MaterialApp(
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        title: 'LangSwitch Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ls = LangSwitch.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.greeting,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<Locale?>(
            valueListenable: ls,
            builder: (context, _, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentLanguage(
                    LanguageNames.nameFor(ls.resolvedLocale) ??
                        ls.resolvedLocale.toLanguageTag(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.itemCount(3)),
                const SizedBox(height: 8),
                Text(l10n.todayDate(DateTime.now())),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => showLangSwitchSheet(context),
            icon: const Icon(Icons.language),
            label: Text(l10n.pickLanguage),
          ),
          const SizedBox(height: 12),
          FutureBuilder<bool>(
            future: ls.isSystemSettingSupported,
            builder: (context, snap) {
              if (snap.data != true) return const SizedBox.shrink();
              return OutlinedButton.icon(
                onPressed: ls.openSystemLanguageSettings,
                icon: const Icon(Icons.settings),
                label: Text(l10n.openSystemSettings),
              );
            },
          ),
          const SizedBox(height: 32),
          _DebugPanel(l10n: l10n),
        ],
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ls = LangSwitch.instance;
    return ValueListenableBuilder<Locale?>(
      valueListenable: ls,
      builder: (context, _, __) => Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.debugPanel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              _DebugRow(
                label: l10n.debugValue,
                value: ls.value?.toLanguageTag() ?? 'null',
              ),
              _DebugRow(
                label: l10n.debugResolved,
                value: ls.resolvedLocale.toLanguageTag(),
              ),
              _DebugRow(
                label: l10n.debugHasOverride,
                value: ls.hasOverride.toString(),
              ),
              FutureBuilder<bool>(
                future: ls.isSystemSettingSupported,
                builder: (context, snap) => _DebugRow(
                  label: l10n.debugPlatformSupport,
                  value: snap.data?.toString() ?? '...',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
