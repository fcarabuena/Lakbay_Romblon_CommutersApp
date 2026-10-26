
Apply a new visual theme called **Tide** to both the phone app and the admin panel. Do this as its own change, separate from the admin editor work. Look at the repo structure first and tell me your plan before writing code.

## Goal

The design should be minimalist and calm. Most surfaces are white. Marine blue is used for information, titles, links and the sea parts of a trip. Island green is used only for the one main action on a screen and for success messages. Readability on low-cost Android phones matters more than decoration.

## Where to put it

- Create one shared theme in the shared core package (or whichever package both the app and the admin panel already depend on), e.g. `lib/theme/lakbay_theme.dart`. Export `LakbayTheme.light()`, which returns a Material 3 `ThemeData`.
- Use it in the app's `MaterialApp` and the admin panel's `MaterialApp`. Remove any duplicated colors or hard-coded `Colors.*` in screens and replace them with theme values.
- Light theme only for now. Set `themeMode: ThemeMode.light`.

## Colors

Build the `ColorScheme` by hand. Do not use `ColorScheme.fromSeed`, because seed generation changes these exact colors.

| Role | Hex | Use |
|---|---|---|
| primary | `#0B5C7A` | Marine blue: titles, links, selected tab, sea legs, trip summary card |
| onPrimary | `#FFFFFF` | |
| primaryContainer | `#E1EFF3` | "Shallows": selected nav pill, chips, info tints, admin sidebar active item |
| onPrimaryContainer | `#0B3F54` | |
| secondary | `#1F7A4D` | Island green: main action button, success, land legs (tricycle, bus) |
| onSecondary | `#FFFFFF` | |
| secondaryContainer | `#E3F1E8` | Success tints |
| onSecondaryContainer | `#14532F` | |
| surface | `#FFFFFF` | Cards, inputs, app bar, bottom nav, admin sidebar |
| scaffold background | `#F2F7F8` | "Mist": page background (`scaffoldBackgroundColor`) |
| onSurface | `#10232B` | "Ink": body text |
| onSurfaceVariant | `#4F6670` | "Slate": help text, secondary text, inactive tabs |
| outline | `#7C9098` | Text field borders (3.3:1, meets the 3:1 rule for controls) |
| outlineVariant | `#D5E1E4` | Dividers and card borders |
| error / onError | `#B42318` / `#FFFFFF` | Form errors |

Contrast (already checked, keep it this way): primary on white is 7.4:1, green on white is 5.3:1, Slate on white is 6.1:1, and Slate on Mist is 5.6:1. Never put grey text lighter than `#4F6670` on these backgrounds.

### Advisory colors (keep the existing meanings)

Add a `ThemeExtension<AdvisoryColors>` so banners don't hard-code colors. Keep the current meanings: red means suspended, amber means caution. Add a blue "notice" level for the admin severity cards.

| Severity | Background | Text and icon | Border |
|---|---|---|---|
| suspended (red) | `#FEF3F2` | `#9A1C12` | `#F4B4AD` |
| caution (amber) | `#FFF6DB` | `#6B4600` | `#F0C552` |
| notice (blue) | `#E1EFF3` | `#0B3F54` | `#B9D7E2` |

Every banner always shows an icon and a bold title as well as the color (for example "Suspended: …"), so it can be understood without seeing color.

## Font

- **Figtree** (weights 400, 500, 600, 700). Bundle the TTF files as font assets in the shared package rather than downloading them at runtime with `google_fonts`, so the font works offline. It's free under the SIL Open Font License at fonts.google.com/specimen/Figtree. Check that the ₱ sign displays correctly.
- Text sizes (sp): titleLarge 20 w700, titleMedium 16 w700, bodyLarge 16 w400, bodyMedium 15 w400, bodySmall 13 w400 (help lines), labelLarge 15 w700 (buttons), labelSmall 11 w600 (tab labels). Nothing below 11. Respect the phone's text-size setting and don't clamp `textScaler`.
- Prices and times use tabular figures: `FontFeature.tabularFigures()`.

## Shape and spacing

- Corner radius is 12 for cards, buttons, inputs, dialogs and banners. Chips and the selected bottom-nav pill use a fully rounded radius (999).
- Cards are white with a 1px `#D5E1E4` border and elevation 0. No shadows, except a small one on dialogs.
- Use a spacing scale of 4, 8, 12, 16, 20, 24 and 32. Page padding is 16 on the phone and 24 to 28 in the admin panel. The gap between form fields is 12 to 14.
- Touch targets are at least 48 high. Buttons and inputs are 48 high.

## Component themes to set in ThemeData

- **FilledButton** (main action, one per screen): green `#1F7A4D`, white text, height 48, radius 12, full width on phone.
- **OutlinedButton** (secondary actions like "Cancel" or "Pick on map"): primary text, 1.5px primary border, radius 12.
- **TextButton**: primary.
- **InputDecorationTheme**: filled white, radius 12, 1.5px `outline` border, focused border 2px primary, label above the field in onSurface w700 13sp, helper text in onSurfaceVariant 12 to 13sp, error in `#B42318`.
- **AppBarTheme**: white background, onSurface text, no elevation, 1px bottom divider (`outlineVariant`), title 16 to 18 w800.
- **NavigationBarTheme** (5 tabs: Plan, Schedules, Guide, Safety, More): white background, indicator pill `#E1EFF3`, selected icon and label primary, unselected `#4F6670`, labels always shown.
- **ChipTheme**: `#E1EFF3` background, primary text, w600, pill shape.
- **DividerTheme**: `#D5E1E4`, 1px.
- **Admin sidebar** (NavigationRail or custom drawer): white background, item text `#2C434C`, active item on `#E1EFF3` with primary bold text, radius 8. Group headings ("Sea travel", "Land travel", "Help for travelers") in 10.5sp uppercase `#4F6670`.
- **SnackBar**: `#10232B` background, white text.

## Screens to touch up

- Trip result: a summary card on primary with white text (route, total fare, door-to-door hours, number of rides). Each leg has a 34×34 rounded icon: primary for ship legs and green for land legs. Show the fare right-aligned in tabular figures.
- Admin empty dashboard: when there's no data, show a white card that says "The app has no travel information yet". It has a green "Load starter data" button, an outlined "I'll add my own" button, and a small tinted box listing what starter data adds (towns, ports, ship fares, hotlines). Below it, show four "Step" cards: Ports, Shipping lines, Voyages & fares, Hotlines. Each card shows how many have been added and has an "Add …" link.

## Rules

- Change only how things look. Don't change any data, Firestore fields or IDs.
- Don't put hex colors in individual screens. Everything comes from `Theme.of(context)` or the `AdvisoryColors` extension.
- Add a widget test that pumps a screen with `LakbayTheme.light()` and checks that the FilledButton uses the green, plus a golden test or a check of the advisory banner colors.
- Run `flutter analyze` and all tests in core, the app and the admin panel. Then run `flutter build web` for the admin panel. Ask me before redeploying.
