# Lakbay Romblon: Phase 3 Plan

Status: **approved and built** (2026-10-26). Decisions: 5 tabs; all hotlines "verify before release" (see `hotlines-to-verify.md`); Tagalog drafted, needs native review; illustrative layouts replaceable via data or image. Scope: maps, pier and terminal guides, emergency and safety info, languages.

## 1. Navigation change

There will be 5 bottom tabs: **Plan · Schedules · Guide · Safety · More**.
"My trips" moves to a button on the Plan screen and an entry under More, because 6 tabs would be too many on small phones.

## 2. Maps and pier guides

- **Guide tab:** a list of piers and bus terminals, sorted by distance when location is on. Each one opens a guide page.
- **Guide page** (`/guide/:placeId`) has two views:
  - **Layout (works offline):** a simple drawn plan of the pier, made from JSON with areas such as the entrance, ticket office, waiting area, restrooms, boarding gate and bus area. Below it is a text list of the same points for screen readers. Each layout is labelled *"Illustrative layout, not to scale. Verify on site."*, because I have no surveyed layouts, so these are placeholders.
  - **Map (needs internet):** live OpenStreetMap tiles via `flutter_map`, with markers for the pier and its points of interest, plus a "my location" button. It shows the required OpenStreetMap attribution and sends `app.lakbayromblon` as the User-Agent, as the tile policy requires. Only tiles you have viewed are cached; nothing is bulk-downloaded. If tiles fail to load, a notice points you to the Layout view.
  - **Tips:** localized text such as where to buy tickets, terminal fee payment and what to watch out for.
  - **Photos:** supported in the data, but none ship in this phase. I won't use made-up photos. The page says "No photos yet" until real ones are added through the admin panel in Phase 4.
- **Location:** uses `geolocator`, in the foreground only, and only after the user taps "Use my location". Without permission, everything still works. "Nearest pier" is calculated on the phone, and location never leaves the device.
- **Android setup:** the `INTERNET` permission in the main manifest (the template only adds it to debug builds, which would break map tiles in release), `ACCESS_COARSE_LOCATION`/`ACCESS_FINE_LOCATION`, and a `tel:` intent declaration for the call buttons.

## 3. Emergency and safety (Safety tab, all offline)

- **Hotlines:** tap to call using `url_launcher` with `tel:`, which opens the phone's dialer and needs no permission. Grouped as national (911, Coast Guard, PNP), province, and per port (port help desks).
  - Every number carries a verification block like fares do, and **all are marked "verify before release"**. I can't confirm phone numbers, and a wrong emergency number is dangerous.
  - Entries for town-level numbers (MDRRMO, police stations) exist but are empty and say "Number needed" until real numbers are added.
- **Scam warnings and safety tips:** short cards, for example fake ticket sellers outside terminals, "fixers", overpriced special trips, keeping valuables close, staying calm when a trip is cancelled, and life jackets. This is general advice I'll write, not data.
- **SOS card:** "Show this to staff" with the traveller's own planned trip summary.

## 4. Languages

| Language | Code | Content |
|---|---|---|
| English | `en` | Full (source) |
| Tagalog | `fil` | Full UI and content, **drafted by me, needs review by a native speaker** |
| Asi (Bantoanon) | `bno` | Untranslated |
| Onhan | `loc` | Untranslated |
| Romblomanon | `rol` | Untranslated |

- **How untranslated strings are marked:** the `bno`, `loc` and `rol` ARB files contain only the translated keys, so missing keys fall back to English automatically. Flutter writes a list of untranslated keys per language to `app/l10n_untranslated.json`, and a test checks the count. Each file also has a header note saying it's waiting for a translator. I won't machine-translate these languages.
- **Language picker** in More → Settings, showing for example "Asi (translation in progress)". The choice is saved on the phone. The default follows the phone's language.
- **Local-language technical detail:** Flutter's built-in widgets (date pickers, buttons) and the `intl` date formatting have no Asi, Onhan or Romblomanon data. Without a fix, the app would crash in those languages. I'll add fallback handlers that use Filipino formats for those three languages.
- **Text size setting:** Normal, Large or Extra large, applied on top of the phone's own font size.

## 5. Data and core changes

- New seed files: `guides.json` (tips, layout, points of interest, photo list), `hotlines.json`, `safety_tips.json`. `dataVersion` goes up to 2, which re-imports the data on update while keeping saved trips and checklist progress.
- `packages/core`:
  - New models: `Guide`, `GuideLayout`, `PointOfInterest`, `Hotline`, `SafetyTip`.
  - Distance and nearest-place helpers.
  - The data checker covers the new files.
- Tagalog (`fil`) text is added to the checklist, guide and tip content.

## 6. Tests

- **Core:** distance and nearest-place calculations, parsing of the new files, and the new data-checker rules.
- **App:**
  - Every key in the Tagalog file exists in English, and the local-language files contain only valid keys.
  - The app opens without crashing in all 5 languages.
  - Switching the language changes the UI.
  - Guide page: the layout and its points appear, and the map view doesn't load real tiles during tests.
  - Safety tab: tapping a hotline calls the dialer, using a fake dialer in tests.
  - The text size setting.
- **End of phase:** `flutter analyze` clean, all tests passing, and a debug APK build.

## 7. Docs

The privacy policy's location section goes from planned to live. I'll also update the README (new data files and how to add translations) and the notes for the Play Store data safety form.

## 8. Not in Phase 3

These are deferred to later phases:
- Advisories and banners (Phase 4)
- Real photos (added through the admin panel in Phase 4)
- The AR guide button (Phase 5)
