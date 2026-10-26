# Firebase setup

This connects the app and the admin panel to a Firebase project. Until it is done,
the app works offline on its bundled data: no sync, reports wait on the phone,
and the advisory-alert setting is hidden.

Do the steps in order. Steps 1–5 are in the Firebase and Google Cloud consoles
(your Google account); the rest are commands run from `D:\Projects\Lakbay_Romblon`.

## 1. Create the project

1. Open <https://console.firebase.google.com> and choose **Create a project**.
2. Name it, for example `lakbay-romblon`. Note the **project ID** it shows (it may get a suffix).
3. Google Analytics: **turn it off**. The app does not use it, and leaving it off keeps
   the privacy policy simple.

## 2. Blaze plan and a ₱100/month budget alert

Photo storage and the push-alert function need the pay-as-you-go **Blaze** plan.
At this app's size, use should stay inside the no-cost quotas, but set an alert anyway.

1. In the Firebase console: the gear icon → **Usage and billing** → **Details & settings** →
   **Modify plan** → **Blaze**. Link or create a billing account (a card is required).
2. Open <https://console.cloud.google.com/billing>, choose the billing account, then
   **Budgets & alerts** → **Create budget**:
   - Scope: this project only.
   - Amount: **₱100** per month (set the currency on the billing account; if it is in
     USD, use the closest amount, about $2).
   - Alert thresholds: **50%, 90% and 100%** of actual spend, emailed to billing admins.
3. A budget **alerts you; it does not stop spending**. If you ever get an alert, check
   **Usage and billing** to see what is growing, and tell me so we can find the cause.

## 3. Firestore and Storage (location matters)

1. **Firestore Database** → **Create database** → **Production mode** → location
   **`asia-southeast1` (Singapore)**. The location cannot be changed later, and the
   push-alert function is set to the same region (`firebase/functions/index.js`).
2. **Storage** → **Get started** → same location → production mode.

The security rules in this repository replace the default rules in step 7.

## 4. Sign-in methods

**Authentication** → **Get started** → **Sign-in method**:

- **Email/Password**: on (admins and editors).
- **Anonymous**: on (travellers sending reports, with no account or personal details).

## 5. Cloud Messaging

Nothing to switch on: Firebase Cloud Messaging is available in every project. The
function sends to topics; phones subscribe only after the traveller opts in.

## 6. Connect the app and the admin panel

Once, install the FlutterFire CLI (it goes into the pub cache on D:):

```sh
dart pub global activate flutterfire_cli
firebase login
```

Then:

```sh
cd app
flutterfire configure --project=<project-id> --platforms=android --android-package-name=app.lakbayromblon
cd ../admin
flutterfire configure --project=<project-id> --platforms=web
cd ..
firebase use --add            # pick the project; saves .firebaserc
```

`flutterfire configure` replaces the placeholder `lib/firebase_options.dart` in each
folder (and adds `google-services.json` for Android, which is git-ignored). These files
are not secret: access is controlled by the security rules.

## 7. Deploy the rules, indexes and alert function

```sh
firebase deploy --only firestore,storage
cd firebase/functions
npm install --cache D:\npm-cache
cd ../..
firebase deploy --only functions
```

The function `advisoryAlerts` sends one push alert when a **caution** or **suspended**
advisory is published (or raised from caution to suspended). Plain edits do not re-alert.

## 8. Admin panel hosting

```sh
cd admin
flutter build web
cd ..
firebase deploy --only hosting
```

The panel is then at `https://<project-id>.web.app`. Nothing in the app links to it.

## 9. The first admin

1. **Authentication** → **Users** → **Add user**: your email and a temporary password.
   Copy the new user's **User UID**.
2. **Firestore Database** → **Start collection** `admins` → **Document ID**: paste the UID →
   fields:
   - `role` (string): `admin`
   - `email` (string): your email
3. Open the admin panel, sign in, and on the dashboard choose **Load starter data**.
   This copies the bundled sample data (all still marked PLACEHOLDER) into Firestore,
   with a change-log entry for each item.
4. Change your password with **Forgot password?** on the sign-in page.

Add other admins and editors from the panel's **Users** page. They get an email to set
their password.

## 10. Build the app with Firebase

After step 6, the next `flutter build apk` includes Firebase. On launch the app syncs
(at most every 15 minutes, or with **Settings → Refresh now**), sends queued reports,
and shows **Advisory alerts** in Settings.

## Testing the security rules locally

The rule tests run on the Firebase emulators, which need **Java 21** (installed at
`D:\Java\jdk-21.0.12.1+1`; the JDK 17 used for Android builds is unchanged). From Git Bash:

```sh
cd /d/Projects/Lakbay_Romblon
export JAVA_HOME="/d/Java/jdk-21.0.12.1+1" PATH="/d/Java/jdk-21.0.12.1+1/bin:$PATH"
export FIREBASE_EMULATORS_PATH='D:\firebase-emulators'   # keeps the emulator download off C:
(cd firebase/rules-test && npm install --cache D:/npm-cache)
firebase emulators:exec --only firestore,storage --project demo-lakbay "npm test --prefix firebase/rules-test"
```

The push-alert logic has its own tests: `cd firebase/functions && npm test`.

## Before a public release

- Turn on **App Check** with Play Integrity for the Android app and enforce it for
  Firestore. Anonymous sign-in is easy to automate; App Check makes report spam much harder.
  (Each device is already limited to 10 reports a day by the rules.)
- Review the budget alert emails and Firestore usage after the first weeks.
