# Rosary Guide

Native iOS companion for praying the Holy Rosary. SwiftUI, Swift 5.9, iOS 17+. No WebView, no backend, no account. Everything lives on device.

Bundle ID: `com.shasasmith.RosaryGuide`

## Open in Xcode

1. On a Mac, install **Xcode 15.4 or later**.
2. Open `RosaryGuide.xcodeproj`.
3. Select the **RosaryGuide** scheme and an iPhone or iPad simulator (or your device).
4. Choose your Development Team under Signing & Capabilities if you are running on a device.
5. Press **Run** (⌘R).

Unit tests for Easter, seasons, mystery assignment, and rosary sequence: **Product → Test** (⌘U).

## What you can do

- **Home** — today’s liturgical season, feast if any, and the mystery set the calendar assigns, with a week strip and a button to begin.
- **Pray** — full traditional sequence with English, Latin, or both. Light haptics on Hail Marys, stronger on Our Fathers, Glory Bes, and mystery announcements, success when the rosary finishes. Leave mid-way and resume later (saved for 36 hours).
- **How to Pray** — eight steps, a bead diagram placeholder, and the weekday/season schedule.
- **Feasts** — fixed Marian and liturgical days plus movable dates from Easter (Ash Wednesday through Christ the King).
- **Settings** — language, system/light/dark, Prayer to Saint Michael, haptics.

## Mystery calendar

Weekdays follow the usual modern usage (Joyful Monday/Saturday, Sorrowful Tuesday/Friday, Glorious Wednesday, Luminous Thursday). Sundays follow the season:

| Season | Sunday mysteries |
| --- | --- |
| Advent and Christmas | Joyful |
| Lent | Sorrowful |
| Easter and Ordinary Time | Glorious |

Easter is computed with the Gregorian Computus. Christmas, Easter, Good Friday, the Assumption, Our Lady of the Rosary, and a few other solemnities override the weekday set.

## Texts

- Traditional prayer texts in English and Latin (Sign of the Cross, Apostles’ Creed, Our Father, Hail Mary, Glory Be, Fatima prayer, Hail Holy Queen, concluding collect, Prayer to Saint Michael).
- All **20 mysteries** with Douay–Rheims excerpts (public domain), references, a short meditation, and the common USCCB fruits.
- Completion quotes from saints and Our Lady of Fatima.

## Art placeholders

Mystery “stained glass” panels and the How to Pray bead diagram are **placeholders**, not commissioned sacred art. Swap in images later under `RosaryGuide/Assets.xcassets` and point `MysteryArtworkView` at them.

## Privacy

Settings and the in-progress rosary are stored in `UserDefaults` on the device. The app does not track, network, or collect data. See `RosaryGuide/PrivacyInfo.xcprivacy`.

## Project layout

```
RosaryGuide.xcodeproj
RosaryGuide/                  App, models, catalogs, services, views, assets
RosaryGuideTests/             Calendar and sequence tests
```
