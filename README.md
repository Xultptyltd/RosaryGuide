# Rosary Guide

Native SwiftUI iOS companion for the cream-and-ink Rosary prayer guide. Swift 5.9, iOS 17+. No WebView and no account. Prayer progress and settings live on the device; the Holy Father’s monthly intention can refresh from a static JSON feed.

Bundle ID: `com.shasasmith.RosaryGuide`

The website is the design and content source of truth. This app matches its paintings, type, mystery texts, and pray flow — including light (cream paper `#F4F1EB`) and dark (near-black `#0C0D0F`) themes.

## Open in Xcode

1. On a Mac, install **Xcode 15.4 or later**.
2. Open `RosaryGuide.xcodeproj`.
3. Select the **RosaryGuide** scheme and an iPhone or iPad simulator (or your device).
4. Choose your Development Team under Signing & Capabilities if you are running on a device.
5. Press **Run** (⌘R).

Unit tests for Easter, seasons, mystery assignment, rosary sequence, and Home type/spacing tokens: **Product → Test** (⌘U).

## What you can do

- **Home** — tall set hero, glass Light/Dark, today’s weekday mystery set, a soft feast offer when the day’s feast suggests a different set, a horizontal mystery rail (painting, RSV reading, fruit), and a week strip that selects a set.
- **Pray** — full-screen rosary. Seven-stage paper track (Opening → I–V → Close). Mystery announcements are plate art. Hail Marys are the prayer text plus a rosary bead map. Footer has Next, Eng / Lat / Both, and Aa. Finis shows the day’s quote; Saint Michael is optional after Amen, never inserted mid-sequence.
- **How to Pray** — accordion steps, weekday schedule, and a bead map.
- **Feasts** — fixed Marian and liturgical days plus movable dates from Easter. Feasts suggest a set; they do not replace the weekday default.
- **Settings** — language, appearance, text size, optional Saint Michael after Finis, haptics.

Appearance follows the system unless you lock Light or Dark in Settings or with the Home glass control. Both modes use the website colour tokens, not stock iOS grouped backgrounds.

## Mystery calendar

Weekdays follow the usual modern usage (Joyful Monday/Saturday, Sorrowful Tuesday/Friday, Glorious Wednesday/Sunday, Luminous Thursday). Sundays follow the season:

| Season | Sunday mysteries |
| --- | --- |
| Advent and Christmas | Joyful |
| Lent | Sorrowful |
| Easter and Ordinary Time | Glorious |

Easter is computed with the Gregorian Computus. Feasts (Christmas, the Assumption, and so on) **offer** their set; the weekday assignment stays the default.

A rosary already underway can be resumed only on the **same calendar day**.

## Texts and type

- Traditional prayer texts in English and Latin (Sign of the Cross, Apostles’ Creed, Our Father, Hail Mary, Glory Be, Fatima prayer, Hail Holy Queen, concluding collect, Prayer to Saint Michael).
- All **20 mysteries** use **RSV-2CE** excerpts, titles, and fruits from `WebsiteReference/mysteries.js`.
- Completion quotes from saints and Our Lady of Fatima.
- **Instrument Sans** and **Newsreader** live in `RosaryGuide/Fonts/` (original `.woff2` plus iOS `.ttf`). They are registered at launch and listed in `UIAppFonts`. Home type size, tracking, and line-height follow `WebsiteReference/app.css` (`h1.title` clamp, `--gut`, 1.02 display leading).

## Art

Theme-aware paintings match `WebsiteReference/art.js`:

```
RosaryGuide/Art/
  light/  dark/     mystery plates and -wide cinema bands
  hero/             tall and wide set heroes
  crucifix.png
```

Light and dark plates share composition; the theme only changes the marble ground. The Xcode project copies `Art/` and `Fonts/` to the **bundle root**. Do not put a top-level `Resources/` folder in the `.app` — iOS codesign treats that as an invalid macOS-style bundle (Info.plist unbound, device install fails).

`WebsiteReference/` holds the website CSS/JS used as the native parity reference (`art.js`, `mysteries.js`, `prayers.js`, `theme.js`, `app.css`).

## Privacy

Settings and the in-progress rosary are stored in `UserDefaults` on the device. The app does not track or collect data. It may fetch `RosaryGuide/Data/PopeIntentions.json` from the public GitHub raw feed to refresh the Holy Father’s monthly intention, then caches the last valid feed locally. See `RosaryGuide/PrivacyInfo.xcprivacy`.

## Holy Father intention feed

`RosaryGuide/Data/PopeIntentions.json` is the stable app-facing feed. A scheduled GitHub Action runs `scripts/update_pope_intentions.py` daily, checks official public Vatican / Pope’s Prayer sources for the current month, validates the required fields, and commits the JSON only when it changes. The iOS app ships with the bundled JSON and quietly keeps using the bundled or cached version if the remote fetch fails.

## Project layout

```
RosaryGuide.xcodeproj
RosaryGuide/                  App, models, catalogs, services, views, Art, Fonts
RosaryGuideTests/             Calendar, sequence, and theme-token tests
WebsiteReference/             Website CSS/JS for parity
```
