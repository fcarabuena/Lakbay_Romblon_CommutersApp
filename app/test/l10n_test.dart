import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbayromblon/core/data/user_repositories.dart';
import 'package:lakbayromblon/l10n/languages.dart';

import 'helpers.dart';

Map<String, Object?> _arb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, Object?>;

Iterable<String> _messageKeys(Map<String, Object?> arb) =>
    arb.keys.where((k) => !k.startsWith('@'));

/// Simple placeholder names in a message: "{from} → {to}" gives {from, to}.
Set<String> _placeholders(String message) =>
    RegExp(r'\{(\w+)[,}]').allMatches(message).map((m) => m.group(1)!).toSet();

void main() {
  final en = _arb('en');
  final enKeys = _messageKeys(en).toSet();

  group('ARB files', () {
    test('every listed language has an ARB file', () {
      for (final lang in appLanguages) {
        expect(
          File('lib/l10n/app_${lang.code}.arb').existsSync(),
          isTrue,
          reason: lang.code,
        );
      }
    });

    test('Tagalog translates every key with the same placeholders', () {
      final fil = _arb('fil');
      expect(_messageKeys(fil).toSet(), enKeys);
      for (final key in enKeys) {
        expect(
          _placeholders(fil[key]! as String),
          _placeholders(en[key]! as String),
          reason: 'placeholders differ in "$key"',
        );
      }
      expect(
        fil['@@x-translation-status'],
        contains('needs review by a native speaker'),
      );
    });

    test(
      'local-language files are marked untranslated and use only real keys',
      () {
        for (final code in localLanguageCodes) {
          final arb = _arb(code);
          expect(
            arb['@@x-translation-status'],
            startsWith('UNTRANSLATED'),
            reason: code,
          );
          expect(
            enKeys.containsAll(_messageKeys(arb)),
            isTrue,
            reason: '$code has unknown keys',
          );
        }
      },
    );

    test(
      'the untranslated report lists what each local language still needs',
      () {
        final report = jsonDecode(
          File('l10n_untranslated.json').readAsStringSync(),
        ) as Map<String, Object?>;
        for (final code in localLanguageCodes) {
          final missing = (report[code]! as List<Object?>)
              .cast<String>()
              .toSet();
          expect(
            missing,
            enKeys.difference(_messageKeys(_arb(code)).toSet()),
            reason: code,
          );
        }
        expect(
          report.containsKey('fil'),
          isFalse,
          reason: 'Tagalog should be complete',
        );
      },
    );
  });

  group('app in every language', () {
    for (final lang in appLanguages) {
      testWidgets('opens without errors in ${lang.name}', (tester) async {
        // More shows a formatted date, which needs intl data for the locale.
        await pumpApp(
          tester,
          location: '/more',
          settings: AppSettings(languageCode: lang.code),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(NavigationBar), findsOneWidget);
      });
    }

    testWidgets('Tagalog shows Tagalog text', (tester) async {
      await pumpApp(tester, settings: const AppSettings(languageCode: 'fil'));
      expect(find.text('Magplano ng biyahe'), findsOneWidget);
      expect(find.text('Gabay'), findsOneWidget);
    });

    testWidgets('an untranslated local language falls back to English', (
      tester,
    ) async {
      await pumpApp(tester, settings: const AppSettings(languageCode: 'bno'));
      expect(find.text('Plan a trip'), findsOneWidget);
      expect(find.text('Safety'), findsOneWidget);
    });
  });
}
