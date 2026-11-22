# Visual parity status (22 Nov 2026, Roborazzi Pixel 7 chrome pass)

Reference: `/workspace/ios-parity-refs-v2/` (iPhone 17 Pro Max, 3×, 1320×2868 px = 440×956 pt, Dynamic Type Large, status bar 9:41, captured 17 Nov 2026 Australia/Perth).
Android captures for onboarding/Today: Pixel 7 AVD `RosaryGuide_Pixel7` on the Mac (1080×2400, 2.625×, ≈411.4×914.3 dp), `en-AU`, `clock_date=2026-11-17`, demo-mode clock 9:41. Light onboarding is captured with **demo mode off** so a hidden status bar stays hidden.
Pray-flow frames in this pass were recorded with **Roborazzi** because the Mac emulator was still unreachable. The harness now injects the measured Pixel 7 system insets (statusBars 52.57 dp, navigationBars 24 dp), draws a plain 9:41 / 3G status strip and a 108×4 dp gesture pill, and feeds the insets through Compose `WindowInsetsHolder` so layouts respond as on a device. Frames are 1078×2399. Recapture on the Mac emulator before calling any Pray screen `matched`.
The harness was validated against the approved Mac captures: today-light title 0.5429 vs 0.5440 (Δ 0.11%); onboarding-1 title/CTA within ~0.02%.
pt and dp are 1:1 at mdpi. iOS PNG measurements are pixels ÷ 3. A screen is marked `matched` only when the measured frame fractions agree within about 2%.

Onboarding/launch and Today are **user-approved**. This pass continues the **Pray flow** group. Learn and Profile/Settings are still deferred.

`intention-icon-picker` is **not** in the live iOS editor. It stays removed.

Status values: `spec-written` · `captured` · `matched` · `mismatch` · `deferred` · `user-approved`.

| screen-id | group | spec | captured | matched | user-approved | notes |
| --- | --- | --- | --- | --- | --- | --- |
| week-feast-sheet | Today | spec-written | captured | close | user-approved | Grabber-to-eyebrow gap matched (see table). User approved the sheet as is, including the 460 dp minimum detent (sheet starts lower than the iOS estimated ~572 pt sheet). |
| launch-splash | onboarding/launch | spec-written | captured | close | user-approved | 144 dp Lottie matches iOS 144 pt, Marian blue `#0054FF` both modes, end-frame cream halo-R. Cannot hit 2% against the iOS PNGs: those refs are mid-animation, not the held end frame (see table). |
| onboarding-1 | onboarding/launch | spec-written | captured | matched | user-approved | Panel, title, dots, and CTA all within 1%. Title/CTA pinned to measured iOS frame fractions. |
| onboarding-2 | onboarding/launch | spec-written | captured | matched | user-approved | Center crop of the hands/beads, same fractions as onboarding-1 (p2 title first ink also within 1%). |
| onboarding-3 | onboarding/launch | spec-written | captured | matched | user-approved | Same panel/title/CTA match; Begin is the filled capsule. |
| sign-in | onboarding/launch | spec-written | captured | matched | user-approved | Quote and Google pinned to measured iOS frame fractions (Apple omitted; its Y is reserved by the gap, not a spacer). Quote, Google, guest, and legal all within 2%. Loop fully visible. |
| sign-in-transition | onboarding/launch | spec-written | captured | matched | user-approved | Plain `#FFFFFF` / `#000000` hold. Android-before labelled **new screen**. |
| replay-welcome | Profile/Settings | deferred | | | | Same pager as onboarding, `includesSignIn: false`. |
| profile-sign-in | Profile/Settings | deferred | | | | Same as `sign-in`, presented from Profile. |
| today | Today | spec-written | captured | matched | user-approved | Date/title/CTA/“Today's mysteries” all within 1%. Appearance chip and tab bar use a translucent fill and hairline (glass approximation; no true backdrop blur). |
| mystery-detail-sheet | Today | spec-written | captured | matched | user-approved | Fruit and CTA within 2%. Fruit is above the fold (760 dp cap). Sheet top is 3.3% higher because both sides cap at 760 on different frame heights (see table). |
| pray-* / rosary-settings-sheet | Pray flow | spec-written | captured | close | | Roborazzi with Pixel 7 system chrome (Mac still offline). See per-screen rows and the Pray measurement section. |
| pray-opening | Pray flow | spec-written | captured | close | | Roborazzi + insets. Next CTA bottom Δ 0.54%. Typography and centering match. |
| pray-intention-step | Pray flow | spec-written | captured | close | | Roborazzi + insets. Title Δ 0.41%; Next CTA bottom Δ 0.85%. Selected row now uses a filled accent circle with a white check, matching the iOS selected chip. |
| pray-mystery-plate | Pray flow | spec-written | captured | close | | Roborazzi + insets. Art window now follows iOS `rosaryMysteryArtworkTopInset` / `0.58` bottom with `bandFocus` fill (Annunciation y = 0.51), so the whole composition sits on a plain backdrop with the dove under the header. Dark shots set the `+night` qualifier so `drawable-night-nodpi` is used. Header chips are 40 dp milky circles. Title Δ 0.50%; Fruit last ink Δ 0.49% (same-method). All landmarks within 2%. Still Roborazzi — recapture on the Mac before `matched`. |
| pray-hail-mary-bead | Pray flow | spec-written | captured | close | | Roborazzi + insets. Next + Complete decade, bead highlight, and “1 of 10” match; CTA bottom Δ 0.54%. |
| pray-decade-end | Pray flow | spec-written | captured | close | | Roborazzi + insets. Fatima copy and bead locus match; CTA bottom Δ 0.54%. |
| pray-final-prayers | Pray flow | spec-written | captured | close | | Roborazzi + insets. Still the short-prayer Next pill, as on the Pro Max ref; CTA bottom Δ 0.54%. |
| pray-completion | Pray flow | spec-written | captured | close | | Roborazzi + insets. Completion plate uses `ArtCatalog.focus` fill in a 1.15-aspect top band (the tall leftover was over-zooming) and the night art variant. Title “Joyful Mysteries” Δ 0.35%; Done bottom Δ 1.45%. All landmarks within 2%. Quote `jp2-contemplate`. Still Roborazzi — recapture on the Mac before `matched`. |
| pray-michael | Pray flow | spec-written | captured | close | | Roborazzi + insets. Labels are exactly “English”, “Latin”, “English + Latin”. Title Δ 1.26%; Done CTA bottom Δ 0.85%. Segmented-control style is M3, not the iOS capsule. |
| rosary-settings-sheet | Pray flow | spec-written | captured | close | | Roborazzi + insets. Rows sit in rounded inset cards on `groupedBackground`, with “Each decade” / “Closing prayers” headers and leading repeat / moon.stars icons inside the cards. Light header is untinted (no M3 lavender surface). Done stays an M3 accent text button; switches stay M3 on-colour with a stronger off-track. Title Δ 1.97%, sheet edge Δ 1.82%. |
| pray-replace-dialog | Pray flow | spec-written | captured | close | | Roborazzi + insets. Copy matches; title Δ 1.28%. Dialog surface is untinted (`tonalElevation = 0`). Material 3 alert (side-by-side accent actions) vs iOS stacked red “Replace saved place” / black Cancel — kept as a native M3 swap. |
| Learn / Profile / Settings screens | later groups | deferred | | | | Not in this run. |

Pairs: `/workspace/android/shots/v2/pairs/<screen-id>-<light|dark>.png` (iOS left, Android right).
Sign-off sheets: `/workspace/android/shots/v2/signoff/<screen-id>.png` (iOS \| Android-before \| Android-after; light on top, dark below). Before frames for splash/onboarding/sign-in/today come from the earlier parity pass. Sheets and sign-in-transition are labelled “new screen”.

## Measurement tables (light, unless noted)

Fractions are y / frame height (top of frame = 0). Δ is `|android − ios|` in percentage points of the frame.

### week-feast-sheet (user-approved as is)

iOS gap is measured from the drag-indicator bottom to the “Memorial · 21 November 2026” top: 72 px ÷ 3 = **24 pt** (0.0251 of the frame). Android uses a 36×4 dp handle with 5 dp top padding and 24 dp content top padding.

| landmark | iOS | Android | Δ |
| --- | --- | --- | --- |
| sheet top | 0.402 | 0.487 | 8.5% |
| grabber bottom | 0.412 | 0.497 | 8.5% |
| eyebrow top (“Memorial · …”) | 0.437 | 0.526 | 8.9% |
| grabber-bottom → eyebrow gap (frac) | 0.0251 | 0.0296 | 0.45% |
| grabber-bottom → eyebrow gap (pt/dp) | 24.00 pt | 27.05 dp | 3.05 dp |

The 0.45% gap match is the requested fix. The sheet itself starts lower because Android still uses `weekFeastSheetHeight() = 460.dp` (the iOS minimum), while the iOS ref uses the estimated detent (~572 pt for this copy), capped at 640. The user approved this sheet as is, including that detent.

### launch-splash (cannot hit 2% vs the iOS PNGs)

Android holds the Lottie **end frame** in both modes, as `LaunchSplashView` / `holdSplash` specify: a 144 dp player (iOS 144 pt) with a solid cream halo-R, visible glyph ≈ 0.183 × 0.100 of the Pixel 7 frame, vertically centered at y 0.449–0.548. Canvas is `#0054FF` both modes.

The iOS reference PNGs were captured mid-animation, not at that end frame:

| landmark | iOS light | Android light | iOS dark | Android dark |
| --- | --- | --- | --- | --- |
| canvas | `#0054FF` (blank / mid-fade) | `#0054FF` | `#0658FF` | `#0054FF` |
| visible monogram | none (do not chase) | cream halo-R, 0.183 × 0.100, y 0.449–0.548 | beaded halo sliver 0.140 × 0.020 at y 0.474–0.493, ghost R | same end-frame cream halo-R as light, 0.183 × 0.100, y 0.449–0.548 |

Matching the iOS PNGs within 2% would mean holding a mid-fade frame, which the source does not do. The size token (144 dp) already matches. This is a reference-timing exception, not a Pixel 7 aspect-ratio miss.

### onboarding-1 / 2 / 3 (light; dark uses the same layout)

Panel bottom is the last non-page pixel at x = 8% (inside the 24 pt inset). Title is the first substantial ink cluster after the panel (p2 also has a 5–7 px first-ink speck one line above the main block, on both platforms). CTA is the filled Continue / Begin pill. Title top is pinned at 0.573 of the frame and CTA top at 0.868.

| landmark | iOS | Android | Δ |
| --- | --- | --- | --- |
| panel bottom | 0.492 | 0.489 | 0.3% |
| title top (p1 / p3) | 0.573 | 0.582 | 0.9% |
| title top (p2, first ink / main block) | 0.573 / 0.579 | 0.582 / 0.589 | 0.9% / 1.0% |
| dots | 0.845–0.851 | 0.843–0.849 | 0.2% |
| CTA top | 0.868 | 0.868 | 0.0% |
| CTA mid | 0.895 | 0.896 | 0.1% |
| CTA bottom | 0.922 | 0.925 | 0.3% |

The remaining ~0.9% title offset is leftover typographic ascent above the first ink, even with `includeFontPadding = false`. Dark pages use the same 50% black panel; the figure is `scaledToFill` with top (pages 1 and 3) or center (page 2) alignment.

### sign-in (light; dark uses the same layout)

Lower content is pinned to the measured iOS frame fractions (`signInQuoteTop = 0.576`, `signInGoogleTop = 0.775`) so Pixel 7’s shorter window and nav inset do not shift the stack. The Apple pill is omitted (Android v1 rule); its Y is left as a gap rather than a spacer, so Google stays at the iOS Google position.

| landmark | iOS | Android | Δ |
| --- | --- | --- | --- |
| panel bottom (Marian fill at x=8%) | 0.492 | 0.489 | 0.3% |
| quote top | 0.576 | 0.584 | 0.8% |
| Apple pill | 0.708–0.762 | omitted | — |
| Google (iOS filled / Android outlined) | 0.776–0.828 (mid 0.802) | 0.776–0.830 (mid 0.803) | 0.0% / 0.2% |
| guest | 0.861–0.873 | 0.854–0.866 | 0.7% |
| legal | 0.927–0.936 | 0.915–0.923 | 1.2% |

Dark panel is `brandCanvas` black; the loop is fully visible with 40 dp padding above the panel bottom.

### today (user-approved)

| landmark | iOS | Android | Δ |
| --- | --- | --- | --- |
| title first line | 0.536 | 0.543 / 0.553 | ≤ 1.7% |
| title second line | 0.601–0.639 | 0.596–0.633 | 0.6% |
| CTA top | 0.778 | 0.773 | 0.5% |
| CTA mid | 0.805 | 0.801 | 0.4% |
| CTA bottom | 0.832 | 0.830 | 0.2% |
| “Today's mysteries” | 0.874–0.882 | 0.873–0.882 | 0.1% |

### mystery-detail-sheet (light; dark matches)

The true iOS “Fruit” line is the “Fruit Obedience to God’s Will” row at 0.855–0.866, just above the pager dots — not the scripture-reference line at 0.782–0.790. Android uses the iOS 1.3-aspect plate and `Space.xl` (24) between art, title, scripture, and Fruit, with `includeFontPadding = false`.

| landmark | iOS | Android | Δ |
| --- | --- | --- | --- |
| Fruit line | 0.855–0.866 | 0.838–0.850 | 1.7% / 1.6% |
| CTA top | 0.889 | 0.899 | 1.0% |
| CTA bottom | 0.941 | 0.956 | 1.5% |
| Fruit above the fold? | yes | yes | — |
| sheet top | 0.191 | 0.158 | 3.3% |

**Sheet top** is the one landmark that cannot reach 2% on Pixel 7 without breaking the iOS 760 cap. Both sides cap the detent at 760 (pt/dp). On the Pro Max that is 760/956 ≈ 0.795 of the frame (measured top 0.191). On Pixel 7 it is 760/914.3 ≈ 0.831 of the frame (measured top 0.158). Raising the sheet to match the iOS frame fraction would exceed the 760 cap; lowering it to 0.191 would shrink the body and risk pushing Fruit toward the fold. Fruit and CTA already sit within 2%, so the cap is left as specified.



### Harness validation vs approved Mac Pixel 7 captures

Roborazzi now injects statusBars 52.57 dp and navigationBars 24 dp (measured from the Mac today / week-feast frames, not the 24/48 dp guess) and paints a plain 9:41 + 3G strip plus a 108×4 dp gesture pill 10 dp from the bottom. Light onboarding hides the status bar, matching the Mac “demo mode off” capture. Today() in the validation shot uses 17 November 2026 so the mystery set matches the Mac Sorrowful frame.

| landmark | Mac | Roborazzi | Δ |
| --- | --- | --- | --- |
| today-light title | 0.5429 | 0.5440 | 0.11% |
| onboarding-1 title | 0.5888 | 0.5890 | 0.02% |
| onboarding-1 CTA | 0.8679–0.9246 | 0.8679–0.9246 | ~0.02% |

### Pray flow (Roborazzi + Pixel 7 chrome, light; Mac emulator still unreachable)

Android frames are 1078×2399 with emulated Pixel 7 insets and chrome. iOS refs are 1320×2868. Δ is raw full-frame. These are not yet signed off as `matched` — they still need a Mac Pixel 7 recapture.

| screen | landmark | iOS | Android (Roborazzi) | Δ | notes |
| --- | --- | --- | --- | --- | --- |
| pray-opening | Next bottom | 0.8846 | 0.8900 | 0.54% | typography / centering match |
| pray-intention-step | title top | 0.1900 | 0.1859 | 0.41% | was 3.9%; 21 dp nudge + `includeFontPadding = false` |
| pray-intention-step | Next bottom | 0.9474 | 0.9558 | 0.85% | |
| pray-mystery-plate | art fade / visible art end | 0.5579 | 0.5502 | 0.77% | fixed hero, text scrolls |
| pray-mystery-plate | eyebrow “I JOYFUL” top | 0.6144 | 0.6061 | 0.83% | |
| pray-mystery-plate | title “The Annunciation” top | 0.6457 | 0.6407 | 0.50% | `modalTitle` 22/28, `includeFontPadding = false` |
| pray-mystery-plate | scripture first line top | 0.6911 | 0.6878 | 0.33% | reading pitch 31.07 pt vs 31.18 dp |
| pray-mystery-plate | Fruit last ink | 0.9111 | 0.9062 | 0.49% | true Fruit line, beside the circle; same-method last ink (prior 0.9149 / 0.9158 used a slightly more sensitive threshold) |
| pray-mystery-plate | scroll control | circle 0.8937–0.9470 | circle 0.8991–0.9558 | 0.54 / 0.88% | collapsed circle, floating over the reading |
| pray-hail-mary-bead | Next bottom | 0.8846 | 0.8900 | 0.54% | Next filled + Complete decade tertiary |
| pray-decade-end | Next bottom | 0.8846 | 0.8900 | 0.54% | Fatima, bead locus correct |
| pray-final-prayers | Next bottom | 0.8846 | 0.8900 | 0.54% | still the Next pill, not a scroll circle |
| pray-completion | tick top | 0.5474 | 0.5398 | 0.76% | `completionTick` = `textPrimary` |
| pray-completion | ROSARY COMPLETE top | 0.6074 | 0.6028 | 0.46% | 6 pt under the tick slot, `includeFontPadding = false` |
| pray-completion | title “Joyful Mysteries” top | 0.6346 | 0.6311 | 0.35% | 6 dp bottom inset unchanged; art crop no longer fills the tall leftover |
| pray-completion | Done top | 0.8431 | 0.8549 | 1.18% | |
| pray-completion | Done bottom | 0.8971 | 0.9116 | 1.45% | |
| pray-completion | Saint Michael bottom | 0.9644 | 0.9825 | 1.81% | 6 dp above the Pixel 7 gesture pill |
| pray-michael | title top | 0.1402 | 0.1276 | 1.26% | labels match the iOS source exactly |
| pray-michael | Done bottom | 0.9474 | 0.9558 | 0.85% | |
| rosary-settings-sheet | sheet edge | 0.0753 | 0.0571 | 1.82% | sized to iOS `.large` detent |
| rosary-settings-sheet | “Customise rosary” | 0.1137 | 0.1334 | 1.97% | M3 text Done; M3 accent switches |
| pray-replace-dialog | title | 0.4132 | 0.4260 | 1.28% | copy matches; Material vs UIKit chrome |

In-flow Saint Michael (the optional closing *step*, toggle off by default) has no v2 iOS ref; `pray-michael` is the post-completion overlay. The scroll-to-continue morph’s collapsed (circle) state is now shown on `pray-mystery-plate` via `scrollPlateToEnd` and a plate end-spacer that includes `ScrollMorph.minimumRange`. There is no mid-lerp iOS ref to chase.

Visual review (22 Nov 2026, after the sign-off visual pass): the plate and completion now show the full Annunciation (angel, dove, Mary) on a plain / black backdrop, with the dove under the header, using the iOS fill + focus crop and the night art variant. Header back/settings/close chips are 40 dp milky circles in both modes. The customise sheet is grouped into inset rounded cards with section icons, an untinted light header, and stronger off-switch tracks; Done stays an M3 accent text button. Intention selected state is a filled accent check circle. The replace-dialog surface is untinted. Remaining visual differences to be candid about: language toggles are still M3 segmented (more rectangular than the iOS capsule) on opening / Hail Mary / decade-end / final-prayers / Michael; replace-dialog actions stay side-by-side M3 vs iOS stacked red/black; customise switches stay M3 blue vs iOS green; “Bible translation” and its value sit tighter on the narrower Pixel 7 row than on the Pro Max; completion art has a slightly taller white gap above the tick because the crop is a top-aligned 1.15 band rather than a full leftover fill; plate side margins are still a hair tighter than iOS (Pixel 7 is narrower). Dark layouts for completion and the plate now use the dark art, not the light-grey plate on black.

## Known allowed deviations

- Device chrome (status bar cutout, gesture bar, aspect) differs between iPhone 17 Pro Max and Pixel 7. Pairs are scaled to the same height.
- Android v1 sign-in is Google + guest only; the iOS Apple pill is intentionally omitted.
- Native iOS segmented `Picker` is implemented as a custom equal-width capsule (gray track, white thumb, weekday dot).
- The iOS tab bar is liquid glass; Android uses a floating capsule with a translucent fill and hairline. Android cannot sample the true backdrop the way `UIVisualEffectView` does.
- Pill buttons are capsules (50% rounding), matching iOS `PillButton`.
- Native M3 swaps (kept, not chased): customise switches use M3 accent rather than iOS system green; the replace dialog is a side-by-side M3 alert rather than iOS stacked red “Replace saved place” / black Cancel; customise Done is an M3 text button because iOS uses a native `toolbar` `confirmationAction`, not a custom `PillButton`.

## Remaining mismatches after this pass

1. **launch-splash** cannot match the iOS reference PNGs within 2%, because those captures are mid-animation (light is a blank `#0054FF` field; dark is a beaded-halo mid-frame) while Android correctly holds the Lottie end-frame cream halo-R. The 144 dp player size already matches the source.
2. **week-feast-sheet** detent is still the 460 dp minimum, so the sheet starts lower than the iOS estimated height on this copy. User-approved as is.
3. **mystery-detail-sheet** sheet top is 3.3% higher on Pixel 7 because both sides cap the detent at 760 on frames of different height (914.3 dp vs 956 pt). Fruit and CTA are within 2%.
4. **Pray flow frames** are still Roborazzi, not Mac-emulator captures. Landmarks remain within 2% after the visual pass (plate title Δ 0.50%, Fruit last ink Δ 0.49%, completion title Δ 0.35%, Done bottom Δ 1.45%). Recapture every Pray screen on the Mac Pixel 7 emulator before marking any of them `matched`, especially the Lottie tick on a real device, plate overflow/scroll-circle, and sheet/dialog chrome.
