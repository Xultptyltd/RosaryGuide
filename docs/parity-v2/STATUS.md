# Visual parity status (Steps 2–3, gap-closing recapture)

Reference: `/workspace/ios-parity-refs-v2/` (iPhone 17 Pro Max, 3×, 1320×2868 px = 440×956 pt, Dynamic Type Large, status bar 9:41, captured 17 Nov 2026 Australia/Perth).
Android captures: Pixel 7 AVD `RosaryGuide_Pixel7` (1080×2400), `en-AU`, `clock_date=2026-11-17`. Light onboarding was recaptured with **demo mode off** so a hidden status bar is actually hidden. Other screens use demo-mode clock 9:41.
pt and dp are 1:1 at mdpi. iOS PNG measurements are pixels ÷ 3.

This group is still **onboarding/launch** and **Today** only. Pray, Learn, and Profile/Settings are deferred.

`intention-icon-picker` is **not** in the live iOS editor. It stays removed.

Status values: `spec-written` · `captured` · `matched` · `mismatch` · `deferred` · `user-approved`.

| screen-id | group | spec | captured | matched | user-approved | notes |
| --- | --- | --- | --- | --- | --- | --- |
| launch-splash | onboarding/launch | spec-written | captured | matched | | Marian blue `#0054FF` both modes, halo R monogram. |
| onboarding-1 | onboarding/launch | spec-written | captured | matched | | Light status bar hidden (demo mode off + `BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE`). Image bleeds to y=0. Capsule Continue. |
| onboarding-2 | onboarding/launch | spec-written | captured | matched | | Same treatment as onboarding-1. |
| onboarding-3 | onboarding/launch | spec-written | captured | matched | | Begin is a filled capsule. Light status bar hidden. |
| sign-in | onboarding/launch | spec-written | captured | mismatch | | Panel now bleeds under the status bar; Google/guest are capsules. **No Apple button** (Android v1 rule). Dark panel is black (`brandCanvas`), matching iOS. Side gutters at the status-bar corners still show the page background, as on iOS. |
| sign-in-transition | onboarding/launch | spec-written | captured | matched | | Plain `#FFFFFF` / `#000000` hold. Android-before labelled **new screen**. |
| replay-welcome | Profile/Settings | deferred | | | | Same pager as onboarding, `includesSignIn: false`. |
| profile-sign-in | Profile/Settings | deferred | | | | Same as `sign-in`, presented from Profile. |
| today | Today | spec-written | captured | mismatch | | Hero uses focus y=0.28; title uses tight 1.02 line-height with `includeFontPadding=false`; monochrome appearance chip; “Today's mysteries” (strong section label) sits above the tab bar at the same frame-relative position as iOS (~87.4%). CTA/title are within ~5 dp of the iOS frame ratio. Remaining: tab bar is not liquid glass; appearance chip is opaque rather than glass. |
| week-feast-sheet | Today | spec-written | captured | matched | | Both themes open from a fresh launch (`debug_nonce` + remount). Gold crown, 460 dp detent starting under the hero, grouped/black fill, 20 dp corners, “Explore this feast” is a filled secondary capsule (black/light, white/dark) pinned at the bottom. Android-before labelled **new screen**. |
| mystery-detail-sheet | Today | spec-written | captured | mismatch | | Both themes open. Correct Agony in the Garden plate (`mysteryPlateDrawableId`), “First mystery · Sorrowful Mysteries”, filled “Pray this decade” capsule pinned with the pager dots. Fruit line (`Fruit` + fruit) is implemented but sits just below the fold under the pinned footer on Pixel 7 — scroll to see it. Android-before labelled **new screen**. |
| pray / Learn / Profile / Settings screens | later groups | deferred | | | | Not in this run. |

Pairs: `/workspace/android/shots/v2/pairs/<screen-id>-<light|dark>.png` (iOS left, Android right).
Sign-off sheets: `/workspace/android/shots/v2/signoff/<screen-id>.png` (iOS \| Android-before \| Android-after; light on top, dark below). Before frames for splash/onboarding/sign-in/today come from the earlier parity pass. Sheets and sign-in-transition are labelled “new screen” (they did not exist in that form in the e632195 APK).

Known allowed deviations (all screens):

- Device chrome (status bar cutout, gesture bar, aspect) differs between iPhone 17 Pro Max and Pixel 7. Pairs are scaled to the same height.
- Android v1 sign-in is Google + guest only; the iOS Apple pill is intentionally omitted.
- Native iOS segmented `Picker` is implemented as a custom equal-width capsule (gray track, white thumb, weekday dot).
- The iOS tab bar is liquid glass; Android uses a custom floating capsule (selected `#0054FF` / `#7DA8FF`).
- Pill buttons are capsules (50% rounding), matching iOS `PillButton`, not 20 dp rounded rects.

## Remaining mismatches after this gap-closing pass

1. **Pixel 7 vs iPhone 17 Pro Max** aspect, status-bar icons (3G vs Dynamic Island / cellular), and home indicator will never be pixel-identical. Custom type, colour, copy, and layout are the comparison target.
2. **Tab bar** is a custom capsule but is not a pixel copy of iOS liquid glass (blur, highlight, metrics).
3. **Appearance chip** uses a monochrome 12 dp sun/moon on an opaque white/translucent fill, not iOS floating glass.
4. **Mystery-detail fruit line** is implemented to match `MysteryFruitLine` (hairline + “Fruit” medium dim + fruit body ink) but sits just below the visible fold under the pinned footer on this 914 dp frame; the scripture and reference are fully visible.
5. **Today CTA / title** land within about 5 dp of the iOS position when expressed as a fraction of the frame (CTA ~77.3% vs 77.8%, title ~55.3% vs 54.7%). Absolute Y differs because Pixel 7 is 42 dp shorter than the iPhone 17 Pro Max reference; the first-screen composition (including “Today's mysteries”) was kept, which is what iOS shows on this content.
