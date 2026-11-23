# Profile / Settings typography and spacing

Source: iOS `OfferView`, `SettingsView`, `PrayerRhythmCard`, `GuestBackupCard`, `AppTheme.TypeRole` / `Space` / `Component`.

pt → dp 1:1 and pt → sp 1:1. Fonts: Instrument Sans. `TypeRole.regularized` maps semibold/bold back to regular; medium stays medium.

SwiftUI typo line height = size × 1.22. Compose `includeFontPadding = false`. Historical tokens (`body` 16/23, `headingPrimary` 32/38, `caption` 12/16, `headingSecondary` 22/28, `supportingLabel` 15/20) are unchanged so approved Today / onboarding / Pray / Learn frames stay put. Profile and Settings use the typo-accurate `*Pray` roles.

## Type roles on live Profile / Settings screens

| Role (iOS) | Size / weight / pitch | Android |
| --- | --- | --- |
| Large “Profile” title | `h1` / large nav | `GuideLargeTopAppBar` / `h1Navigation` (unchanged chrome) |
| Compact “Settings”, “All intentions”, pushed titles | `navigationTitle` 17 medium | `navigationTitlePray` 17 medium |
| “Find room for prayer”; “What’s on your heart?” | `cardTitle` / `headingSecondary` 22, typo 26.84 | `headingSecondaryPray` 22/26.84 |
| “Your prayer”, quiet section labels | `supportingLabel` 15 typo | `supportingLabelPray` |
| Rhythm weekday letters | `caption` 12, typo 14.64 | `captionPray` 12/14.64 |
| Settings rows, backup headline (`body` regularized-semibold), papal title (`callout` regularized-semibold), empty-card subtitle (`bodySmall` = callout) | 16 regular, typo 19.52 | `bodyPray` 16/19.52 |
| Papal month, settings meta / version | `caption` 12, typo 14.64 | `captionPray` 12/14.64 |
| Strong section labels (“General”, “Your intentions”, “Holy Father’s intention”) | `GuideSectionLabel` prominence `.strong` = body 16 | `bodyPray`, `strong = true` |

## Layout spacing

| Location | iOS | Android |
| --- | --- | --- |
| Page gutter | `gutter` 16 | `RosarySpace.gutter` 16 |
| Rhythm / empty-intention card inset | `PrayerPreview.cardInset` / `Space.lg + xs` = 20 | 20 |
| Container / card radius | `containerRadius` 20 | 20 |
| Guest backup card radius | `featureRadius` 24 | 24 |
| Settings section title → rows | `sectionTitleGap` 20 | 20 |
| Settings / profile row min height | `profileRowHeight` 56 | 56 |
| Icon column | `Space.xl` 24, symbol 20 light | 24 dp column, 20 dp glyph |
| Icon → title | `Space.lg` 16 | 16 |
| Papal photo | 96 × 96, flush left, clipped to card radius | 96 dp, flush left |
| Papal photo → title | `Space.lg` 16 | 16 |
| Empty-card heart circle | 44 pt, asset at 0.8 | 44 dp |
| Backup icon | `icloud.and.arrow.up` 34 | 34 dp |
| Backup stack | `Space.md` 12 / `xs` 8 / button `sm` 8 + top | 12 / 8 / 20 |
| Dividers | `Component.hairline` in `palette.hair` | `Hairline` 1 px in `palette.hair` |

`minHitTarget` stays 48 dp on Android (iOS 44) except already-sized 40 dp milky chips (gear, back, more).

Allowed native M3 swaps, unchanged: accent switches (not iOS green), an M3 text button for Done, side-by-side dialog actions, no Apple button, no blur.

## Notes on measured differences

Pixel 7 logical width is ≈411.4 dp vs iOS 440 pt, so a 16-body line that fits on iPhone 17 Pro Max can wrap earlier on Android. The Settings guest-backup headline “Your prayers have not been backed up for 11 days” wraps before “days” on Pixel 7; the type role itself is 16/19.52 on both sides. Frame-fraction Y also drifts slightly because the Pixel 7 logical height is ≈913.9 dp vs iOS 956 pt.

Rhythm weekday dots are the typo-accurate 16 / 6 / 22 dp construction from iOS (`Day` markers), but the filled “past” disc reads lighter and a little smaller than the iOS screenshot, likely from anti-aliasing at 2.625× vs 3×.
