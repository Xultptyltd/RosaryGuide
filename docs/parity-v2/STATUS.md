# Visual parity status (22 Nov 2026, 2:23 PM close-the-gaps pass)

Reference: `/workspace/ios-parity-refs-v2/` (iPhone 17 Pro Max, 3×, 1320×2868 px = 440×956 pt, Dynamic Type Large, status bar 9:41, captured 17 Nov 2026 Australia/Perth).
Android captures: Pixel 7 AVD `RosaryGuide_Pixel7` (1080×2400, 2.625×, ≈411.4×914.3 dp), `en-AU`, `clock_date=2026-11-17`, demo-mode clock 9:41. Light onboarding is captured with **demo mode off** so a hidden status bar stays hidden.
pt and dp are 1:1 at mdpi. iOS PNG measurements are pixels ÷ 3. A screen is marked `matched` only when the measured frame fractions agree within about 2%.

This group is still **onboarding/launch** and **Today** only. Pray, Learn, and Profile/Settings are deferred.

`intention-icon-picker` is **not** in the live iOS editor. It stays removed.

Status values: `spec-written` · `captured` · `matched` · `mismatch` · `deferred` · `user-approved`.

| screen-id | group | spec | captured | matched | user-approved | notes |
| --- | --- | --- | --- | --- | --- | --- |
| week-feast-sheet | Today | spec-written | captured | close | user-approved | Grabber-to-eyebrow gap matched (see table). User approved the sheet as is, including the 460 dp minimum detent (sheet starts lower than the iOS estimated ~572 pt sheet). |
| launch-splash | onboarding/launch | spec-written | captured | close | | 144 dp Lottie matches iOS 144 pt, Marian blue `#0054FF` both modes, end-frame cream halo-R. Cannot hit 2% against the iOS PNGs: those refs are mid-animation, not the held end frame (see table). |
| onboarding-1 | onboarding/launch | spec-written | captured | matched | | Panel, title, dots, and CTA all within 1%. Title/CTA pinned to measured iOS frame fractions. |
| onboarding-2 | onboarding/launch | spec-written | captured | matched | | Center crop of the hands/beads, same fractions as onboarding-1 (p2 title first ink also within 1%). |
| onboarding-3 | onboarding/launch | spec-written | captured | matched | | Same panel/title/CTA match; Begin is the filled capsule. |
| sign-in | onboarding/launch | spec-written | captured | matched | | Quote and Google pinned to measured iOS frame fractions (Apple omitted; its Y is reserved by the gap, not a spacer). Quote, Google, guest, and legal all within 2%. Loop fully visible. |
| sign-in-transition | onboarding/launch | spec-written | captured | matched | | Plain `#FFFFFF` / `#000000` hold. Android-before labelled **new screen**. |
| replay-welcome | Profile/Settings | deferred | | | | Same pager as onboarding, `includesSignIn: false`. |
| profile-sign-in | Profile/Settings | deferred | | | | Same as `sign-in`, presented from Profile. |
| today | Today | spec-written | captured | matched | user-approved | Date/title/CTA/“Today's mysteries” all within 1%. Appearance chip and tab bar use a translucent fill and hairline (glass approximation; no true backdrop blur). |
| mystery-detail-sheet | Today | spec-written | captured | matched | | Fruit and CTA within 2%. Fruit is above the fold (760 dp cap). Sheet top is 3.3% higher because both sides cap at 760 on different frame heights (see table). |
| pray / Learn / Profile / Settings screens | later groups | deferred | | | | Not in this run. |

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

## Known allowed deviations

- Device chrome (status bar cutout, gesture bar, aspect) differs between iPhone 17 Pro Max and Pixel 7. Pairs are scaled to the same height.
- Android v1 sign-in is Google + guest only; the iOS Apple pill is intentionally omitted.
- Native iOS segmented `Picker` is implemented as a custom equal-width capsule (gray track, white thumb, weekday dot).
- The iOS tab bar is liquid glass; Android uses a floating capsule with a translucent fill and hairline. Android cannot sample the true backdrop the way `UIVisualEffectView` does.
- Pill buttons are capsules (50% rounding), matching iOS `PillButton`.

## Remaining mismatches after this pass

1. **launch-splash** cannot match the iOS reference PNGs within 2%, because those captures are mid-animation (light is a blank `#0054FF` field; dark is a beaded-halo mid-frame) while Android correctly holds the Lottie end-frame cream halo-R. The 144 dp player size already matches the source.
2. **week-feast-sheet** detent is still the 460 dp minimum, so the sheet starts lower than the iOS estimated height on this copy. User-approved as is.
3. **mystery-detail-sheet** sheet top is 3.3% higher on Pixel 7 because both sides cap the detent at 760 on frames of different height (914.3 dp vs 956 pt). Fruit and CTA are within 2%.
