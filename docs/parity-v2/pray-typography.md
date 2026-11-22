# Pray typography and spacing (audit-sprint-native)

Source: iOS `audit-sprint-native` (`AppTheme.TypeRole`, `AppTheme.Space`, `AppTheme.Component`, `FontRegistrar`, and the Pray views).  
Android maps pt → dp 1:1 and pt → sp 1:1. Dynamic Type is Large on both sides.

Fonts are **Instrument Sans** (UI) and **Newsreader** (serif). iOS registers the variable fonts in `Fonts/` and sets the `wght` / `opsz` axes through `FontRegistrar`. Android ships static instances of the same families. Typo metrics match (Instrument Sans UPM 1000, typo 970/−250/0; typo line height = size × 1.22).

`TypeRole.regularized(_:)` maps `.semibold`, `.bold`, `.heavy`, and `.black` back to `.regular`. Medium stays medium (axis 500).

SwiftUI `.tracking(x)` is an absolute point value → Compose `letterSpacing = x.sp`.  
SwiftUI `.lineSpacing(s)` adds space *between* lines only. Compose equivalent: `lineHeight = font typo line height + s`, with `LineHeightStyle` trim `Both` and `includeFontPadding = false`. Roles without extra spacing use typo line height and trim `None`.

## Type roles used on Pray screens

| Role (iOS) | Size / weight / family | iOS line pitch (pt) | Tracking | Old Android | New Android |
| --- | --- | --- | --- | --- | --- |
| `headingPrimary` / `screenTitle` / `title2` | 32 regular Instrument Sans | typo 39.04 | 0 | `headingPrimary` 32 / 38, font padding on | `headingPrimaryPray` 32 / 39.04, padding off |
| `headingSecondary` / `modalTitle` / `title3` / `headline` | 22 regular | typo 26.84 | −0.2 on prayer titles | `modalTitle` 22 / 28, padding often on, no tracking on bead titles | `modalTitlePray` 22 / 26.84, tracking −0.2, padding off |
| `navigationTitle` | 17 medium | typo 20.74 | 0 | `navigationTitle` 17 / 22 | `navigationTitlePray` 17 / 20.74, padding off (Customise title) |
| `body` / `callout` / `bodySmall` / `settingsRow` / `sectionHeading` / `pillLabel` | 16 regular | typo 19.52 | 0 | `body` 16 / 23, font padding on | `bodyPray` 16 / 19.52, padding off |
| `supportingLabel` | 15 regular | typo 18.30 | 0 | `supportingLabel` 15 / 20 | `supportingLabelPray` 15 / 18.30, padding off |
| `caption` / `label` / `sectionLabel` | 12 regular | typo 14.64 | varies | `caption` 12 / 16 | `captionPray` 12 / 14.64, padding off |
| `label(weight: .medium)` progress header | 12 medium | typo 14.64 | 0 | **`navigationTitle` 17 / 22** | `progressLabel` 12 / 14.64 medium |
| `caption(weight: .medium)` “1 of 10”, set eyebrow | 12 medium | typo 14.64 | eyebrow +2 (RosaryFlow) | 12 medium, 2.sp on plate; bead count used 12 / 16 | `captionMediumPray`, plate tracking 2 |
| `segmentedControl` | 14 medium | typo 17.08 | 0 | `segmentedControl` 14 / 18 | `segmentedControlPray` 14 / 17.08 |
| `prayerText(scale: 1)` | 18 regular | typo 21.96 | 0 | `prayerText` 18 / **21** | `prayerText` 18 / 21.96 |
| `BilingualStack` prayer (beads + plate) | 18 regular + lineSpacing `21×1.65 − native(21)` = +9.03 | **30.99** | 0 | Beads used 18 / **21** (not the reading style). Plate used 18 / 31. Latin was Newsreader italic 16 / 23 | `prayerTextReading` 18 / 30.99, trim Both, same sans on Latin |
| `PrayerReaderBlock` (Saint Michael) | 18 regular + `lineSpacing(Space.sm)` = +8 | **29.96** | 0 | `prayerText` 18 / 21; Latin Newsreader italic | `prayerTextMichael` 18 / 29.96, trim Both, same sans on Latin |
| `completionQuote` | `body` 16 + `lineSpacing(2)` | **21.52** | 0 | `body` 16 / 23 | `completionQuote` 16 / 21.52, trim Both |
| `quoteAttribution` | `caption` 12 + `tracking(0.8)` | typo 14.64 | 0.8 | **`supportingLabel` 15 / 20** + 0.8 | `quoteAttribution` 12 / 14.64, tracking 0.8 |
| “ROSARY COMPLETE” | caption 12 + tracking 1.4 | typo 14.64 | 1.4 | 12 / 16, 1.4, padding off | `captionPray` + 1.4 |
| `scriptureReference(isMystery: true)` | 11 regular | typo 13.42 | 0 | 11 / 14 | `scriptureReferenceMystery` 11 / 13.42 |
| `guideThemeSummaryStyle` (Michael Latin title) | `themeSummary` = callout 16 + `lineSpacing(5)` | **24.52** | 0 | `body` 16 / 23 | `themeSummary` 16 / 24.52 |
| Fruit label | body medium 16 + `fruitTracking` 0.8 | typo 19.52 | 0.8 | 16 / 23, padding off, tracking 0.8 | `bodyPray` medium, 0.8 |
| `regularized(.semibold)` on intention row titles | body **regular** 16 (semibold is regularized) | typo 19.52 | 0 | body regular 16 / 23 | `bodyPray` regular 16 / 19.52 |

The older `RosaryType.body` (16 / 23) and `headingPrimary` (32 / 38) roles are unchanged so approved Today / onboarding frames stay put.

## Layout spacing (Pray + customise)

| Location | iOS | Old Android | New Android |
| --- | --- | --- | --- |
| Prayer paragraph gap (`BilingualStack`) | `Space.xxl` 32 | `\n\n` rendered as one blank line at the (wrong) line pitch | 32 dp between split paragraphs |
| Saint Michael paragraph gap (`PrayerReaderBlock`) | `Space.xl` 24 | same blank-line treatment | 24 dp |
| Title → body (most steps) | `prayerTitleBodyGap` 22 | 22, but Latin title was *inside* that gap | 22 *after* optional Latin title |
| Title → body (Sign of the Cross, plate) | `Space.lg` 16 | 16 (plate) | 16 |
| “1 of 10” → title | stack `sm` 8 + pad `xs` 4 = **12** | 8 | 12 |
| Eyebrow → plate title | stack `sm` 8 + pad `xs` 4 = **12** | 12 | 12 |
| Locus top inset | 2 | 0 on bead steps | 2 |
| Bilingual Latin title under English | stack `sm` 8 | 22 then Latin | 8 under the title, then the title-body gap |
| Progress header horizontal pad | `Space.lg` 16 | `sm` 8 | 16 |
| Progress header vertical pad | `xs` 4 | `xs` 4 | 4 |
| Header progress type | 12 medium | 17 medium | 12 medium |
| Intention title → first row | `Space.xxl` 32 | `sm` 8 | 32 |
| Intention row stack | `Space.md` 12 | 0 (rows flush) | 12 |
| Intention title tracking | −0.2 | none | −0.2 |
| Michael title → Latin | `sm` 8 | `xs` 4 | 8 |
| Michael title block → language control | `xl` 24 | `lg` 16 | 24 |
| Michael language → body | stack `xl` 24 + reader pad `lg` 16 | `xl` 24 | 24 + 16 vertical pad, 8 horizontal pad |
| Fruit hairline → row | `sm` 8 | 8 | 8 |
| Scripture → fruit hairline | announce stack `sm` 8 + Fruit `padding.top` `lg` 16 = **24** | 16 | 24 |
| Completion “ROSARY COMPLETE” → title | 6 | 6 | 6 |
| Completion quote card padding | horizontal `lg` 16, vertical 14 | same | same |
| Quote → attribution | `sm` 8 | 8 | 8 |
| Customise section gaps | 8 (measured grouped gap) | 8 | 8 |
| Customise row min height | `profileRowHeight` 56 | 56 | 56 |
| Pill height | `Component.pillHeight` 52 | 52 | 52 |
| Page gutter | 16 | 16 | 16 |

`minHitTarget` remains 48 dp on Android (iOS 44) for Material hit targets, except the already-sized 40 dp header chips.

## Measured on recorded frames (equal scale)

Method: iOS PNG pixels ÷ 3 = pt; Android Roborazzi pixels ÷ 2.625 = dp. Line pitch is baseline-to-baseline of the prayer (or quote) body only — CTA labels and chrome are excluded. Cap / x-height come from the ink projection of that line. Targets: pitch and size within 0.5 sp; gaps within 1 pt/dp.

Instrument Sans metrics (both platforms): cap height 720 / 1000, x-height 510 / 1000. Expected cap / x at 18 pt is 12.96 / 9.18; at 22 pt 15.84 / 11.22; at 32 pt 23.04 / 16.32; at 16 pt 11.52 / 8.16; at 12 pt 8.64 / 6.12.

### Line pitch and type size

| Screen | Role | iOS | Android | Δ | Target | Within 0.5? |
| --- | --- | --- | --- | --- | --- | --- |
| pray-opening | body pitch (Sign of the Cross) | 31.00 | 31.23 | +0.23 | 30.99 | yes |
| pray-opening | 22 pt title cap | 15.67 | 16.00 | +0.33 | 15.84 | yes |
| pray-opening | 18 pt x-height | 9.33 | 9.14 | −0.19 | 9.18 | yes |
| pray-hail-mary-bead | body pitch | 31.00 | 31.24 | +0.24 | 30.99 | yes |
| pray-hail-mary-bead | paragraph b2b | 54.00 | 54.10 | +0.10 | typo + 32 ≈ 53.96 | yes |
| pray-hail-mary-bead | 22 pt title cap | 16.00 | 16.00 | 0.00 | 15.84 | yes |
| pray-decade-end | body pitch | 31.00 | 31.24 | +0.24 | 30.99 | yes |
| pray-final-prayers | body pitch | 31.00 | 31.24 | +0.24 | 30.99 | yes |
| pray-final-prayers | paragraph b2b | 54.00 | 54.10 | +0.10 | typo + 32 ≈ 53.96 | yes |
| pray-mystery-plate | scripture pitch | 31.00 | 31.24 | +0.24 | 30.99 | yes |
| pray-mystery-plate | 22 pt title cap | 16.00 | 16.00 | 0.00 | 15.84 | yes |
| pray-mystery-plate | 12 pt eyebrow cap | 8.67 | 8.76 | +0.09 | 8.64 | yes |
| pray-completion | quote pitch | 21.67 | 21.71 | +0.04 | 21.52 | yes (both ~0.15 over target) |
| pray-completion | 32 pt title cap | 23.33 | 23.62 | +0.29 | 23.04 | yes |
| pray-completion | 12 pt caption cap | 8.67 | 8.76 | +0.09 | 8.64 | yes |
| pray-michael | body pitch | 30.00 | 30.10 | +0.10 | 29.96 | yes |
| pray-michael | paragraph b2b | 46.00 | 46.10 | +0.10 | typo + 24 ≈ 45.96 | yes |
| pray-michael | 32 pt title pitch (2 lines) | 39.33 | 39.24 | −0.09 | 39.04 | yes |
| pray-michael | 32 pt title cap | 23.00 | 23.24 | +0.24 | 23.04 | yes |
| rosary-settings-sheet | in-card row pitch | 56.00 | 56.38 | +0.38 | 56 | yes |

The opening / decade-end *auto-median* over every detected line looks worse (~1.8 / 0.74) because it mixes in CTA label pitch. Body-only figures are the ones above.

### Gaps (ink-to-ink unless noted)

| Screen | Gap | iOS | Android | Δ | Within 1? |
| --- | --- | --- | --- | --- | --- |
| pray-opening | title → body | 26.00 | 26.29 | +0.29 | yes |
| pray-hail-mary-bead | title → body | 32.33 | 32.76 | +0.43 | yes |
| pray-decade-end | title → body | 32.00 | 32.38 | +0.38 | yes |
| pray-final-prayers | title → body | 32.00 | 32.38 | +0.38 | yes |
| pray-mystery-plate | eyebrow → title | 21.67 | 22.10 | +0.43 | yes (was +1.57 before first-baseline alignment) |
| pray-mystery-plate | title → scripture | 26.00 | 26.29 | +0.29 | yes |
| pray-completion | ROSARY COMPLETE → title | 17.33 | 17.14 | −0.19 | yes |
| pray-completion | title → quote (includes card pad) | 66.33 | 66.67 | +0.33 | yes |
| pray-michael | title line gap (ink) | 16.33 | 16.76 | +0.43 | yes |
| pray-michael | title → Latin | 20.00 | 20.57 | +0.57 | yes |
| pray-michael | Latin → language (b2b) | 57.67 | 55.62 | −2.05 | **no** |
| pray-michael | language → body (b2b) | 75.67 | 74.29 | −1.38 | **no** (was −5.2 before the 44 dp height) |
| pray-intention-step | title → first row (ink) | 60.00 | 59.81 | −0.19 | yes (was +4.00 with an extra 4 dp pad) |
| rosary-settings-sheet | in-card row pitch | 56.00 | 56.38 | +0.38 | yes |

### Remaining candid misses

- **Saint Michael language control.** After matching iOS `segmentedControlHeight` (44 pt), the custom capsule still has slightly tighter internal padding than UIKit's large `UISegmentedControl`, so the Latin→control gap is 2.05 dp short and the control→body gap is 1.38 dp short. Body pitch itself is within 0.10 dp.
- **Customise.** In-card row pitch is within 0.38 dp of iOS 56. Section-to-section gaps still differ because Android uses inset grouped cards (kept from the earlier visual pass). Switches stay M3 accent, Done stays an M3 text button.
- **Replace dialog.** Not typography-compared. It remains the approved side-by-side M3 alert.
- **Wrapping.** Pixel 7 is ~412 dp wide, the Pro Max is 440 pt, so longer lines (Fatima, Hail Holy Queen, Saint Michael's title, plate scripture) break at different words. Pitch and gaps were compared at equal scale, not as frame fractions.
- Plate art / crop / inset were not changed in this pass.

2× baseline-guide crops: `/workspace/android/shots/v2/signoff/zoom/<screen>.png`.
