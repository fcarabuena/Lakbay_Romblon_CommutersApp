# Lakbay Romblon

An inter-island travel companion for people from Romblon province, especially
first-time travellers. It plans a door-to-door trip between any of Romblon's 17
municipalities and Metro Manila, and back home: a local ride to the pier, the
ship (with intermediate stops), Batangas or Lucena port, the bus to Manila, and
the last leg. Every step shows a fare and a time estimate.

Package id: `app.lakbayromblon` · Android first · Flutter

> **Data status:** all bundled operators, fares, schedules and travel times are
> **PLACEHOLDER sample data** (for example "Sample Shipping Line A"). The app labels
> every such value "Sample, not verified" and shows a banner on every tab. Real
> operators will be added only after fares are verified and permission is obtained.

## Build status by phase

| Phase | Scope | Status |
|---|---|---|
| 1 | Folder structure, data model, screen list | Done ([docs/phase-1-proposal.md](docs/phase-1-proposal.md)) |
| 2 | Trip planner, budget planner, First-Timer Mode (offline seed data) | Done |
| 3 | Maps, pier guides, emergency info, languages | Done ([plan](docs/phase-3-plan.md)) |
| 4 | Firebase, admin panel, community reports, advisories, push alerts, photos | **Built, awaiting approval** ([plan](docs/phase-4-plan.md)) |
| 5 | Share My Trip, AR pier guide | Not started |

## Repository layout

```
pubspec.yaml            Dart pub workspace root (members: packages/core, packages/ui, app, admin)
packages/core/          Pure Dart: models, route planner, fare/time/budget calculators,
                        First-Timer checklist builder, data validator (+ unit tests)
packages/ui/            Flutter: the shared "Tide" theme (LakbayTheme, AdvisoryColors) and the
                        bundled Figtree font (SIL OFL, fonts/OFL.txt) used by the app and admin
app/                    Flutter Android app
  assets/data/          Seed JSON (PLACEHOLDER values)
  lib/app/              MaterialApp, theme, router (go_router)
  lib/core/             sqflite database, repositories, providers, shared widgets
  lib/features/         planner, ships, buses, first_timer, budget, trips, guides, safety,
                        settings, onboarding
  lib/l10n/             ARB files (en, fil draft, bno/loc/rol untranslated) + language setup
  test/                 Seed, database and widget tests
admin/                  Flutter web admin panel (editors, advisories, photos, reports,
                        change log, users); assets/seed is a copy of app/assets/data
firebase/               firestore.rules, storage.rules, indexes, functions/ (push alerts),
                        rules-test/ (security rule tests on the emulators)
firebase.json           Firebase CLI config (rules, functions, admin hosting, emulators)
docs/                   Proposals, privacy policy draft, translations, hotlines to verify,
                        pier layout format, Firebase setup, admin guide
```

Architecture: each feature has `application/` (Riverpod state) and
`presentation/` (screens). Domain models and all calculation logic live in
`packages/core`, so the web admin panel (Phase 4) can reuse them. The app
reads only from the local SQLite database, so it works fully offline.

## Setup

Requirements: Flutter stable (3.47 or later, Dart 3.13), JDK 17, Android SDK 36.

```sh
flutter pub get                    # run at the repo root; resolves the whole workspace
flutter analyze                    # analyzes app and core
cd packages/core && dart test      # core unit tests
cd app && flutter test             # app tests (seed, database, widgets)
cd app && flutter run              # run on a connected device or emulator
```

The Android SDK path must not contain spaces (the NDK breaks). On the main dev
machine the heavy build storage lives on drive D: (user environment variables):
`ANDROID_HOME`/`ANDROID_SDK_ROOT=D:\Android\Sdk`, `GRADLE_USER_HOME=D:\.gradle`,
`PUB_CACHE=D:\pub-cache`. A first Android build downloads the NDK (~3 GB), so
keep at least 6 GB free on the drive that holds the SDK.

## How the data works

1. Seed files in `app/assets/data/*.json` ship with the app.
2. On first launch (or when an app update ships a higher `dataVersion` in
   `meta.json`), the seed is parsed, validated and imported into SQLite in one
   transaction. A broken seed never replaces working data. Saved trips and
   checklist progress are kept.
3. Screens read from SQLite. When Firebase is set up, the app syncs changed
   documents from Firestore into the same tables (on launch and on return to
   the app, at most every 15 minutes). Each synced document is validated first;
   one that is malformed or would break the data is skipped.

### Updating the data

1. Edit the JSON in `app/assets/data/`. Money is in **pesos** (`farePhp`) and
   times are `"HH:mm"` local time. `dayOffset` counts days after the voyage's first departure.
2. When a value has been checked with the operator, update its verification block:
   ```json
   "verification": {"source": "Operator ticket office, 12 Sep 2026", "isPlaceholder": false, "lastVerified": "2026-09-12"}
   ```
   The validator rejects any value that is marked verified but has no date.
   Values older than 90 days show "may be outdated".
3. Increase `dataVersion` in `meta.json`. Set `isPlaceholderData` to `false`
   only when no placeholder values remain.
4. Run `cd app && flutter test`. `seed_data_test.dart` checks references, that
   all 17 towns are present, and that every town has a route to and from every
   Manila hub. One test asserts that everything is still a placeholder; update
   it deliberately when real data arrives.

Other data files:

- `guides.json`: pier and terminal guides. Layouts are illustrative placeholders; see
  [docs/guide-layout-format.md](docs/guide-layout-format.md) for how to replace them with a drawing or an image.
- `hotlines.json`: emergency numbers. **All entries must be verified before release**; only 911 has a
  number so far. Work through [docs/hotlines-to-verify.md](docs/hotlines-to-verify.md).
- `safety_tips.json`: scam warnings and safety tips.

All text in the data can carry `"en"`, `"fil"`, `"bno"`, `"loc"` and `"rol"` versions; see
[docs/translations.md](docs/translations.md). The Tagalog is a draft that **needs native review**.

Ship fares are listed per voyage segment (`fromPortId` → `toPortId`, by class),
so a stop in the middle of a voyage has its own fare.

## Firebase and the admin panel

Follow [docs/firebase-setup.md](docs/firebase-setup.md) (project, Blaze plan with a budget
alert, Firestore in `asia-southeast1`, sign-in methods, `flutterfire configure`, deploying
the rules, function and admin panel, and adding the first admin). Editors' instructions are
in [docs/admin-guide.md](docs/admin-guide.md).

Without that setup the app still builds and runs offline: `lib/firebase_options.dart` is a
placeholder until `flutterfire configure` replaces it.

Checks for the backend:

```sh
cd admin && flutter test                  # admin panel
cd firebase/functions && npm test         # push-alert logic
# security rules: see "Testing the security rules locally" in docs/firebase-setup.md
```

After changing `app/assets/data`, refresh the admin panel's starter copy with
`cd admin && dart run tool/copy_seed.dart` (a test fails if you forget).

## Play Store release

1. **Signing key** (once; keep it backed up and never commit it):
   ```sh
   keytool -genkey -v -keystore %USERPROFILE%\lakbay-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Create `app/android/key.properties` (git-ignored):
   ```properties
   storeFile=C:/Users/<you>/lakbay-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```
   `app/android/app/build.gradle.kts` uses this file automatically. Without it,
   release builds are signed with debug keys, which the Play Store rejects.
   Enrol in **Play App Signing** so Google holds the app signing key and yours is the upload key.
2. **Version:** bump `version:` in `app/pubspec.yaml` (`1.0.0+1`; the number
   after `+` must increase with every upload).
3. **App bundle:** `cd app && flutter build appbundle --release`. Upload
   `build/app/outputs/bundle/release/app-release.aab`.
4. **Privacy policy:** finalize [docs/privacy-policy.md](docs/privacy-policy.md),
   host it at a public URL, and enter that URL in Play Console → App content.
5. **Data safety form:** answer from the privacy policy. Current Phase 3 build:
   - Location (approximate and precise): accessed only when the user taps "Use my location",
     processed **on device only**, not collected or shared. Declare it as not collected
     (on-device processing), or follow Play's current guidance for on-device location.
   - **App activity → Other user-generated content** (community reports): collected, not
     shared, optional, used for app functionality; not linked to identity (anonymous ID only).
   - **Device or other IDs**: the Firebase anonymous user ID (reports) and the Cloud Messaging
     token (only if alerts are turned on); used for app functionality.
   - Data is encrypted in transit (HTTPS). Users can ask for deletion via the contact email.
   - Map tiles are fetched from OpenStreetMap; travel data and photos from Firebase.
   - Phase 5 adds trip details shared by the user.
   - Permissions to explain in the listing: Internet (maps, updates), Location (optional,
     foreground) and Notifications (optional, advisory alerts).
6. **Content rating:** complete the IARC questionnaire (travel utility, no
   violence, gambling or user-to-user chat; user reports are private and reviewed by staff).
7. **Target audience:** 18+ or general audience; not designed for children.
8. **Store listing:** short and full description, icon (512×512), feature
   graphic (1024×500), at least 2 phone screenshots. State clearly that
   fares and schedules are estimates.
9. **Notification icon:** make a proper monochrome small icon for advisory alerts
   (white on transparent, e.g. `app/android/app/src/main/res/drawable*/ic_notification.png`)
   and set it as `com.google.firebase.messaging.default_notification_icon` in the
   Android manifest. Until then alerts use the app icon, which Android shows as a blank shape.
10. **App Check:** turn on App Check with Play Integrity for the Android app and enforce it
    for Firestore and Storage (see docs/firebase-setup.md, "Before a public release").
    Without it, anonymous report spam is easier.
11. Release to **internal testing** first, then closed testing, then production.
   New personal developer accounts must run a closed test with testers for a
   period before production access; check the current Play Console requirement.
