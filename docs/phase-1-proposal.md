# Lakbay Romblon: Phase 1 Proposal

Status: **awaiting approval**. No app code has been written yet.
Package id: `app.lakbayromblon` · Platform: Android first (Flutter web for the admin panel)

---

## 1. Key technical decisions

| Area | Proposal | Why |
|---|---|---|
| Repo layout | Dart **pub workspace** (monorepo): `app/`, `admin/`, `packages/core/` | The mobile app and the web admin share the same models, JSON parsing and calculators, so fares are computed the same way everywhere. |
| State / DI | `flutter_riverpod` + `riverpod_annotation` (code-gen) | As requested. Providers are easy to override in tests. |
| Navigation | `go_router` with a `StatefulShellRoute` bottom-nav shell | As requested. Deep links are needed later for share links and push alerts. |
| Local DB | **sqflite** (tests use `sqflite_common_ffi` on desktop) | Isar's original author has stopped maintaining it, and there are open Android build issues on new AGP/NDK versions. sqflite is boring, small and works well on low-end phones. |
| Models | `freezed` + `json_serializable` | Immutable value types with exact JSON round-trips. |
| Money | `int` **centavos** everywhere; formatted only in the UI | No floating-point rounding errors in totals. |
| Time | `int` minutes, plus a **min–max range** for every estimate | Sea and land travel times vary a lot, so a single number would overstate how precise we are. |
| Maps | `flutter_map` + OSM tiles, `latlong2`, `geolocator` (foreground only) | No API key. See risk R2 about offline tiles. |
| Localization | `flutter_localizations` + ARB + `gen-l10n` | See §5 for the locale codes. |
| Backend (Phase 4) | Firebase Auth, Firestore, Cloud Messaging, Hosting | As requested. Hosting serves the admin panel and the public share-trip page. |
| AR (Phase 5) | ARCore plugin, optional and feature-gated | See risk R3. |
| Lints | `flutter_lints` + stricter rules (`strict-casts`, `strict-raw-types`) | |

---

## 2. Folder structure

```
Lakbay_Romblon/
├─ pubspec.yaml                  # workspace root
├─ README.md                     # setup, Firebase, data updates, Play Store release
├─ docs/
│  ├─ phase-1-proposal.md
│  ├─ privacy-policy.md          # draft (Phase 2, finalized in Phase 5)
│  ├─ data-safety-form.md        # Play Console answers, kept in sync with features
│  └─ data-update-guide.md
├─ packages/
│  └─ core/                      # pure Dart, no Flutter dependency → fast unit tests
│     ├─ lib/src/
│     │  ├─ models/              # Municipality, Port, Voyage, BusRoute, Fare, ...
│     │  ├─ planner/             # graph builder, route search, sorting
│     │  ├─ calculators/         # fare, time, budget
│     │  ├─ checklist/           # First-Timer step engine
│     │  └─ validation/          # seed / admin data validators
│     └─ test/
├─ app/                          # Android app (app.lakbayromblon)
│  ├─ assets/
│  │  ├─ data/                   # seed JSON (see §3.3)
│  │  ├─ images/piers/
│  │  └─ map/                    # bundled pier-area tiles (if R2 approved)
│  ├─ lib/
│  │  ├─ main.dart
│  │  ├─ app/                    # MaterialApp, theme, router, l10n setup
│  │  ├─ core/                   # db, sync, connectivity, formatting, widgets
│  │  │  ├─ db/                  # sqflite schema, migrations, seed importer
│  │  │  ├─ sync/                # (Phase 4) Firestore → sqflite delta sync
│  │  │  └─ widgets/             # VerifiedBadge, MoneyText, BigButton, ...
│  │  ├─ l10n/                   # app_en.arb, app_fil.arb, app_bno.arb, app_loc.arb, app_rol.arb
│  │  └─ features/
│  │     ├─ onboarding/
│  │     ├─ planner/             # each feature: data/ domain/ presentation/
│  │     ├─ ships/
│  │     ├─ buses/
│  │     ├─ first_timer/
│  │     ├─ budget/
│  │     ├─ advisories/
│  │     ├─ guides/              # maps, pier & terminal guides
│  │     ├─ emergency/
│  │     ├─ reports/             # community reports
│  │     ├─ share_trip/
│  │     ├─ ar_guide/
│  │     └─ settings/
│  ├─ test/                      # widget tests + repository tests
│  └─ android/                   # signing config reads key.properties (git-ignored)
├─ admin/                        # Flutter web admin panel (Phase 4)
│  └─ lib/features/{auth,fares,schedules,advisories,reports,alerts,audit}/
└─ firebase/
   ├─ firestore.rules
   ├─ firestore.indexes.json
   ├─ functions/                 # (optional) send FCM on advisory publish, set admin claims
   └─ hosting/                   # share-trip page
```

Each feature follows **data → domain → presentation**:
- `data/`: repository implementations (sqflite now, plus Firestore sync in Phase 4) and DTO mapping.
- `domain/`: repository interfaces and use cases. Models and calculators come from `packages/core`.
- `presentation/`: screens, widgets, Riverpod providers/notifiers.

---

## 3. Data model

### 3.1 Trust metadata (attached to every fare, schedule and time estimate)

```dart
class Verification {
  final DateTime? lastVerified;   // null => never verified
  final String source;            // "PLACEHOLDER", "Operator notice", "Field check", ...
  final bool isPlaceholder;       // true for all seed values until an admin verifies
  final String? verifiedBy;       // admin uid (Phase 4)
}
```

UI rule: every fare and schedule shows a `VerifiedBadge`, either **"PLACEHOLDER – not verified"** (amber) or **"Last verified 12 Sep 2026"**. Data older than 90 days also gets a "may be outdated" warning. Plan totals that include any placeholder value are labelled *"Estimate includes unverified values."*

### 3.2 Entities (`packages/core/lib/src/models`)

| Entity | Key fields |
|---|---|
| **Municipality** | `id`, `name`, `island` (Tablas, Sibuyan, Romblon, Banton, Maestro de Campo, Simara, Carabao), `centroid` LatLng, `nearestPortIds[]` |
| **Place** | `id`, `name`, `kind` (municipality, port, busTerminal, manilaHub, custom), `location`, `municipalityId?` |
| **Port** | `id`, `name`, `municipalityId?`, `side` (romblon / mainland), `location`, `terminalFee` (Money + Verification), `facilities[]`, `guideId?` |
| **ShippingLine** | `id`, `name`, `contact`, `website?`, `isPlaceholder` |
| **Vessel** | `id`, `lineId`, `name`, `classes[]` (e.g. economy, tourist, cabin) |
| **Voyage** | `id`, `lineId`, `vesselId?`, `stops[]` (ordered `VoyageStop`), `daysOfWeek`, `verification` |
| **VoyageStop** | `portId`, `arrival?` / `departure?` (local time), `dayOffset` |
| **ShipFare** | `voyageId`, `fromPortId`, `toPortId`, `fareClass`, `amount` (centavos), `discounts` (student / senior / PWD %), `verification` |
| **BusOperator** | `id`, `name`, `contact`, `isPlaceholder` |
| **BusTerminal** | `id`, `name`, `location`, `isPortTerminal`, `guideId?` |
| **BusRoute** | `id`, `operatorId`, `originTerminalId`, `dropOffs[]` (terminal id + fare + minutes from origin), `firstTrip`, `lastTrip`, `headwayMinutes`, `aircon`, `verification` |
| **LocalRide** | `id`, `fromPlaceId`, `toPlaceId`, `mode` (tricycle, jeepney, van, habal-habal, taxi/TNVS, walk), `fare` range, `minutes` range, `verification` |
| **Advisory** | `id`, `type` (weather, coastGuard, portNotice), `severity`, `affectedPortIds[]`, `affectedVoyageIds[]`, `validFrom`, `validUntil`, `message` (localized map), `publishedAt`, `source` |
| **Hotline** | `id`, `agency`, `label`, `numbers[]`, `scope` (national, province, port), `portId?`, `verification` |
| **Guide** | `id`, `placeId`, `title`, `sections[]` (tip text per locale, photo asset paths), `pointsOfInterest[]` (ticket booth, waiting area, CR, gate), `arAnchors[]` (Phase 5) |
| **ChecklistTemplate** | `id`, `direction` (toManila / toRomblon), `steps[]` → `ChecklistStep { id, phase (prepare, homeToPier, atPier, onShip, atMainlandPort, onBus, arrival), titleKey, bodyKey, whatHappensNextKey, items[] }` |
| **BudgetProfile** | `cashOnHand`, `foodPerMeal`, `mealsCount`, `bufferPercent` (default 20%), `travellers` |
| **CommunityReport** (Phase 4) | `id`, `kind` (fareChange, delay, outdatedInfo, other), `targetRef` (entity type + id), `proposedValue?`, `note`, `photoUrl?`, `status` (pending, approved, rejected), `submittedAt`, `reviewerUid?` |
| **SharedTrip** (Phase 5) | `id`, `planSnapshot`, `currentStepIndex`, `updatedAt`, `expiresAt` |
| **DataMeta** | `dataVersion`, `generatedAt`, per-collection `updatedAt` (drives sync) |

### 3.3 Seed files (`app/assets/data/`)

`meta.json`, `municipalities.json`, `places.json`, `ports.json`, `shipping_lines.json`, `voyages.json`, `ship_fares.json`, `bus_operators.json`, `bus_terminals.json`, `bus_routes.json`, `local_rides.json`, `advisories.json` (empty plus one sample), `hotlines.json`, `guides.json`, `checklists.json`.

Rules:
- Every seed fare, schedule and time value has `"isPlaceholder": true, "source": "PLACEHOLDER", "lastVerified": null`.
- Operators are named **"Sample Shipping Line A" / "Sample Bus Co. 1"** until real, verified data is entered (see open question Q2).
- National hotlines that are publicly published (e.g. 911) can carry a real verified date. Anything I cannot verify stays a placeholder.
- A `core` validator test checks that the seed is internally consistent: every id it references exists, voyages have at least 2 stops, there are no negative fares, and every value carries a verification.

### 3.4 Planner model

The data becomes a **directed graph**. Nodes are `Place`s. Edges are `Leg`s:

```dart
sealed class Leg { Place from; Place to; MoneyRange fare; MinutesRange duration; Verification v; }
  LocalRideLeg | ShipLeg(voyage, fareClass, stops passed) | BusLeg(route, dropOff) | TransferLeg(walk/terminal fee)
class TripPlan { List<Leg> legs; MoneyRange totalFare; MinutesRange totalTime; int transfers; bool hasPlaceholders; }
```

- Search: a bounded depth-first search over the four stage types (home → pier → mainland port → Manila terminal → destination). It returns all valid plans, capped at about 20.
- Sorting: `cheapest` (by max fare, then time), `fastest` (by max minutes, then fare), `fewestTransfers` (then fare). Ties are broken deterministically.
- Balikbayan mode: the same engine run with the stage order reversed. Voyages are directional, so the reverse trip uses real return voyages, not mirrored ones.
- Waiting time: the time to the next scheduled departure is added when the user picks a date. Without a date, the "typical wait" range is used.
- Advisory-aware: plans that use a voyage or port covered by an active advisory are flagged, and alternates that avoid it are offered.

### 3.5 sqflite schema

There is one table per entity. Columns that are queried are typed. Nested data such as stops and localized text is stored as JSON. Tables: `municipalities, places, ports, shipping_lines, vessels, voyages, ship_fares, bus_operators, bus_terminals, bus_routes, local_rides, advisories, hotlines, guides, checklists, checklist_progress, saved_trips, budget_profiles, pending_reports (offline outbox), meta`.

On first launch the app imports the asset JSON in a single transaction. A later app update with a higher `dataVersion` re-imports the seed but keeps user tables. In Phase 4, Firestore delta sync (`updatedAt > lastSync`) writes into the same tables, so the UI always reads from local data.

---

## 4. Screen list

Bottom navigation has 4 tabs (**Plan · Guide · Safety · More**), large tap targets, and a persistent advisory banner whenever an active advisory exists.

| # | Screen | Route | Phase |
|---|---|---|---|
| 1 | Language picker + welcome (first run) | `/onboarding` | 2 (language list in 3) |
| 2 | Home / Trip planner form: hometown, destination (Cubao, Buendia/Pasay, PITX, custom), direction toggle (to Manila / balikbayan), date, travellers, fare class | `/plan` | 2 |
| 3 | Route results: plan cards, sort chips (Cheapest / Fastest / Fewest transfers), placeholder warning | `/plan/results` | 2 |
| 4 | Plan detail: step timeline (fare and time per leg, verified badge, totals), buttons for "Start First-Timer Mode", "Check budget" and "Share" | `/plan/:planId` | 2 |
| 5 | Ship list: lines, ports, schedules, fares by class, stops | `/ships`, `/ships/voyage/:id` | 2 |
| 6 | Bus list: operators, terminals, drop-offs, fares | `/buses`, `/buses/route/:id` | 2 |
| 7 | First-Timer Mode: phases, checklist, "what happens next", progress ring, resumable | `/first-timer/:planId` | 2 |
| 8 | Budget planner: cash on hand, breakdown (fares, food, terminal fees, buffer), covered / short result | `/budget` (optional `?planId=`) | 2 |
| 9 | Saved trips | `/trips` | 2 |
| 10 | Map + pier and terminal list | `/guide` | 3 |
| 11 | Pier / terminal guide detail: photos, tips, points of interest, "Open AR guide" | `/guide/:placeId` | 3 (AR button in 5) |
| 12 | Emergency hotlines: tap to call, works offline | `/safety` | 3 |
| 13 | Scam warnings & safety tips | `/safety/tips` | 3 |
| 14 | Advisories list + detail with suggested alternate | `/advisories`, `/advisories/:id` | 3 (offline seed), 4 (live) |
| 15 | Settings: language, text size, data version and last sync, privacy policy | `/more/settings` | 3 |
| 16 | Report an update: form with offline outbox | `/report` (`?target=`) | 4 |
| 17 | My reports: status | `/more/reports` | 4 |
| 18 | Share My Trip: SMS / link, progress updates | `/share/:planId` | 5 |
| 19 | AR pier guide (supported devices only) | `/guide/:placeId/ar` | 5 |
| 20 | About & data sources / disclaimers | `/more/about` | 2 |

**Admin web (Phase 4):** Login → Dashboard (pending reports, active advisories, stale data) → Fares editor → Schedules/voyages editor → Bus routes editor → Advisories editor (publish + push) → Reports review queue (approve applies the change and stamps `lastVerified`) → Hotlines/guides editor → Editors & roles → Audit log.

**Accessibility / low-end targets:** base text 18sp, respects system font scale up to 200%, WCAG AA contrast (AAA for prices), no heavy animations, images in WebP at ≤ 200 KB each, release APK per ABI under ~25 MB, cold start under 3 s on a 2 GB RAM phone.

---

## 5. Languages

| Language | Locale code | Notes |
|---|---|---|
| English | `en` | Source language / fallback |
| Tagalog (Filipino) | `fil` | Supported by Flutter's built-in Material localizations |
| Asi (Bantoanon) | `bno` (ISO 639-3) | Not in Flutter's built-in set. A custom delegate falls back to `en` for Material widget strings. |
| Onhan | `loc` | Same as above |
| Romblomanon | `rol` | Same as above |

Untranslated strings in `bno`, `loc` and `rol` are copied from English and prefixed `⟦TODO⟧`. A script and test list the untranslated keys per language, and a debug-only toggle highlights them on screen. I won't machine-translate the local languages, because a wrong translation is worse than an English fallback. Native speakers should fill these in.

---

## 6. Testing plan

- `packages/core`: unit tests for the fare calculator (classes, discounts, per-traveller, ranges), time calculator (stops, day rollover, waits), budget calculator (covered, short, exact, zero cash, buffer), route sorting (each criterion and tie-breaks), planner search (reverse trip, advisory-blocked port), and the seed validator.
- `app`: repository tests on an in-memory sqflite; widget tests for Planner form, Results (sort chips reorder), Plan detail (badges, totals), First-Timer (progress advances), Budget (covered / short states), and later Hotlines, Advisory banner, Report form.
- Every phase ends with `flutter analyze` (zero issues) and `flutter test` across all packages.

---

## 7. Risks and things I need you to know

- **R1 – Flutter SDK is not installed** on this machine. JDK 17 and an Android SDK are installed. Phase 2 needs Flutter stable installed and on PATH, followed by `flutter doctor`.
- **R2 – Offline maps:** OpenStreetMap's tile usage policy forbids bulk-downloading or prefetching `tile.openstreetmap.org` tiles for offline use. Proposal: show online OSM tiles with attribution and normal caching when online. Offline, each pier guide falls back to a **schematic layout** (vector diagram of the terminal) and coordinates with an "open in maps" link. Bundling legally generated tiles (e.g. a small MBTiles export from OpenMapTiles or Protomaps data, ODbL) can come later. Also, I'll avoid `flutter_map_tile_caching` because it's GPL-3.0, which conflicts with closed-source Play Store distribution unless you open-source the app.
- **R3 – AR plugin:** `ar_flutter_plugin` hasn't had a release in a long time and has build issues on current Android Gradle. In Phase 5 I'll evaluate a maintained fork or a thin native ARCore bridge, keep AR behind a capability check, and make sure the app builds and works without it.
- **R4 – Real data:** I won't present any fare, schedule or operator as real. Seed values are placeholders until someone verifies them through the admin panel.

---

## 8. Open questions (please answer with your approval)

1. **Local DB:** OK with **sqflite** instead of Isar (reasons in §1)?
2. **Operator names in seed data:** neutral placeholders ("Sample Shipping Line A") *(recommended)*, or real company names with placeholder fares and schedules?
3. **Monorepo:** OK to keep the app, admin panel and shared `core` package in this one folder?
4. **Flutter install:** should I install Flutter stable for you (e.g. into `C:\src\flutter` and add it to your user PATH), or will you install it yourself?
5. **Offline maps (R2):** OK with online OSM plus offline schematic pier layouts for v1?
