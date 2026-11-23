# Profile / Settings typography and spacing

Source: iOS `OfferView`, `SettingsView`, `PrayerRhythmCard`, `GuestBackupCard`, `AppTheme.TypeRole` / `Space` / `Component`.

pt → dp 1:1 and pt → sp 1:1. Fonts: Instrument Sans. `TypeRole.regularized` maps semibold/bold back to regular; medium stays medium.

SwiftUI typo line height = size × 1.22. Compose `includeFontPadding = false`. Historical tokens (`body` 16/23, `headingPrimary` 32/38, `caption` 12/16, `headingSecondary` 22/28, `supportingLabel` 15/20) are unchanged so approved Today / onboarding / Pray / Learn frames stay put. Profile and Settings use the typo-accurate `*Pray` roles.

## Type roles on live Profile / Settings screens

| Role (iOS) | Size / weight / pitch | Android |
| --- | --- | --- |
| Large “Profile” title | `h1` / large nav | Profile-only title row, `h1Navigation` (shared `GuideLargeTopAppBar` unchanged) |
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


## Measured landmark table (tightening pass, 23 Nov 2026)

Equal-scale ink projection (iOS px / 3 = pt, Android Pixel 7 px / 2.625 = dp). Target: text size and in-paragraph line pitch within 0.5 sp, gaps within 1 dp, frame-fraction landmarks within 2%.

Typography on these screens is 1:1 from the `*Pray` roles by construction (see the table above). The automatic line detector also sees icons, photographs, cards, progress bars and dialog chrome, so the **median pitch is not a clean type measurement** on mixed screens such as Profile, App icon, Journey and the confirm dialogs. Use it as a landmark index, then read the 2× zoom crops with baseline guides in `/workspace/android/shots/v2/signoff/zoom/`.

Cleaner text screens stay inside budget: `settings-legal-terms` and `settings-legal-privacy` median pitch Δ −0.05; `settings-license` Δ 0.00; `journey-prayer-sheet` Δ +0.29; `delete-intention` Δ +0.02; `prayer-journey-history` Δ −0.69 (just outside the 0.5 sp pitch budget on mixed list rows).

| Screen | iOS median pitch (pt) | Android median pitch (dp) | Δ | Detected lines (iOS/Android) |
| --- | ---: | ---: | ---: | ---: |
| `profile` | 22.00 | 18.29 | -3.71 | 12/15 |
| `profile-backup` | 15.83 | 19.05 | +3.21 | 15/17 |
| `profile-sign-in` | 20.00 | 12.57 | -7.43 | 10/8 |
| `replay-welcome` | 24.67 | 21.33 | -3.33 | 7/6 |
| `intention-detail` | 19.67 | 16.00 | -3.67 | 10/10 |
| `delete-intention` | 20.17 | 20.19 | +0.02 | 11/6 |
| `papal-intention-detail` | 26.33 | 19.81 | -6.52 | 11/9 |
| `prayer-journey-milestones` | 15.17 | 16.57 | +1.40 | 12/20 |
| `prayer-journey-history` | 15.17 | 14.48 | -0.69 | 12/16 |
| `journey-day-sheet` | 13.67 | 25.33 | +11.67 | 10/4 |
| `journey-prayer-sheet` | 26.00 | 26.29 | +0.29 | 13/11 |
| `settings` | 12.00 | 19.81 | +7.81 | 18/15 |
| `settings-notifications` | 24.00 | 14.86 | -9.14 | 8/8 |
| `settings-app-icon` | 20.17 | 15.62 | -4.55 | 11/12 |
| `settings-legal-terms` | 23.67 | 23.62 | -0.05 | 27/25 |
| `settings-legal-privacy` | 23.67 | 23.62 | -0.05 | 28/25 |
| `settings-license` | 18.67 | 18.67 | +0.00 | 29/12 |
| `settings-report-problem` | 12.00 | 5.33 | -6.67 | 11/7 |
| `settings-mail-unavailable` | 10.00 | 20.19 | +10.19 | 13/5 |
| `settings-clear-history` | 16.33 | 20.19 | +3.86 | 14/7 |


2× zoom crops (equal pt/dp scale, baseline guides) for every screen in the group live at `/workspace/android/shots/v2/signoff/zoom/{stem}.png`.

## Review-pass landmarks (23 Nov 2026)

Equal-scale ink (iOS px / 3, Android px / 2.625), after the compact-bar, title-offset, Settings padding and list-pitch fixes.

| Landmark | iOS (pt) | Android (dp) | Δ |
| --- | ---: | ---: | ---: |
| Profile title top | 118.3 | 122.7 | +4.4 (status-inset) |
| Profile title mid | 134.7 | 139.0 | +4.3 |
| Rhythm card top | 194.7 | 198.1 | +3.4 |
| Settings title mid | 85.3 | 85.7 | +0.4 |
| Settings first-section ink mid (“General”) | 161.7 | 162.1 | +0.4 |
| All-intentions first icon top | 144.0 | 144.4 | +0.4 |
| All-intentions title-to-title pitch | 66.33 / 65.17 | 65.71 / 64.57 | ≤ 1.0 |
| Compact “Profile” / gear mid on `profile-backup` | — | 74.1 / 74.3 | centred in the 44 dp bar below the 52.57 dp status strip |

