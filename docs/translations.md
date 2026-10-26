# Translations

| Language | Code | UI strings (ARB) | Content (checklists, guides, tips, hotlines) | Status |
|---|---|---|---|---|
| English | `en` | Complete (source) | Complete (source) | Done |
| Tagalog | `fil` | Complete | Complete | **DRAFT: needs native review** |
| Asi (Bantoanon) | `bno` | Untranslated | Untranslated | Waiting for a translator |
| Onhan | `loc` | Untranslated | Untranslated | Waiting for a translator |
| Romblomanon | `rol` | Untranslated | Untranslated | Waiting for a translator |

## Tagalog: needs native review

The Tagalog text was drafted with AI assistance during Phase 3. It has **not** been checked by a native
speaker. Before release, a native Tagalog speaker should review:

- `app/lib/l10n/app_fil.arb`: all 205 UI strings. The file header (`@@x-translation-status`) says it is a draft.
- The `"fil"` entries in `app/assets/data/checklists.json`, `guides.json`, `safety_tips.json`,
  `hotlines.json` and `local_rides.json`.

Things to check in particular: safety wording (it must be clear and calm), terms people actually use
at ports (for example "terminal fee", "check-in"), and the polite form (*kayo/ninyo*), which the draft uses throughout.
When the review is done, change the ARB header and the Settings label: set `TranslationStatus.complete` for `fil` in
`app/lib/l10n/languages.dart`.

## Asi, Onhan and Romblomanon: untranslated

These are left untranslated on purpose: no machine translation, because a wrong translation is worse than
an English fallback.

- `app/lib/l10n/app_bno.arb`, `app_loc.arb`, `app_rol.arb` contain only the locale and a status note.
  Any key missing from a file automatically shows the English text.
- `app/l10n_untranslated.json` is regenerated on every build (`flutter gen-l10n`) and lists every key
  each language still needs. A test checks this list matches the ARB files.
- The language picker shows these languages as "translation in progress".
- Flutter has no built-in date formats or widget strings for these languages, so they use **Filipino**
  formats (see `app/lib/l10n/languages.dart`).

### How a translator adds strings

1. Open `app/lib/l10n/app_en.arb` for the English source. Lines starting with `@` describe placeholders.
2. Copy a key into, for example, `app_bno.arb` and translate the value. Keep `{placeholders}` exactly as
   they are, and keep plural forms such as `{count, plural, =1{...} other{...}}`.
3. Run `cd app && flutter gen-l10n && flutter test`. The tests fail if a key doesn't exist in English.
4. For content (checklists, guides, tips), add a `"bno"` entry next to `"en"` and `"fil"` in the JSON,
   then increase `dataVersion` in `meta.json`.
5. When a language is complete and reviewed, update its status in `app/lib/l10n/languages.dart`
   and in this table.

Native-speaker translators are best found through local schools, the provincial government, or community
groups on each island (Banton for Asi, Tablas for Onhan, Romblon and Sibuyan for Romblomanon).
