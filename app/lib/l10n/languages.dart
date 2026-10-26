import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'generated/app_localizations.dart';

enum TranslationStatus { complete, draft, untranslated }

class AppLanguage {
  const AppLanguage(this.code, this.name, this.status);

  final String code;

  /// The language's own name, shown untranslated in the picker.
  final String name;
  final TranslationStatus status;
}

/// Every language the app offers. Keep in sync with the ARB files and
/// `docs/translations.md`.
const appLanguages = [
  AppLanguage('en', 'English', TranslationStatus.complete),
  AppLanguage('fil', 'Tagalog', TranslationStatus.draft),
  AppLanguage('bno', 'Asi', TranslationStatus.untranslated),
  AppLanguage('loc', 'Onhan', TranslationStatus.untranslated),
  AppLanguage('rol', 'Romblomanon', TranslationStatus.untranslated),
];

/// Romblon languages that Flutter and `intl` have no built-in data for.
const localLanguageCodes = {'bno', 'loc', 'rol'};

/// The locale to use for dates and numbers. The local languages use
/// Filipino formats, which `intl` supports.
String intlLocaleFor(String localeName) =>
    localLanguageCodes.contains(localeName) ? 'fil' : localeName;

/// All delegates for [MaterialApp]. Without the fallbacks, Flutter throws
/// "No MaterialLocalizations found" for Asi, Onhan and Romblomanon.
const appLocalizationsDelegates = <LocalizationsDelegate<Object>>[
  AppLocalizations.delegate,
  _FilipinoFallback<MaterialLocalizations>(
    GlobalMaterialLocalizations.delegate,
  ),
  _FilipinoFallback<CupertinoLocalizations>(
    GlobalCupertinoLocalizations.delegate,
  ),
  _FilipinoFallback<WidgetsLocalizations>(GlobalWidgetsLocalizations.delegate),
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

/// Serves the Filipino version of Flutter's own strings (date pickers,
/// tooltips) for the local languages. App text comes from the ARB files.
class _FilipinoFallback<T> extends LocalizationsDelegate<T> {
  const _FilipinoFallback(this.inner);

  final LocalizationsDelegate<T> inner;

  @override
  bool isSupported(Locale locale) =>
      localLanguageCodes.contains(locale.languageCode);

  @override
  Future<T> load(Locale locale) => inner.load(const Locale('fil'));

  @override
  bool shouldReload(covariant LocalizationsDelegate<T> old) => false;

  @override
  Type get type => T;
}
