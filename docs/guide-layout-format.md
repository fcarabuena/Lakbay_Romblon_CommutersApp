# Pier and terminal layout format

Each guide in `app/assets/data/guides.json` (later: the `guides` collection in Firestore, edited from the
admin panel) can carry a `layout`. The app shows it in the **Layout** tab, which works offline.

The layouts that ship now are **illustrative placeholders**: generic drawings, not surveyed plans. They
are flagged `"isIllustrative": true`, and the app shows *"Illustrative layout, not to scale. Verify on site."*

## Two ways to replace a layout

### Option A: upload a sketch or photo (easiest)

Set `imageUrl` (an image uploaded through the admin panel) or `imageAsset` (an image bundled in the app).
When either is set, the app shows the image **instead of** the drawing. If the image fails to load
(for example offline, before it's cached), the drawn `areas` are shown as a fallback, so keep them if you can.

```json
"layout": {
  "width": 12, "height": 8,
  "imageUrl": "https://…/odiongan-port-layout.png",
  "isIllustrative": false,
  "areas": [ … ],
  "verification": {"source": "Site visit sketch", "isPlaceholder": false, "lastVerified": "2026-11-20"}
}
```

### Option B: edit the drawn areas

The drawing is a grid of rectangles in **layout units** (any unit you like; it's scaled to the screen).

```json
"layout": {
  "width": 12,
  "height": 8,
  "seaSide": "top",
  "isIllustrative": true,
  "areas": [
    {"id": "gate", "kind": "gate", "label": {"en": "Boarding gate", "fil": "Gate papasakay"}, "x": 4, "y": 1.5, "w": 4, "h": 1}
  ],
  "verification": {"source": "PLACEHOLDER", "isPlaceholder": true, "lastVerified": null}
}
```

| Field | Meaning |
|---|---|
| `width`, `height` | Size of the whole drawing in layout units. |
| `seaSide` | `"top"` draws a "Sea" band above the drawing. Leave out for bus terminals. |
| `areas[].x`, `y` | Top-left corner, from the top-left of the drawing. |
| `areas[].w`, `h` | Width and height. Every area must fit inside `width` × `height` (the validator checks this). |
| `areas[].kind` | `entrance`, `ticketing`, `waiting`, `restroom`, `food`, `baggage`, `gate`, `boarding`, `transport`, `security`, `office`, `other`. Sets the colour and icon. |
| `areas[].label` | Text in each language. Missing languages fall back to English. |
| `isIllustrative` | Set to `false` only for a plan drawn from a real site visit. |
| `verification` | Same as fares: who checked it and when. |

Sketching tip: draw the pier on squared paper, with one square = one unit. Then copy each box's corner, width and height.

## Points of interest (Map tab)

`pointsOfInterest` are markers on the live map. Each needs a `location` (`lat`, `lng`) taken on site,
for example from a phone's map app while standing at the ticket office. Entries without a location
are not drawn. The shipped data has **no** invented coordinates; only each place's own location is on the map.

## Photos

`photos` is a list of `{ "url" | "asset", "caption" }`. None ship yet. Add real photos through the
admin panel (Phase 4). Use photos you have permission to use, and avoid showing people's faces.
