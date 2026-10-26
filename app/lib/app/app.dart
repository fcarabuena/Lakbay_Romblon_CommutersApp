import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/languages.dart';
import 'background_tasks.dart';
import 'router.dart';
import 'theme.dart';

class LakbayApp extends ConsumerWidget {
  const LakbayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: LakbayTheme.light(),
      themeMode: ThemeMode.light,
      locale: settings.languageCode == null
          ? null
          : Locale(settings.languageCode!),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: combinedTextScaler(
              media.textScaler,
              settings.textScale,
            ),
          ),
          child: BackgroundTasks(child: child!),
        );
      },
    );
  }
}
