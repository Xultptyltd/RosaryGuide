# Visual parity status (23 Nov 2026, Profile/Settings approved)

Reference: `/workspace/ios-parity-refs-v2/` (iPhone 17 Pro Max, 3×, 1320×2868 px = 440×956 pt, Dynamic Type Large, status bar 9:41, captured 17 Nov 2026 Australia/Perth).
Android captures for onboarding/Today: Pixel 7 AVD `RosaryGuide_Pixel7` on the Mac (1080×2400, 2.625×, ≈411.4×914.3 dp), `en-AU`, `clock_date=2026-11-17`, demo-mode clock 9:41. Light onboarding is captured with **demo mode off** so a hidden status bar stays hidden.
Pray-flow frames in this pass were recorded with **Roborazzi** because the Mac emulator was still unreachable. The harness now injects the measured Pixel 7 system insets (statusBars 52.57 dp, navigationBars 24 dp), draws a plain 9:41 / 3G status strip and a 108×4 dp gesture pill, and feeds the insets through Compose `WindowInsetsHolder` so layouts respond as on a device. Frames are 1078×2399. Recapture on the Mac emulator before calling any Pray screen `matched`.
The harness was validated against the approved Mac captures: today-light title 0.5429 vs 0.5440 (Δ 0.11%); onboarding-1 title/CTA within ~0.02%.
pt and dp are 1:1 at mdpi. iOS PNG measurements are pixels ÷ 3. A screen is marked `matched` only when the measured frame fractions agree within about 2%.

Onboarding/launch, Today, the **Pray flow** group, the **Learn** group (including walkthrough 1–5), and the **Profile/Settings** group are **user-approved**. Today, Learn, and `rosary-settings-sheet` were re-approved 23 Nov 2026, 11:29 Australia/Perth with the official `SectionBand` separators; the Profile/Settings screens were approved at the same time. Status stays `close` until a Mac Pixel 7 emulator recapture; do not treat approval as `matched`. Specs: `docs/parity-v2/profile-settings.md`, `docs/parity-v2/feasts.md`. The **Feasts** group (hub, feast detail, related prayers, patronages, scripture) is captured and `close` as of 23 Nov 2026, afternoon Australia/Perth, with no user approval yet. The already-approved Today `week-feast-sheet` was not recaptured.

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

| today | Today | spec-written | captured | close | user-approved | Re-rendered so dark mode uses night hero art. The harness had scoped `+night` to Pray/Learn stems, so the previous Roborazzi Today dark loaded the light drawable (washed grey-white band, no fade to black). Night hero now matches the approved Mac frame and iOS (hero-band average ~103 vs Mac 103 and iOS 102). Everything above the tab bar matches the approved Mac composition aside from the drawn Roborazzi 9:41 / 3G strip (Mac has real system icons; dark frame is 1076×2396). A 90 dp full-width scroll-edge scrim (transparent → page background) sits behind the floating tab, approximating the iOS 26 bottom `scrollEdgeEffect` that iOS leaves visible on tab roots. That removes the bright marble slivers in the 20 dp side margins. Light Today content above the tab is unchanged (rms 0.0 vs the previous Roborazzi). Recaptured 22 Nov 21:12 Australia/Perth for a 1-physical-pixel `Hairline` token: only the week-row dividers and the tab-capsule stroke width changed (light rms 0.017, ~0.09% of pixels). Layout, type, and night hero are unchanged. Re-approved 23 Nov 2026, 9:03 Australia/Perth with the production `GuideTabBar` and 1 px `Hairline` dividers. Re-approved again 23 Nov 2026, 11:29 Australia/Perth with official full-bleed `SectionBand` separators before “Upcoming feast days” and “This week” (below the first viewport). 1 px in-group week-row hairlines are unchanged. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| mystery-detail-sheet | Today | spec-written | captured | matched | user-approved | Fruit and CTA within 2%. Fruit is above the fold (760 dp cap). Sheet top is 3.3% higher because both sides cap at 760 on different frame heights (see table). |
| pray-* / rosary-settings-sheet | Pray flow | spec-written | captured | close | user-approved | Roborazzi with Pixel 7 system chrome (Mac still offline). Typography and spacing retuned to iOS TypeRole / Space this pass; see `docs/parity-v2/pray-typography.md` and the typography table below. Still `close` until a Mac recapture. |
| pray-opening | Pray flow | spec-written | captured | close | user-approved | Roborazzi + insets. Body pitch 31.23 dp vs iOS 31.00 pt (Δ 0.23). Header progress is 12 pt medium (`progressLabel`), not 17. Next CTA bottom Δ 0.54%. Bead-header language control stays a 36 dp custom capsule. |
| pray-intention-step | Pray flow | spec-written | captured | close | user-approved | Roborazzi + insets. Title-to-row ink gap Δ −0.19 dp after removing an extra 4 dp pad. Title Δ 0.41%; Next CTA bottom Δ 0.85%. |
| pray-mystery-plate | Pray flow | spec-written | captured | close | user-approved | Roborazzi + insets. Scripture pitch 31.24 dp vs iOS 31.00 pt (Δ 0.24). Eyebrow→title ink gap Δ 0.43 after first-baseline alignment of I / JOYFUL. Plate art / crop / inset unchanged. Title Δ 0.50%; Fruit last ink Δ 0.49%. Still Roborazzi — recapture on the Mac before `matched`. |
| pray-hail-mary-bead | Pray flow | spec-written | captured | close | user-approved | Roborazzi + insets. Body pitch Δ 0.24; paragraph b2b Δ 0.10; title→body ink Δ 0.43. CTA bottom Δ 0.54%. |
| pray-decade-end | Pray flow | spec-written | captured | close | user-approved | Roborazzi + insets. Body pitch Δ 0.24; title→body ink Δ 0.38. Fatima wraps one line earlier on the 412 dp frame. CTA bottom Δ 0.54%. |
| pray-final-prayers | Pray flow | spec-written | captured | close | user-approved | Roborazzi + insets. Body pitch Δ 0.24; paragraph b2b Δ 0.10. Hail Holy Queen wraps earlier on the narrower frame. CTA bottom Δ 0.54%. |
| pray-completion | Pray flow | spec-written | captured | close | user-approved | Roborazzi + insets. Quote pitch 21.71 vs 21.67 (Δ 0.04); attribution is 12 pt caption + tracking 0.8 (was 15 pt). Hero crop / fade unchanged. Title Δ 1.44%; tick Δ 1.88%. Still Roborazzi — recapture on the Mac before `matched`. |
| pray-michael | Pray flow | spec-written | captured | close | user-approved | Roborazzi + insets. Body pitch 30.10 vs 30.00 (Δ 0.10). Full-width language capsule is now 44 dp (`segmentedControlHeight`); Latin→control b2b is still 2.05 dp short, control→body 1.38 dp short (UIKit large segmented padding). Title Δ 1.26%; Done bottom Δ 0.85%. |
| rosary-settings-sheet | Pray flow | spec-written | captured | close | user-approved | Roborazzi + insets. In-card row pitch 56.38 dp vs iOS 56 pt (Δ 0.38). Rows use `bodyPray` 16 / 19.52. Grouped inset cards, M3 Done, and M3 switches unchanged. Title Δ 1.75%, sheet edge Δ 1.53%. Re-approved 23 Nov 2026, 11:29 Australia/Perth with official `SectionBand` separators between the three settings groups, shared with `settings-rosary`. In-group hairlines unchanged. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| pray-replace-dialog | Pray flow | spec-written | captured | close | user-approved | Roborazzi + insets. Copy matches; title Δ 1.28%. Dialog surface is untinted (`tonalElevation = 0`). Material 3 alert (side-by-side accent actions) vs iOS stacked red “Replace saved place” / black Cancel — kept as a native M3 swap. |
| learn | Learn | spec-written | captured | close | user-approved | Roborazzi + insets. Custom large title: cap 128.0 dp vs iOS 127.7 (Δ 0.3); baseline 150.9 vs 150.7. Soft Marian-blue `AppPageBackground` wash in light and dark. Production `GuideTabBar` (opaque capsule, hairline, light-mode shadow, 20/10 dp margin) is used in the app and the harness; the old `ParityTabBar` is gone. Dark fill is opaque so labels no longer read through the bar. Intro icon is an outlined `book.closed` in a 56 dp accent-tint tile (foot/proportions still shy of SF). Sorrowful crown is unclipped; iOS still overflows the circle more. Tab and list hairlines are now 1 physical pixel (`Hairline.thickness`). Still `close` until a Mac recapture. User approved 23 Nov 2026, 9:03 Australia/Perth. Re-approved 23 Nov 2026, 11:29 Australia/Perth with official `SectionBand` separators after the intro, mysteries, prayers tiles, and questions (before Pray today), matching iOS `PrayHubView`. Search results, walkthrough, mystery-detail, all-prayers, and rosary-prayers were left alone (no iOS bands). Still `close` until a Mac recapture; do not treat approval as `matched`. |
| learn-faq | Learn | spec-written | captured | close | user-approved | Scrolled to Common questions with a compact “Learn” title; first question expanded. Ambient wash behind the compact title. Answer pitch 24.76 vs 24.67 (Δ 0.10). Wraps earlier on the 412 dp frame. User approved 23 Nov 2026, 9:03 Australia/Perth. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| learn-search | Learn | spec-written | captured | close | user-approved | Query `Hail`, flat list, search icon + filled-circle clear (`xmark.circle.fill`). Ambient wash. The search field is `cardSurface(Grouped)` (white in light, `#1C1C1E` in dark) with a 1 px `cardSurfaceStroke` rim — the same as the Learn hub field, and different from the grey plain-page field on all-prayers. User approved 23 Nov 2026, 9:03 Australia/Perth. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| learn-search-empty | Learn | spec-written | captured | close | user-approved | Query `zzzznotfoundxyz`. Copy matches. Field → message ink Δ −0.24. Ambient wash. User approved 23 Nov 2026, 9:03 Australia/Perth. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| learn-mystery-detail | Learn | spec-written | captured | close | user-approved | Ambient wash + milky circular back. Hero uses `heroWideFocus` so Mary, Joseph and the child are fully framed (slightly looser than iOS on the narrower Pixel 7). Row titles are `bodyPray` 16; fruit is `captionPray` 12; 28 dp plain surface badge. “The Presentation in the Temple” fits on one line. Intro pitch 27.81 vs 27.67 (Δ 0.14); title→body ink Δ −0.33. The “Pray these mysteries” CTA is a scroll-end button, not a sticky footer; at the default (top) scroll it sits behind the floating tab like iOS. Dark labels no longer read through the bar, and the earlier thick blue strip below the tab is gone (content is clipped at the 10 dp bottom margin). A 90 dp full-width scroll-edge scrim behind the tab fades the remaining blue CTA corner slivers into the page background. User approved 23 Nov 2026, 9:03 Australia/Perth. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| rosary-prayers | Learn | spec-written | captured | close | user-approved | Ambient wash + milky circular back. Grouped white cards, strong section labels, ×3/×10 captions. User approved 23 Nov 2026, 9:03 Australia/Perth. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| all-prayers | Learn | spec-written | captured | close | user-approved | Plain `palette.bg` (no wash, matching iOS `guidePlainPageBackground`). Search chrome + filled-circle clear. Row pitch 73.14 vs 73.00 dp (Δ 0.14). Milky circular back. Row separators use `Hairline.thickness` (1 physical pixel) and `palette.hair` (UIKit `separator`: light `#3C3C43` @ 0.29, dark `#545458` @ 0.60), replacing the previous 1 dp `HorizontalDivider`. Light search field is `cardSurface(Plain)` `#F2F3F7` with no border, matching the iOS ref; dark stays `surface` `#1C1C1E`. User approved 23 Nov 2026, 9:03 Australia/Perth. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| prayer-reader | Learn | spec-written | captured | close | user-approved | Ambient wash + milky circular back. Body pitch 30.10 vs 30.00 (Δ 0.10). 44 dp language capsule. Latin is sans `themeSummary`. User approved 23 Nov 2026, 9:03 Australia/Perth. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| walkthrough-1 | Learn | spec-written | captured | close | user-approved | Matches iOS `OnboardingDots` (active 18×6 capsule, inactive 6×6, spacing `Space.sm`). Panel uses the source `SignInLayout` formula plus the `OnboardingPanel` top black fade (`statusBars + Space.xl`) and a `Spacer(lg)` + weighted centered text + footer clearance, so the title sits farther under the art. 1.018 scale only when `!reduceMotion`. Light hides the status bar; dark shows it. Close is a 40 dp milky chip (light `#F4F4F5`, dark `#636366` @ 0.60 so it stays a visible grey disk on marble and on the black panel) with a hairline stroke and `palette.ink` X, 48 dp hit target, padding `gutter+sm` / `xs`. Art crop is still slightly tighter than iOS on the Pixel 7 aspect. Still Roborazzi — recapture on the Mac before `matched`. User approved 23 Nov 2026, 9:03 Australia/Perth. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| walkthrough-2 | Learn | spec-written | captured | close | user-approved | Same chrome as walkthrough-1. Page 2 now uses iOS `MysteryJoyful` (Madonna and Child, top-aligned) instead of the Annunciation asset. In light, the close chip is a flat `#F4F4F5` fill — iOS `guideFloatingGlass` samples the dark art and reads darker there, which Compose cannot match without blur. User approved 23 Nov 2026, 9:03 Australia/Perth. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| walkthrough-3 | Learn | spec-written | captured | close | user-approved | Same chrome as walkthrough-1 (dots, fade, title gap, close, status-bar rule). User approved 23 Nov 2026, 9:03 Australia/Perth. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| walkthrough-4 | Learn | spec-written | captured | close | user-approved | Same chrome as walkthrough-1 (dots, fade, title gap, close, status-bar rule). User approved 23 Nov 2026, 9:03 Australia/Perth. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| walkthrough-5 | Learn | spec-written | captured | close | user-approved | Last page; Continue becomes Begin Rosary + Done. Footer clearance adds `minHitTarget + Space.sm` as in iOS `lastPageControlsHeight`. Same chrome as walkthrough-1. User approved 23 Nov 2026, 9:03 Australia/Perth. Still `close` until a Mac recapture; do not treat approval as `matched`. |
| replay-welcome | Profile/Settings | spec-written | captured | close | user-approved | Same pager as approved onboarding-1 (`includesSignIn: false`). Light hides the status bar. Still `close` until a Mac recapture; do not treat as `matched`. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| profile-sign-in | Profile/Settings | spec-written | captured | close | user-approved | Same Sign-in screen as approved `sign-in` (Google + guest, no Apple). Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| profile | Profile/Settings | spec-written | captured | close | user-approved | Signed-in empty hub, 17 Nov 2026. Profile-only large title (top 122.7 dp vs iOS 118.3 pt), milky gear, compact rhythm card, empty-intentions heart card, 96 dp papal photo, Marian wash, floating `GuideTabBar` + 90 dp scrim. See `docs/parity-v2/profile-settings.md`. Still `close` until a Mac recapture. Official `SectionBand` (`verticalSpacing` 0) before Holy Father’s intention. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| profile-backup | Profile/Settings | spec-written | captured | close | user-approved | Guest hub scrolled so the backup card is on screen. Compact centred “Profile” + gear sit below the 3G strip, with a downward scrim so week dots fade underneath. Headline is “not backed up yet”. Still `close` until a Mac recapture. Official `SectionBand` (`verticalSpacing` 0) before the backup card. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| all-intentions | Profile/Settings | spec-written | captured | close | user-approved | Title “All intentions”, wash, chevron-in-chip back, 40 dp white (dark: grey) more chip with a bold horizontal ellipsis, official category marks, row pitch within 1 dp of iOS. Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| archived-intentions | Profile/Settings | spec-written | captured | close | user-approved | Archived list. Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| intention-detail | Profile/Settings | spec-written | captured | close | user-approved | Detail for a single intention. Still `close` until a Mac recapture. Official `SectionBand` between notes and the details table. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| intention-editor | Profile/Settings | spec-written | captured | close | user-approved | Add/edit intention. No icon picker (not in the live iOS editor). Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| papal-intention-detail | Profile/Settings | spec-written | captured | close | user-approved | Official Pope Leo wide art. Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| prayer-journey-milestones | Profile/Settings | spec-written | captured | close | user-approved | Journey milestones (not on the Profile hub). Still `close` until a Mac recapture. Official `SectionBand` before each milestone category. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| prayer-journey-history | Profile/Settings | spec-written | captured | close | user-approved | Journey history. Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| journey-day-sheet | Profile/Settings | spec-written | captured | close | user-approved | Day sheet. Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| settings | Profile/Settings | spec-written | captured | close | user-approved | Compact bar, flat `palette.bg`, labels outside grouped cards, System appearance, 11-day guest backup, trailing values, hairline dividers, external-link arrows. Backup headline wraps on Pixel 7’s narrower width. Switch accent is Marian (allowed). Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| settings-rosary | Profile/Settings | spec-written | captured | close | user-approved | Customise rosary. Marian accent switches (allowed). “Bible translation” value is now trailing. Still `close` until a Mac recapture. Official `SectionBand` between the three groups. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| settings-reset-rosary | Profile/Settings | spec-written | captured | close | user-approved | Reset confirm. Dialog actions sit side by side (allowed M3). Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| settings-notifications | Profile/Settings | spec-written | captured | close | user-approved | Notifications. Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| settings-app-icon | Profile/Settings | spec-written | captured | close | user-approved | Available icons + check, plus a rounded home-screen preview card (not a bezeled iOS device frame). Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| settings-legal-terms | Profile/Settings | spec-written | captured | close | user-approved | Terms of service. Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| settings-legal-privacy | Profile/Settings | spec-written | captured | close | user-approved | Privacy. Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| settings-acknowledgements | Profile/Settings | spec-written | captured | close | user-approved | Acknowledgements. Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| settings-license | Profile/Settings | spec-written | captured | close | user-approved | First Android license entry (AndroidX Core), not iOS Abseil — the dependency sets differ. Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| settings-report-problem | Profile/Settings | spec-written | captured | close | user-approved | Report-a-problem chooser. Still `close` until a Mac recapture. Dark dialog actions use `actionForeground` `#7DA8FF` (6.1:1 on the M3 dark dialog fill, WCAG AA). User approved 23 Nov 2026, 11:29 Australia/Perth. |
| settings-mail-unavailable | Profile/Settings | spec-written | captured | close | user-approved | Mail-unavailable alert; M3 actions side by side (allowed). Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| settings-clear-history | Profile/Settings | spec-written | captured | close | user-approved | Clear-history confirm; M3 actions side by side (allowed). Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| delete-intention | Profile/Settings | spec-written | captured | close | user-approved | Confirm-delete dialog on intention detail. M3 side-by-side actions (allowed). Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| journey-prayer-sheet | Profile/Settings | spec-written | captured | close | user-approved | Journey prayer half-sheet. Still `close` until a Mac recapture. User approved 23 Nov 2026, 11:29 Australia/Perth. |
| feasts | Feasts | spec-written | captured | close | | Hub rewrite: scope capsules, week strip + handle, accent selected day, SectionBand agenda, no search. Roborazzi +night, 17 Nov 2026. Still `close` until a Mac recapture. Not user-approved. |
| feast-detail | Feasts | spec-written | captured | close | | Presentation of Mary. Width-scaled 330 pt hero (308 dp on Pixel 7) just below the nav, local milky back chip + 84 dp title centre. Still `close` until a Mac recapture. Not user-approved. |
| feast-related-prayers | Feasts | spec-written | captured | close | | Secondary page off feast detail, width-scaled 238 pt hero (222 dp on Pixel 7), first prayer expanded. Still `close` until a Mac recapture. Not user-approved. |
| feast-patronages | Feasts | spec-written | captured | close | | Secondary page, Marian default patronages. Still `close` until a Mac recapture. Not user-approved. |
| feast-scripture | Feasts | spec-written | captured | close | | Secondary page, Zechariah / Matthew passages. Still `close` until a Mac recapture. Not user-approved. |
| feasts-empty | Feasts | spec-written | captured | close | | Empty copy only; no iOS ref, not a sign-off pair. Still `close`. Not user-approved. |

Pairs: `/workspace/android/shots/v2/pairs/<screen-id>-<light|dark>.png` (iOS left, Android right).
Sign-off sheets: `/workspace/android/shots/v2/signoff/<screen-id>.png` (iOS \| Android-before \| Android-after; light on top, dark below). Before frames for splash/onboarding/sign-in/today come from the earlier parity pass. Sheets and sign-in-transition are labelled “new screen”.
Zoomed 2× baseline-guide crops (Pray typography pass): `/workspace/android/shots/v2/signoff/zoom/<screen-id>.png`.

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
| pray-completion | tick top | 0.5478 | 0.5290 | 1.88% | leftover fill + fade; still within 2% |
| pray-completion | ROSARY COMPLETE top | 0.6077 | 0.5919 | 1.58% | 6 pt under the tick slot, `includeFontPadding = false` |
| pray-completion | title “Joyful Mysteries” top | 0.6342 | 0.6198 | 1.44% | 16 dp bottom inset (was 6) so Saint Michael clears the gesture pill |
| pray-completion | Done top | 0.8431 | 0.8441 | 0.10% | |
| pray-completion | Done bottom | 0.8971 | 0.9008 | 0.37% | |
| pray-completion | Saint Michael bottom | 0.9641 | 0.9712 | 0.71% | breathing room above the Pixel 7 gesture pill |
| pray-michael | title top | 0.1402 | 0.1276 | 1.26% | labels match the iOS source exactly |
| pray-michael | Done bottom | 0.9474 | 0.9558 | 0.85% | |
| rosary-settings-sheet | sheet edge | 0.0753 | 0.0600 | 1.53% | sized to iOS `.large` detent |
| rosary-settings-sheet | “Customise rosary” | 0.1126 | 0.1301 | 1.75% | M3 text Done; M3 accent switches |
| rosary-settings-sheet | last card bottom → Reset top | ~0.061 | 0.0759 | 1.49% | iOS gap is ~6% of the frame (card edge to Reset); Android is 7.6% |
| pray-replace-dialog | title | 0.4132 | 0.4260 | 1.28% | copy matches; Material vs UIKit chrome |

### Pray typography (equal-scale pt/dp, 22 Nov 2026 typography pass)

Frame-fraction landmarks above are unchanged from the previous visual pass (art, chrome, CTA positions). This pass retunes type size, line pitch, and spacing. Full role table: `docs/parity-v2/pray-typography.md`. Historical `RosaryType.body` / `headingPrimary` tokens used by approved Today and onboarding screens were left alone; Pray uses `*Pray` styles with typo line heights, `includeFontPadding = false`, and `LineHeightStyle` trim.

Body-only line pitch (CTA labels excluded). Target ≤ 0.5 sp.

| screen | metric | iOS (pt) | Android (dp) | Δ |
| --- | --- | --- | --- | --- |
| pray-opening | body pitch | 31.00 | 31.23 | 0.23 |
| pray-hail-mary-bead | body pitch | 31.00 | 31.24 | 0.24 |
| pray-hail-mary-bead | paragraph b2b | 54.00 | 54.10 | 0.10 |
| pray-decade-end | body pitch | 31.00 | 31.24 | 0.24 |
| pray-final-prayers | body pitch | 31.00 | 31.24 | 0.24 |
| pray-mystery-plate | scripture pitch | 31.00 | 31.24 | 0.24 |
| pray-mystery-plate | eyebrow → title (ink) | 21.67 | 22.10 | 0.43 |
| pray-completion | quote pitch | 21.67 | 21.71 | 0.04 |
| pray-michael | body pitch | 30.00 | 30.10 | 0.10 |
| pray-michael | Latin → language (b2b) | 57.67 | 55.62 | 2.05 |
| pray-michael | language → body (b2b) | 75.67 | 74.29 | 1.38 |
| pray-intention-step | title → first row (ink) | 60.00 | 59.81 | 0.19 |
| rosary-settings-sheet | in-card row pitch | 56.00 | 56.38 | 0.38 |

Wrapping can still differ: Pixel 7 is ~412 dp wide, the iPhone 17 Pro Max is 440 pt.

User approved every Pray-flow screen on 22 Nov 2026 (Australia/Perth), including the known remaining deltas (Saint Michael language-control gaps of 2.05 / 1.38 dp, Pixel 7 wrapping, native M3 swaps on the replace dialog and customise sheet, and Roborazzi rather than a Mac Pixel 7 recapture). Status stays `close` until that recapture; do not treat approval as `matched`.

In-flow Saint Michael (the optional closing *step*, toggle off by default) has no v2 iOS ref; `pray-michael` is the post-completion overlay. The scroll-to-continue morph’s collapsed (circle) state is now shown on `pray-mystery-plate` via `scrollPlateToEnd` and a plate end-spacer that includes `ScrollMorph.minimumRange`. There is no mid-lerp iOS ref to chase.

Visual review (22 Nov 2026, second sign-off pass): the mystery plate is unchanged from the prior pass (accepted). Completion hero art now fills the leftover edge to edge with the iOS crop and fade — figures are large and side-cropped, the lectern is gone, and the sculpture fades into the tick; Saint Michael has breathing room above the gesture pill. Customise “Reset to default” no longer sits on the last card; the last-card-to-Reset gap is 7.6% of the Pixel 7 frame (iOS ~6%), with 8 dp section gaps and 20 dp card corners. “No specific intention” is a taller rounded-rect card with a hairline; “Add intention” is a filled surface pill in both modes. The bead rail fits inside the margins on every bead step; the dark crucifix highlight is a large faint halo (pulse phase offset 0.72 so Roborazzi does not freeze on the tight burst). Language pickers are a custom Compose capsule with a raised thumb, not an M3 segmented control.

Remaining visual differences to be candid about: replace-dialog actions stay side-by-side M3 vs iOS stacked red/black; customise switches stay M3 blue vs iOS green; customise Done stays an M3 text button vs the iOS filled pill; “Bible translation” and its value sit tighter on the narrower Pixel 7 row than on the Pro Max; the completion light fade still finishes about 2% earlier than iOS (tick is 1.88% high, within budget); the language capsule thumb is a little more detached / shadowed than the iOS control, and the dark selected thumb is slightly lighter; plate side margins are still a hair tighter than iOS (Pixel 7 is narrower). Dark layouts for completion and the plate use the dark art, not the light-grey plate on black.

## Known allowed deviations

- Device chrome (status bar cutout, gesture bar, aspect) differs between iPhone 17 Pro Max and Pixel 7. Pairs are scaled to the same height.
- Android v1 sign-in is Google + guest only; the iOS Apple pill is intentionally omitted.
- Native iOS segmented `Picker` is implemented as a custom equal-width capsule (gray track, white or dark raised thumb). The Pray language control uses that same custom Compose capsule rather than an M3 segmented button row.
- The iOS tab bar is liquid glass; Android uses a floating capsule with margin, hairline, and (in light) a soft shadow. There is no backdrop blur, so the fill is opaque enough that scrolling labels do not read through as clutter. A 90 dp bottom scroll-edge scrim (transparent → page background) stands in for the iOS 26 `scrollEdgeEffect`, which iOS only hides at the top and leaves on at the bottom of tab roots.
- Pill buttons are capsules (50% rounding), matching iOS `PillButton`.
- Native M3 swaps (kept, not chased): customise switches use M3 accent rather than iOS system green; the replace dialog is a side-by-side M3 alert rather than iOS stacked red “Replace saved place” / black Cancel; customise Done is an M3 text button because iOS uses a native `toolbar` `confirmationAction`, not a custom `PillButton`.

## Walkthrough close and search-field pass (22 Nov 2026, 21:25 Australia/Perth)

The dark walkthrough close chip is now a mid-grey milky fill (`#636366` @ 0.60) with a light X, so it stays visible on the cream sculpture and as a filled disk on the black panel. A white veil, even at 0.28–0.32, lightened the marble and disappeared; this follows the sampled iOS ref colour. Light close chips were not changed.

The all-prayers light search field uses `cardSurface(Plain)` `#F2F3F7` and no border, matching the iOS ref (previously white with a 1 dp outline). Learn hub, learn-search, and learn-search-empty keep the grouped-page treatment: a white (light) / `#1C1C1E` (dark) capsule with a 1 px `cardSurfaceStroke` rim, which is what their iOS refs show. FAQ has no search field, so it was not recaptured.

The user's Mac (`8cb4ed56-4cb9-424d-a9cd-395e0f575f4a`) was probed again and is still unreachable, so there is no Pixel 7 AVD recapture and no APK install.

## Walkthrough and hairline pass (22 Nov 2026, 21:12 Australia/Perth)

Walkthrough-1…5 were re-laid to the iOS source (`OnboardingPageView` / `OnboardingDots` / `OnboardingPanel` / `SignInLayout` in `OnboardingView.swift`): capsule page indicator, top fade and larger title gap, milky close chip, and the light-only hidden status bar. Walkthrough-2 uses the iOS `MysteryJoyful` Madonna-and-Child art (top-aligned), not Annunciation.

Hairlines across the app now use a shared `Hairline.thickness` of `(1 / LocalDensity.current.density).dp` — 1 physical pixel, matching iOS `1/displayScale` pt — and list dividers use `palette.hair` (`UIColor.separator`). Card, field, glass, and tab-bar strokes changed width only; their colours were left as-is so approved fills stay put. `GuideSectionDivider` (the 8 dp decorative band) and the intention selected-row 1 dp accent border were not retargeted. Approved Today, Learn, and Pray frames were recaptured for this divider-only change (Today light rms 0.017; list-heavy sheets such as all-prayers move more pixels because both thickness and colour changed). Onboarding, week-feast-sheet, mystery-detail-sheet, launch-splash, and sign-in were not overwritten.

The user's Mac (`8cb4ed56-4cb9-424d-a9cd-395e0f575f4a`) was probed this pass and is still unreachable (desktop app offline), so there is no Pixel 7 AVD recapture and no debug APK in `~/Downloads`. Frames stay Roborazzi. Status stays `close`; do not mark Pray, Today, or Learn `matched`.

Approved onboarding still uses the older 8/7 dp circular dots; those screens were not opened. The iOS `Hairline()` SwiftUI view is still 1 pt in source; this pass follows the user's 1-physical-pixel request, which matches `AppTheme.Component.hairline = 1/displayScale`.

## Remaining mismatches after this pass

1. **launch-splash** cannot match the iOS reference PNGs within 2%, because those captures are mid-animation (light is a blank `#0054FF` field; dark is a beaded-halo mid-frame) while Android correctly holds the Lottie end-frame cream halo-R. The 144 dp player size already matches the source.
2. **week-feast-sheet** detent is still the 460 dp minimum, so the sheet starts lower than the iOS estimated height on this copy. User-approved as is.
3. **mystery-detail-sheet** sheet top is 3.3% higher on Pixel 7 because both sides cap the detent at 760 on frames of different height (914.3 dp vs 956 pt). Fruit and CTA are within 2%.
4. **Pray flow frames** are still Roborazzi, not Mac-emulator captures. Landmarks remain within 2% after this pass (plate title Δ 0.50%, Fruit last ink Δ 0.49%, completion title Δ 1.44%, tick Δ 1.88%, Saint Michael bottom Δ 0.71%). Recapture every Pray screen on the Mac Pixel 7 emulator before marking any of them `matched`, especially the Lottie tick on a real device, plate overflow/scroll-circle, and sheet/dialog chrome.
5. **Learn flow frames** are Roborazzi, not Mac-emulator captures. Large-title cap is 128.0 dp vs iOS 127.7; FAQ / walkthrough / prayer-reader / mystery intro body pitch is within 0.5 sp (typically Δ 0.10–0.14). Remaining designer-eye diffs: `book.closed` foot and proportions are not a perfect SF match; the dark Marian wash is a bit weaker than iOS; the Sorrowful crown sits inside the circle instead of overflowing it; walkthrough art is closer after the top fade and title-gap fix, but is still slightly tighter than iOS on the Pixel 7 aspect; wrapping still differs on the narrower 412 dp frame. See `docs/parity-v2/learn-typography.md`.
6. **Pray typography** is much closer (body pitch typically Δ 0.24 sp, most gaps within 1 dp) but two Saint Michael language-control gaps stay 2.05 / 1.38 dp short of UIKit's large segmented control, and wrapping still differs on the narrower Pixel 7. See `docs/parity-v2/pray-typography.md`.
