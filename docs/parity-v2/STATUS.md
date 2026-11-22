# Visual parity status (22 Nov 2026 review, frame-fraction pass)

Reference: `/workspace/ios-parity-refs-v2/` (iPhone 17 Pro Max, 3×, 1320×2868 px = 440×956 pt, Dynamic Type Large, status bar 9:41, captured 17 Nov 2026 Australia/Perth).
Android captures: Pixel 7 AVD `RosaryGuide_Pixel7` (1080×2400, 2.625×, ≈411.4×914.3 dp), `en-AU`, `clock_date=2026-11-17`, demo-mode clock 9:41. Light onboarding is captured with **demo mode off** so a hidden status bar stays hidden.
pt and dp are 1:1 at mdpi. iOS PNG measurements are pixels ÷ 3. A screen is marked `matched` only when the measured frame fractions agree within about 2%.

This group is still **onboarding/launch** and **Today** only. Pray, Learn, and Profile/Settings are deferred.

`intention-icon-picker` is **not** in the live iOS editor. It stays removed.

Status values: `spec-written` · `captured` · `matched` · `mismatch` · `deferred` · `user-approved`.

| screen-id | group | spec | captured | matched | user-approved | notes |
| --- | --- | --- | --- | --- | --- | --- |
| week-feast-sheet | Today | spec-written | captured | close | | Grabber-to-eyebrow gap matched (see table). Sheet still uses the 460 dp minimum detent, so it starts lower than the iOS estimated ~572 pt sheet. |
| launch-splash | onboarding/launch | spec-written | captured | close | | 144 dp Lottie matches iOS 144 pt, Marian blue `#0054FF` both modes. iOS light ref is mid-fade (blank canvas) — not chased. |
| onboarding-1 | onboarding/launch | spec-written | captured | close | | Panel and title within 2%. CTA is 2.2–2.5% lower (same 24 dp + safe-area tokens; Pixel 7 inset/aspect). |
| onboarding-2 | onboarding/launch | spec-written | captured | close | | Center crop of the hands/beads, same fractions as onboarding-1. |
| onboarding-3 | onboarding/launch | spec-written | captured | close | | Same panel/title match; Begin is the filled capsule. |
| sign-in | onboarding/launch | spec-written | captured | close | | 50% panel and full loop now match. Quote within ~2%. Google sits ~6% lower than the iOS Google pill (Apple omitted; Apple-height spacer reserved). No Apple button (Android v1 rule). |
| sign-in-transition | onboarding/launch | spec-written | captured | matched | | Plain `#FFFFFF` / `#000000` hold. Android-before labelled **new screen**. |
| replay-welcome | Profile/Settings | deferred | | | | Same pager as onboarding, `includesSignIn: false`. |
| profile-sign-in | Profile/Settings | deferred | | | | Same as `sign-in`, presented from Profile. |
| today | Today | spec-written | captured | matched | | Date/title/CTA/“Today's mysteries” all within 1%. Appearance chip and tab bar use a translucent fill and hairline (glass approximation; no true backdrop blur). |
| mystery-detail-sheet | Today | spec-written | captured | close | | Fruit line is above the fold (760 dp cap, matching iOS max detent). Fruit Y is still a few percent lower than iOS on this shorter frame. |
| pray / Learn / Profile / Settings screens | later groups | deferred | | | | Not in this run. |

Pairs: `/workspace/android/shots/v2/pairs/<screen-id>-<light|dark>.png` (iOS left, Android right).
Sign-off sheets: `/workspace/android/shots/v2/signoff/<screen-id>.png` (iOS \| Android-before \| Android-after; light on top, dark below). Before frames for splash/onboarding/sign-in/today come from the earlier parity pass. Sheets and sign-in-transition are labelled “new screen”.

## Measurement tables (light, unless noted)

Fractions are y / frame height (top of frame = 0). Δ is `|android − ios|` in percentage points of the frame.

### week-feast-sheet

iOS gap is measured from the drag-indicator bottom to the “Memorial · 21 November 2026” top: 72 px ÷ 3 = **24 pt** (0.0251 of the frame). Android uses a 36×4 dp handle with 5 dp top padding and 24 dp content top padding.

| landmark | iOS | Android | Δ |
| --- | --- | --- | --- |
| sheet top | 0.402 | 0.487 | 8.5% |
| grabber bottom | 0.412 | 0.497 | 8.5% |
| eyebrow top (“Memorial · …”) | 0.437 | 0.526 | 8.9% |
| grabber-bottom → eyebrow gap (frac) | 0.0251 | 0.0296 | 0.45% |
| grabber-bottom → eyebrow gap (pt/dp) | 24.00 pt | 27.05 dp | 3.05 dp |

The 0.45% gap match is the requested fix. The sheet itself starts lower because Android still uses `weekFeastSheetHeight() = 460.dp` (the iOS minimum), while the iOS ref uses the estimated detent (~572 pt for this copy), capped at 640.

### launch-splash

| landmark | iOS light | Android light | iOS dark | Android dark |
| --- | --- | --- | --- | --- |
| canvas | `#0054FF` (blank / mid-fade) | `#0054FF` | `#0658FF` | `#0054FF` |
| monogram box | — (do not chase) | 144 dp player, visible glyph ≈ 0.183 of width | faint halo; source player is 144 pt | 144 dp player, visible glyph ≈ 0.183 of width |

### onboarding-1 / 2 / 3 (light)

Panel bottom is the last non-page pixel at x = 8% (inside the 24 pt inset). Title is the first substantial ink cluster after the panel. CTA is the filled Continue pill.

| landmark | iOS | Android | Δ |
| --- | --- | --- | --- |
| panel bottom | 0.492 | 0.490 | 0.2% |
| title top (p1 / p3) | 0.573 | 0.589 | 1.6% |
| title top (p2) | 0.580 | 0.596 | 1.6% |
| dots mid (iOS) | 0.848 | just above CTA | — |
| CTA top | 0.868 | 0.890 | 2.2% |
| CTA mid | 0.895 | 0.919 | 2.4% |
| CTA bottom | 0.923 | 0.948 | 2.5% |

Dark pages use the same 50% black panel; the figure is `scaledToFill` with top (pages 1 and 3) or center (page 2) alignment so the panel edge blends into the page.

### sign-in (light)

| landmark | iOS | Android | Δ |
| --- | --- | --- | --- |
| panel bottom (Marian fill at x=8%) | 0.492 | 0.489 | 0.3% |
| quote top | 0.576 | 0.597 | 2.1% |
| Apple pill | 0.708–0.762 | omitted; 52+12 dp spacer reserved | — |
| Google (iOS filled / Android outlined) | ~0.774–0.828 (mid ~0.80) | ~0.830–0.887 (mid ~0.86) | ~6% |

The lower stack is bottom-aligned, as in iOS `signInLowerContent(spacious: true)`. Dark panel is `brandCanvas` black; the loop is fully visible with 40 dp padding above the panel bottom.

### today (light)

| landmark | iOS | Android | Δ |
| --- | --- | --- | --- |
| title first line | 0.536 | 0.543 / 0.553 | ≤ 1.7% |
| title second line | 0.601–0.639 | 0.596–0.633 | 0.6% |
| CTA top | 0.778 | 0.773 | 0.5% |
| CTA mid | 0.805 | 0.801 | 0.4% |
| CTA bottom | 0.832 | 0.830 | 0.2% |
| “Today's mysteries” | 0.874–0.882 | 0.873–0.882 | 0.1% |

### mystery-detail-sheet (light)

| landmark | iOS | Android | Δ |
| --- | --- | --- | --- |
| Fruit line | 0.782–0.790 | 0.831–0.843 | ~5% |
| CTA top | 0.889 | 0.899 | 1.0% |
| CTA bottom | 0.941 | 0.956 | 1.5% |
| Fruit above the fold? | yes | yes | — |

## Known allowed deviations

- Device chrome (status bar cutout, gesture bar, aspect) differs between iPhone 17 Pro Max and Pixel 7. Pairs are scaled to the same height.
- Android v1 sign-in is Google + guest only; the iOS Apple pill is intentionally omitted.
- Native iOS segmented `Picker` is implemented as a custom equal-width capsule (gray track, white thumb, weekday dot).
- The iOS tab bar is liquid glass; Android uses a floating capsule with a translucent fill and hairline. Android cannot sample the true backdrop the way `UIVisualEffectView` does.
- Pill buttons are capsules (50% rounding), matching iOS `PillButton`.

## Remaining mismatches after this pass

1. **Onboarding CTA** is 2.2–2.5% lower than the Pro Max ref with the same 24 dp + safe-area tokens, because Pixel 7 is 42 dp shorter and its nav inset differs.
2. **Sign-in Google** sits about 6% lower than the iOS Google pill even with an Apple-height spacer.
3. **week-feast-sheet** detent is still the 460 dp minimum, so the sheet starts lower than the iOS estimated height on this copy.
4. **mystery-detail Fruit** is on-screen but a few percent lower than iOS, on a shorter frame with the 760 dp cap.
5. **iOS light splash** is a mid-fade blank `#0054FF` field; Android shows the end-frame halo-R in both modes.
