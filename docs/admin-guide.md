# Admin panel guide

For admins and editors of Lakbay Romblon. The panel is a website; open it on a computer.

Travellers trust what the app shows, so one rule matters most:
**never enter a fare, schedule, phone number or photo you have not checked yourself.**
If you are not sure, leave the old value and leave it unverified.

## Roles

| | Admin | Editor |
|---|---|---|
| Edit data, publish advisories, upload photos | Yes | Yes |
| Review traveller reports | Yes | Yes |
| See the change log | Yes | Yes |
| Delete change-log entries | Yes | No |
| Add, change or remove users | Yes | No |

## Signing in

Use the email and password from your invitation email. **Forgot password?** sends a reset
link. An account that is not an admin or editor cannot get past the sign-in page.

## The dashboard

- **Active advisories** and **Reports to review**: tap to open them.
- **Not verified yet**: values still marked PLACEHOLDER.
- **Verified over 90 days ago**: the app shows these as "may be outdated".
- **Needs attention** lists each kind of data with unverified or outdated values.

## Verifying a fare (or any value)

1. Open **Ship fares** (or Voyages, Bus routes, Local rides, Ports, Hotlines, Guides).
2. Use **Search**, or tick **Not verified or outdated** to see what needs checking.
3. Open the item and correct anything that is wrong.
4. Under **Verification**, write the **Source**: who you asked or what you read, and when.
   For example: *"Called Odiongan ticket office (0917…), 20 Nov 2026"* or
   *"Fare board at Batangas Port, photo taken 18 Nov 2026"*.
5. Tick **I verified these values today** only if you really checked them today.
6. **Save**.

If you save **without** ticking the box, the value is shown in the app as
*"PLACEHOLDER – not verified"*. That is the right choice when you fix a typo but have
not confirmed the value itself.

The panel refuses to save data the app could not use. For example, it blocks a fare of
zero, a voyage with fewer than two stops, or a fare for a voyage that does not exist.
Read the red box, fix the field, and save again.

## Publishing an advisory

1. **Advisories** → **New advisory**.
2. **Type** and **Severity**:
   - **Notice**: information only (no push alert).
   - **Caution**: trips may be delayed or rough (sends a push alert).
   - **Suspended**: trips are not sailing (sends a push alert; red banner in the app).
3. **Title** and **Message** in English; add Tagalog if you can.
4. **Starts** is filled in with now (Philippine time). Leave **Ends** empty for
   "until further notice".
5. **Source**: always say where it came from, e.g. *"PCG Romblon bulletin, 12:00"*.
   Only publish advisories from the Coast Guard, PAGASA, the port, or the operator.
6. **Affected ports** and **Affected voyages**: choose them, or choose none if it applies to
   all sea trips in Romblon.
7. Check the **Banner preview**, then **Publish**.

Travellers who turned on alerts get one notification when a caution or suspension is
published, or when a caution is raised to suspended. Fixing a typo later does not send
another one.

When it is over, open the advisory and press **End now**. Phones pick up changes at their
next sync (within about 15 minutes of opening the app).

## Photos

Open **Guides & photos** → a pier or terminal → **Upload photo**.

- Use photos **you took** or have **permission** to use. Tick both boxes only if they are true:
  - *I took this photo or have permission to use it.*
  - *No one can be recognised (faces) and no plate numbers are readable.*
- Write a caption that helps a first-time traveller ("Ticket windows, left of the entrance")
  and the photographer's name for the credit.
- The panel shrinks the photo to at most 1280 px and 200 KB and removes its location data.
- Press **Save** on the guide afterwards; the photo is not shown in the app until you do.

**Upload layout image** replaces the drawn pier layout with your sketch or a photo of a
signboard map. See `docs/guide-layout-format.md`.

## Traveller reports

**Reports** lists what travellers sent. They have no names or phone numbers.

- **Open in editor**: check the suggestion yourself, correct the data, verify it, and save.
  The report is marked approved and the traveller sees "Approved".
- **Already fixed**: the data is already correct; marks it approved.
- **Reject**: give a short reason (the traveller sees it), e.g. *"Fare confirmed unchanged
  with the operator"*.

A report never changes data by itself.

## Deleting and restoring

- Delete an item with the red **Delete** button on its page, or the trash icon on its row in the list.
- The panel asks first, using the item's name: *"Delete Odiongan Port? This removes it from the app for everyone."*
- If other data still uses the item, it is not deleted. The panel says what uses it, e.g.
  *"3 voyages and 12 fares use this port. Delete or change those first."*
- Phones drop a deleted item the next time they update their travel data.
- Every delete is recorded in the change log with who did it and a full copy of the item.
  **Admins** can open that entry and press **Restore** to put it back.

## Change log

Every save is recorded: who, when, and the values before and after. Open an entry to see
them. Editors cannot change or delete entries; admins can delete one if it must not be kept.

## Users (admins)

**Users** → **Add user**: their email and role. They get an email to set a password.
Change a role from the drop-down, or remove a user. You cannot change or remove yourself,
so there is always at least one admin.
