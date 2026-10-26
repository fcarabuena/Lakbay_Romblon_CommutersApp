# Lakbay Romblon Privacy Policy (DRAFT)

> **DRAFT for review.** Not legal advice. Have it reviewed against the Philippine
> Data Privacy Act of 2012 (RA 10173) before publishing. Replace every
> `[PLACEHOLDER]`. Sections marked *(planned)* describe features that are not
> released yet; remove them or mark them as live when they ship.

**Effective date:** [PLACEHOLDER DATE]
**Developer / data controller:** [PLACEHOLDER NAME], [PLACEHOLDER ADDRESS]
**Contact:** [PLACEHOLDER EMAIL]

## 1. Summary

Lakbay Romblon helps you plan trips between Romblon and Metro Manila. Most of
the app works entirely on your phone. We do not sell your data, show ads, or
track you across other apps.

## 2. Information stored only on your phone

- **Trip plans, saved trips, First-Timer checklist progress and budget inputs.**
  These stay in the app's private storage on your device. Uninstalling the app
  or clearing its data deletes them.
- **Travel data** (ports, schedules, fares) that the app downloads or bundles.
  This is not personal information.

## 3. Location

Only if you tap **"Use my location"** (on the pier and terminal guides), the app asks for your phone's
location **while you use the app**. It uses it to sort piers and terminals by distance and to show
where you are on a pier map. Your location is processed on your phone and is **not sent to us** or
stored. The app never uses location in the background. Every feature works without location permission,
and you can turn it off anytime in Android settings.

Map images come from OpenStreetMap tile servers. Opening a map sends your phone's IP address and the
map area being viewed to that tile server, as with any website. The app caches viewed map tiles on your
phone. See the OpenStreetMap Foundation privacy policy.

## 3a. Phone calls

The emergency hotline buttons open your phone's dialer with the number filled in. The app cannot place
calls by itself and does not record which numbers you call.

## 3b. Language and display settings

Your chosen language and text size are stored on your phone only.

## 4. Community reports

You can report that a fare, schedule, guide or hotline looks wrong. You do not need
an account. When you send a report we collect:

- what you wrote (the kind of change, a suggested value and an optional note),
- the item it is about, as shown in the app,
- the time, the app language and the app version,
- a random identifier created by Firebase anonymous sign-in for this installation,
  so you can see your own reports' status and we can limit reports to 10 per day.

We do **not** collect your name, phone number, email, location or photos with a
report. Please do not type personal details into the note. Reports are read only by
our admins and editors, who check them before changing anything; reports are not
published. A report waits on your phone until you have internet. Reports are stored
with Google Firebase (Cloud Firestore, Singapore region), and Google may process data
outside the Philippines.

## 5. Advisory alerts (optional)

Alerts are **off** until you turn them on in Settings. If you do, the app asks for
permission to show notifications and subscribes this phone to alert topics in Firebase
Cloud Messaging: "all of Romblon", or the ports you choose, in English or Tagalog. Firebase
creates a device token for this; we do not receive a list of who subscribed. We send alerts
only for trip cautions and suspensions. Turning alerts off unsubscribes the phone.

## 5a. Travel data updates

When online, the app downloads updated travel data (fares, schedules, advisories,
guide photos) from Google Firebase. Like any web service, Google's servers receive your
phone's IP address for these requests. No personal information is sent with them.

## 6. Share My Trip *(planned, Phase 5)*

You decide what to share and with whom. By **SMS**, the message goes from your
phone through your mobile network; we do not receive it. A **share link**
uploads your trip plan and progress (no precise location unless you choose to
include it) so your family can view it. Anyone with the link can see it. Links
expire after [PLACEHOLDER: e.g. 7 days] and you can stop sharing at any time.

## 7. Who we share data with

Only service providers needed to run the features above (Google Firebase,
OpenStreetMap tile servers), and authorities when required by law. We do not
sell or rent personal information.

## 8. Retention

- On-device data: until you delete it or uninstall the app.
- Community reports: [PLACEHOLDER, e.g. 2 years], then deleted. The anonymous identifier
  is removed from Firebase Authentication after [PLACEHOLDER, e.g. 1 year] without use.
- Admin and editor accounts (staff only): their email, until the account is removed.
- Share links: deleted when they expire or when you stop sharing.

## 9. Your rights

Under the Data Privacy Act you may access, correct, object to processing of,
and request deletion of your personal data, and you may file a complaint with
the National Privacy Commission (privacy.gov.ph). Contact us at [PLACEHOLDER EMAIL].

## 10. Children

The app is not directed at children under 13 and does not knowingly collect
their personal information.

## 11. Safety and accuracy

Fares, schedules and travel times are estimates and may be outdated. Always
confirm with the shipping line, bus company, port authority or the Philippine
Coast Guard. Values marked "Sample, not verified" are not real data.

## 12. Changes

We will post changes here and update the effective date. Significant changes
will be announced in the app.
