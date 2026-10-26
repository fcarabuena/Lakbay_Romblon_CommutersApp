# Lakbay Romblon: Phase 4 Plan

Status: **built, awaiting approval** (2026-10-26).
Decisions: community reports included (text-only, anonymous, 10 a day per device); Blaze plan with a ₱100/month budget alert; opt-in push alerts for caution and suspension advisories only; roles **admin** (everything, including users and deleting change-log entries) and **editor** (data and reports).
Scope: Firebase backend, live advisories, the web admin panel, real photo support and community reports.

Changes from the plan while building:
- Starter data is loaded from the admin panel (**Load starter data** on an empty project) instead of a `tool/upload_seed.dart` script, which would have needed a service-account key on this PC.
- `firebase.json` is at the repository root (the Firebase CLI expects it there); the rules, functions and rule tests are in `firebase/`.
- The admin panel edits the same JSON shape as the seed files, checked with the app's own parser and validator, so models did not need JSON writers (only `Verification` got one).

## 1. Firebase setup (needs you once)

- **One Firebase project** (for example `lakbay-romblon`) with an Android app `app.lakbayromblon` and a web app for the admin panel.
  - Creating it requires your Google account, so you do it. I'll walk you through `firebase login` and `flutterfire configure`.
  - That generates `firebase_options.dart` and `google-services.json`. These aren't secret, but they're git-ignored with a template file so the project isn't tied to one Firebase project.
- **Services:**
  - Firestore for data
  - Authentication: email/password for admins, and anonymous sign-in for reporters if question 1 is yes
  - Storage for photos
  - Hosting for the admin panel
- **Billing:** Firebase Storage needs the pay-as-you-go **Blaze plan** for new projects, as do Cloud Functions (needed for push notifications).
  - At this app's size, usage should stay inside the free quotas.
  - I'll document setting a low **budget alert** (for example ₱100/month) before anything is turned on. See question 2.
- **The app still works offline-first.** Firebase only *refreshes* the local database. With no internet, or Firebase not configured, the app runs on the bundled and last-synced data exactly as it does now.
- I won't deploy anything or create cloud resources without asking you first.

## 2. Data sync (app)

- Firestore mirrors the local collections: `ports`, `voyages`, `ship_fares`, `bus_routes`, `local_rides`, `guides`, `hotlines`, `safety_tips`, `advisories`, … Each document has an `updatedAt`.
- On launch and on pull-to-refresh (at most every 15 minutes), the app fetches only documents changed since the last sync (`updatedAt > lastSync`) and writes them into the same sqflite tables. Deletions are soft (`deleted: true`), so they sync too.
- Every incoming document goes through the existing `DataValidator` first. A bad document is skipped and logged, and never wipes good local data.
- Firestore's own offline cache is turned off, because sqflite is the single local store and that avoids keeping two copies on low-storage phones.
- Settings shows "Data last updated: …" and a **Refresh now** button.
- A one-off script, `tool/upload_seed.dart`, loads the current seed JSON into Firestore so the admin panel starts with the same data. Everything stays marked PLACEHOLDER until an admin verifies it.

## 3. Advisories (app)

- **New `Advisory` model** in `packages/core`:
  - type (weather, Coast Guard, port notice, operator notice)
  - severity (info, caution, suspended)
  - affected ports and voyages
  - valid from/until
  - localized message
  - source and when it was published
- **Banner** at the top of the Plan, Schedules and Guide tabs whenever an advisory is active. "Suspended" is red, the others amber, and it can't be dismissed while the advisory is active. Tapping it opens the list.
- **Screens:** `/advisories` (active first, then recently ended) and `/advisories/:id` (full message, affected trips, source, published time).
- **Planner awareness:**
  - Plans that use an affected voyage or port get a warning chip.
  - Results offer "Show alternatives that avoid this", which re-runs the planner without the blocked voyages and ports.
  - Saved trips and First-Timer mode show the warning too.
- **No made-up advisories:** `advisories.json` ships empty. Sample advisories exist only in tests. Every advisory shows its source and the line *"Always confirm with the Coast Guard or shipping line before travelling."*
- **Push notifications:** these are optional (see question 3). If you approve them, a Cloud Function sends one when an admin publishes a caution or suspension advisory, to people subscribed to the affected ports or "all of Romblon". It's opt-in in Settings, which shows the Android 13+ notification permission prompt. If you don't approve them, the app picks up advisories at the next sync.

## 4. Real photos

- **Admin upload:**
  - The admin picks an image, which is resized in the browser to at most 1280 px and saved as JPEG at 200 KB or less. That's the size target from Phase 1; I'm using JPEG because Dart can't encode WebP.
  - The image goes to Storage under `guides/{guideId}/…`.
  - Photo location (EXIF/GPS) metadata is removed by the re-encode.
- **Required at upload:**
  - a caption (English, plus Tagalog if you have it)
  - a credit
  - a checkbox: *"I took this photo or have permission to use it"*
  - a checkbox: *"No identifiable faces or plate numbers"*

  The upload is blocked until both are ticked. Both are stored with the photo.
- **Layout images:** the same uploader can set a guide's `layout.imageUrl`. That's Option A in `guide-layout-format.md`, which is already supported by the app.
- **App side:**
  - Uses `cached_network_image` (MIT), which keeps photos after the first view and shows a placeholder while loading or offline.
  - Each guide gets a **"Save photos for offline"** button. It only downloads that guide's photos, and warns if you're on mobile data.
  - Tap a photo for a full-screen view with zoom.
- **Storage rules:** anyone can read, and only admins can write. Uploads must be images under 1 MB.

## 5. Admin panel (`admin/`, Flutter web)

- **Login:** email/password. A user counts as an admin only if an `admins/{uid}` document exists, which the security rules check. You add the first admin by hand in the Firebase console (I'll write the steps). Two roles: **admin** (everything, including managing editors) and **editor** (data, no user management).
- **Dashboard:** active advisories, pending reports, and **stale data** (placeholder values, or values not verified in 90+ days), with links to fix each one.
- **Editors** (tables with search, each with an edit form):
  - Ship fares and voyages (stops, days, times)
  - Bus routes and drop-offs
  - Local rides
  - Hotlines, which shows `hotlines-to-verify.md` as a checklist
  - Guides: tips, layout, points of interest, photos
  - Advisories: create, preview the banner, publish, end early
- **Verification is explicit.** Saving a value doesn't mark it verified. The editor fills in a **source** and ticks *"I verified this"*, which stamps `lastVerified` and `verifiedBy`. Unticked edits stay as placeholders.
- **Validation:** the same `DataValidator` from `packages/core` runs before every save, so the admin can't save data the app would reject. For example, it blocks a voyage with fewer than two stops, a fare below zero, or a stop that refers to a port that doesn't exist.
- **Audit log:** every save writes a record of who changed what, when, and the before and after values. The security rules make it append-only, and the panel lets you view and filter it.
- **Hosting:** built with `flutter build web` and deployed to Firebase Hosting when you say so. It's linked from nowhere in the app.

## 6. Community reports (if question 1 is yes)

- In the app, a **Report an update** button on fares, schedules, guides and hotlines opens a short form: what's wrong, the suggested value, and a note. Reports are text only, with no photo upload from the public; that avoids moderating images and faces.
- Reports wait in an **offline outbox** and send when there's internet. Sending uses anonymous sign-in, so no account or personal data is needed.
- **My reports** (`/more/reports`) shows each report's status: pending, approved or rejected.
- **Admin review queue:** the admin sees the current value next to the suggested one. **Approve** opens the normal editor pre-filled with the suggestion, so verification and the audit log still apply. **Reject** takes an optional reason.
- **Abuse limits:** the security rules check field sizes, and each anonymous user can send at most 10 reports a day.

## 7. Security rules

- **Travel data, advisories and photos:** anyone can read; only admins and editors can write.
- **`admins`:** only admins can write.
- **`audit_log`:** admins and editors can create entries; nobody can update or delete them.
- **`reports`:** a signed-in user can create a valid report and read their own; admins and editors can read and update all reports.
- **Rule tests:** they run against the Firebase emulator. It's installed through the Firebase CLI, which is already on this PC. Recent versions of the emulator may need **JDK 21** (this PC has JDK 17). If so, I'll install it on D: and won't touch the JDK 17 used for Android builds.

## 8. Structure and code changes

- `packages/core`:
  - The `Advisory` model and a check for whether an advisory is active at a given time
  - The planner's avoid-voyages/ports option
  - A `CommunityReport` model
  - Validator rules for the new types
  - A JSON writer (`toJson`) for every model, which the admin panel needs
- `app/lib/core/sync/`: a `RemoteSource` interface, its Firestore implementation, and the sync service. Tests use a fake `RemoteSource`, so no test touches the network.
- `app/lib/features/advisories/`, `app/lib/features/reports/`.
- `admin/` is a new workspace package with features `auth`, `dashboard`, `editors`, `advisories`, `photos`, `reports`, `audit`.
- `firebase/` holds `firestore.rules`, `storage.rules`, `firestore.indexes.json`, `firebase.json` and `functions/` (only if push is approved).
- `dataVersion` goes to 3, adding the `advisories` table. The local database schema goes to v3, adding a `pending_reports` outbox table and sync timestamps. Saved trips and checklist progress are kept.
- **New dependencies:**
  - Firebase: `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`, and `firebase_messaging` (only with push)
  - Other: `cached_network_image`, `connectivity_plus`, `image` (admin only), `file_picker` (admin only)
- Expect the debug APK to grow by a few MB from the Firebase libraries. I'll report the release size per ABI against the 25 MB target.

## 9. Tests

- **Core:**
  - Advisory active-window logic (start, end, time zone, open-ended)
  - The planner avoiding blocked voyages and ports, including when no alternative exists
  - JSON round-trips for every model
  - Validator rules for advisories and reports
- **App:**
  - Sync: delta merge, soft delete, an invalid document skipped, no network, and Firebase not configured
  - Advisory banner: shown or hidden, colour by severity
  - Advisory list and detail screens
  - Warning chips and the "avoid" alternatives on results
  - Report form and outbox: queued while offline, sent when back online
  - Photo gallery: placeholder while loading, failure fallback, and the offline-save button
- **Admin:**
  - Login gating (non-admins are refused)
  - Editor validation blocks bad data
  - Photo upload is blocked without both checkboxes
  - Verification stamping
  - An audit entry is written on every save
  - Approving a report pre-fills the editor
- **Security rules:** emulator tests for every rule in section 7.
- **End of phase:**
  - `flutter analyze` clean for app, admin and core
  - all tests passing
  - a debug APK build
  - a `flutter build web` of the admin panel

  Per your instruction, nothing gets installed or run on a device or emulator.

## 10. Docs

- `docs/firebase-setup.md`: creating the project, the Blaze plan and budget alert, adding the first admin, and deploying the rules and admin panel.
- `docs/admin-guide.md`: how to verify a fare, publish an advisory, upload photos with permission, and review reports. It's written for non-developers.
- `docs/privacy-policy.md`: the anonymous report ID, notification topics if push is approved, and the fact that photos are uploaded by admins only.
- The README and the notes for the Play Store data safety form get updated too.

## 11. Not in Phase 4

- Share My Trip and the public share page (Phase 5)
- The AR pier guide (Phase 5)
- Any real fares, schedules, numbers or photos. Those are entered and verified by you or your admins through the panel. I won't invent or scrape them.

## 12. Questions for you

1. **Community reports:** your message listed advisories, the admin panel and photos. The Phase 1 roadmap also put community reports in Phase 4. Should I keep them in? *(Recommended: yes. The admin review queue reuses the editors, and it's how stale data gets noticed.)*
2. **Blaze plan:** are you OK upgrading the Firebase project to Blaze, with a budget alert, for photo storage? Without it, photos can't use Firebase Storage. The alternative is bundling approved photos into the app in each release, which makes the APK bigger and means photos only update with an app update.
3. **Push notifications** for caution and suspension advisories: build them now (needs a Cloud Function on Blaze), or rely on sync only for v1? *(Recommended: build them now, opt-in. A suspended trip is the most useful thing to tell someone quickly.)*
4. **Admin accounts:** who will be the first admin (which email)? Do you want the editor role, or just admins for now?
