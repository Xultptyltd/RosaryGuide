# Visual parity status (Steps 2–3)

Reference: `/workspace/ios-parity-refs-v2/` (iPhone 17 Pro Max, 3×, 1320×2868 px = 440×956 pt, Dynamic Type Large, status bar 9:41, captured 17 Nov 2026 Australia/Perth).
Android captures: Pixel 7 AVD `RosaryGuide_Pixel7` (1080×2400), demo-mode clock 9:41, `en-AU`, `clock_date=2026-11-17`.
pt and dp are 1:1 at mdpi. iOS PNG measurements are pixels ÷ 3.

This run is time-boxed to **onboarding/launch** and **Today** only. Pray, Learn, and Profile/Settings are listed so later groups can tick the same grid. `replay-welcome` and `profile-sign-in` are Entry covers in the iOS README but are reached from Settings / Profile, so they are deferred to that group; visually they reuse `onboarding-*` and `sign-in`.

`intention-icon-picker` is **not** in the live iOS editor (`OfferView.swift:3131`, “not presented while icons are hidden”). The Android nested picker added in the IA pass has been removed.

Status values: `spec-written` · `captured` · `matched` · `mismatch` · `deferred` · `user-approved`.

| screen-id | group | spec | captured | matched | user-approved | notes |
| --- | --- | --- | --- | --- | --- | --- |
| launch-splash | onboarding/launch | spec-written | captured | matched | | Marian blue `#0054FF` both modes. Lottie/monogram is faint or already finished in some holds, as on iOS. |
| onboarding-1 | onboarding/launch | spec-written | captured | mismatch | | Layout, type, copy, and pill match. Light mode still shows the status bar (iOS hides it). Pixel chrome differs. |
| onboarding-2 | onboarding/launch | spec-written | captured | mismatch | | Same as onboarding-1 (status bar in light). |
| onboarding-3 | onboarding/launch | spec-written | captured | mismatch | | Same as onboarding-1 (status bar in light). |
| sign-in | onboarding/launch | spec-written | captured | mismatch | | Quote is 32 pt Instrument Sans; Google + guest + legal match. **No Apple button** (Android v1 product rule). |
| sign-in-transition | onboarding/launch | spec-written | captured | matched | | Plain `#FFFFFF` / `#000000` hold. |
| replay-welcome | Profile/Settings | deferred | | | | Same pager as onboarding, `includesSignIn: false`. |
| profile-sign-in | Profile/Settings | deferred | | | | Same as `sign-in`, presented from Profile. |
| today | Today | spec-written | captured | mismatch | | Hero, date, 50-pt title, set picker, CTA, appearance chip, floating tab bar, grouped `#F8F8FA`/`#000000` all landed. Remaining: Pixel vs Pro Max chrome/aspect, tab-bar material (not iOS liquid glass), mystery rail sits under the tab bar in the first viewport (same as iOS). |
| week-feast-sheet | Today | spec-written | captured | mismatch | | **Light captured** (Presentation of Mary, 21 November 2026, “Explore this feast”). **Dark hook failed** — the shot is Today without the sheet. |
| mystery-detail-sheet | Today | spec-written | captured | mismatch | | **Dark captured** (The Agony in the Garden, “Pray this decade”). **Light hook failed** — the shot is Today without the sheet. |
| pray / Learn / Profile / Settings screens | later groups | deferred | | | | Not in this run. |

Pairs: `/workspace/android/shots/v2/pairs/<screen-id>-<light\|dark>.png` (iOS left, Android right, same height, labelled).
Sign-off sheets: `/workspace/android/shots/v2/signoff/<screen-id>.png` (iOS \| Android-before \| Android-after; light on top, dark below). Before frames for most screens come from the earlier parity pass, because a first emulator batch captured a stuck splash.

Known allowed deviations (all screens):

- Device chrome (status bar cutout, gesture bar, aspect) differs between iPhone 17 Pro Max and Pixel 7. Pairs are scaled to the same height.
- Android v1 sign-in is Google + guest only; the iOS Apple pill is intentionally omitted.
- Native iOS segmented `Picker` is implemented as a custom equal-width capsule (gray track, white thumb, weekday dot) so it matches the iOS look more closely than an unstyled M3 `SegmentedButton`.
- The iOS tab bar is a custom floating capsule, not `UITabBar`. Android now uses a custom floating capsule too (selected `#0054FF` / `#7DA8FF`).

## Remaining mismatches this run could not fully close

1. **Light onboarding still shows the status bar.** iOS hides it (`statusBarHidden` when the scheme is light). `WindowInsetsController.hide(statusBars)` is in `OnboardingScreen`, but Pixel 7 / demo mode still painted 9:41 over the hero. Needs a follow-up (edge-to-edge hero + a more reliable hide, possibly `WindowInsetsController` + `WindowCompat.setDecorFitsSystemWindows`).
2. **`week-feast-sheet` dark and `mystery-detail-sheet` light** did not open from the debug intent after the activity was already on Today (`onNewIntent` delivered, but the `LaunchedEffect` did not present the sheet). Light week-feast and dark mystery-detail did capture. Follow-up: open the sheet from the intent in a way that retriggers after Home has composed, or drive a tap on the week row / rail card.
3. **Pixel 7 vs iPhone 17 Pro Max** aspect, status-bar icons (3G vs Dynamic Island / cellular), and home indicator will never be pixel-identical. Custom type, colour, copy, and layout are the comparison target.
4. **Tab bar** is a custom capsule but is not a pixel copy of iOS liquid glass (highlight, blur, metrics).
