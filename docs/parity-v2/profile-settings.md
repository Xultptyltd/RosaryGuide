# Profile / Settings — parity pass (RGA-4)

IA: `/workspace/android/ia/ia-map.md` §§6–7. Navigation follows that map: Profile hub (rhythm → Journey, intentions list / editor, papal detail, guest backup → sign-in, gear → Settings). Settings is a full-screen page (iOS `HomeSettingsDrawer` settles full-screen). Replay welcome is Onboarding page 0 with `includesSignIn: false`. Profile sign-in is the same Sign-in screen as onboarding (Google + guest, no Apple). `intention-icon-picker` is not in the live iOS editor and stays removed.

iOS refs: `/workspace/ios-parity-refs-v2`. Android frames: Roborazzi Pixel 7, light and dark (`+night`), clock 17 Nov 2026 so the week-dot “today” is Tuesday and the guest headline is “11 days” (earliest activity 6 Nov 2026).

## Screens in this group

Hub and auth: `profile`, `profile-backup`, `profile-sign-in`, `replay-welcome`.

Intentions and journey: `all-intentions`, `archived-intentions`, `intention-detail`, `intention-editor`, `delete-intention`, `papal-intention-detail`, `prayer-journey-milestones`, `prayer-journey-history`, `journey-day-sheet`, `journey-prayer-sheet`.

Settings: `settings`, `settings-rosary`, `settings-reset-rosary`, `settings-notifications`, `settings-app-icon`, `settings-legal-terms`, `settings-legal-privacy`, `settings-acknowledgements`, `settings-license`, `settings-report-problem`, `settings-mail-unavailable`, `settings-clear-history`.

No iOS refs (captured where a test exists, not sent as pairs): `settings-delete-account`, `settings-sign-out`, `settings-notifications-picker`, `archived-intentions-empty`, `profile-empty` (a duplicate of the empty signed-in `profile`).

Sign-off sheets: `/workspace/android/shots/v2/signoff/{stem}.png`. Pairs: `/workspace/android/shots/v2/pairs/`. 2× zoom crops: `/workspace/android/shots/v2/signoff/zoom/{stem}.png`.

## What was aligned (review pass, 23 Nov 2026)

- On `profile-backup`, the compact bar is overlaid below the status strip (44 dp, title and gear vertically centred at mid 74 dp). The 3G glyph no longer collides with the gear. A downward 90 dp scrim, the same treatment as the tab-bar edge fade and filled with `groupedBackground`, lets scrolled content (“Your intentions”, week dots) fade under the bar instead of peeking through.
- The Profile large “Profile” title is a Profile-only row (`statusBarsPadding` + 60 dp), not `GuideLargeTopAppBar`, so Learn and Feasts stay put. Title top is 122.7 dp vs iOS 118.3 pt (the ~4 dp status-inset difference); the rhythm card top is 198.1 dp vs iOS 194.7 pt.
- Back controls in this group use a chevron-in-chip (`chevronBack`), matching the approved Learn milky 40 dp chip shape but with an iOS-style chevron. The `GuideTopAppBar` default stays the Material arrow so approved Learn frames are unchanged.
- The All-intentions more control is a 40 dp white circle (dark: grey `#3A3A3C`), the same size as the back chip, with a bold horizontal ellipsis.
- Settings root content starts 36 dp below the bar (iOS `contentTop` 16 + `sectionGap − xl` 20). The “General” heading-to-rows gap is `sectionTitleGap` 20. First-section ink mid is 162.1 dp vs iOS 161.7 pt; Settings title mid 85.7 vs 85.3.
- Intention list rows use 10 dp vertical padding, a 16 dp icon gap and a 44 dp trailing control. All-intentions row pitch is 65.71 / 64.57 dp vs iOS 66.33 / 65.17 pt; the first icon top is 144.4 dp vs iOS 144.0 pt. Archived lists use the same horizontal ellipsis, not a vertical more.

## What was aligned (tightening pass)

- Profile large title collapses to a compact, centred 17 medium “Profile” with the trailing milky gear once you scroll (or immediately on the `profile-backup` capture).
- Settings is a plain white / black page. General, Help and About sit on the page with full-bleed `GuideSectionBoundary` bands (`sectionDivider` `#E3E4E8` in light, `surface` in dark, 8 dp bar with official endpoint art). Only the guest backup card is a filled rounded surface: `#F2F3F7` on Settings (`PageStyle.Plain`) and `surface` in dark.
- The back control on Settings and other plain pages is the milky circular chevron chip, filled `#F4F4F5` with a hairline rim in light so it reads on white. Learn / wash pages keep the approved white-92 chip.
- Settings row icons are outlined vectors standing in for the iOS SF Symbols (slider, half-circle, bell, app, exclamation bubble, lightbulb, sparkles, doc, hand, arrow-up-right).
- All intentions (and similar lists) use the official iOS category marks — purple church, sky-blue two people, mint hands-and-heart — at 0.8 of the accent circle, with a horizontal ellipsis trailing control.
- The App icon screen has a home-screen phone preview (selected Rosary Guide icon plus Calendar / Photos / Camera / Mail / Notes / Reminders / Clock placeholders).
- Rhythm past-day dots use the iOS `PrayerPreview` tokens: 24 dp marker frame, 12 dp inactive dots, 2 dp today ring with 1 dp inset, `strokeRegular` / `strokeStrong` opacities.
- `delete-intention` and `journey-prayer-sheet` are now captured. The prayer sheet uses `GuideHalfSheetHeader` typography (32 heading, 12 caption), the 56 dp mystery lily thumb, body fact rows, and “No specific intention”.
- The intention editor is a sheet with grabber, milky Cancel / Save chips, 96 dp category icon, field cards, a 44 dp capsule for Personal / Someone else / Church & world, a “Set as primary intention” switch, and a disabled Done pill until the title is filled.
- Legal pages use typo-accurate roles (`headingPrimary` / `headingSecondary` / body 16) plus the iOS `lineSpacing(4)`, 16 dp block rhythm, and extra 16 dp above `h2`. Acknowledgements rows are name-only; the license body is reflowed `captionReading` in `dim`.
- Journey uses the same 44 dp emphasis capsule as iOS `GuideChoiceControl`, and a milky back on the plain page.

Typography and measured landmark table: `docs/parity-v2/profile-settings-typography.md`.

## Remaining differences

- “11 days” in the Settings guest headline wraps on the Pixel 7 logical width (~411 dp vs iOS 440 pt). Left as a device-width difference, not a type-token bug.
- `settings-license` lists AndroidX Core (and the rest of the Android catalog), not the iOS Abseil-first Swift package list.
- Allowed M3 swaps still apply: accent switches (not iOS green) on Settings toggles; the primary switch on the editor uses the iOS success green; side-by-side dialog actions (Delete stays destructive red, but the confirm chrome is M3, not the iOS filled grey/red pills); no Apple button; no blur.
- Roborazzi 9:41 / 3G status bar and the tab-bar selected-pill treatment are the same already-approved Today / Learn harness differences. The compact Profile bar now sits below the 3G glyph.
- At end-of-scroll on `profile-backup`, faded week-dot remnants can still appear in the compact-bar scrim (iOS has usually scrolled that row away and uses a blur material). The backup card itself, including Create account, is fully above the tab bar.
- Settings icons are close stand-ins, not traced SF Symbols. The backup cloud is a simpler upload glyph than `icloud.and.arrow.up`.
- The App icon preview is a rounded grey card with outlined placeholder glyphs, not a bezeled iOS home-screen device frame with the official iOS placeholder artwork. Reminders is a checkbox rather than the three-dot list icon.
- Intention editor fields are a little shorter than the iOS 100 / 92 pt cards, and the capture uses a flat dimmed peek rather than a live Profile backdrop.
- Journey milestones still show “1 of 13” with the current four-session fixture; the iOS ref is “3 of 13” with First Rosary and 10 Rosaries already ticked. Hero leaf art and completed-row check treatment still differ. iOS Journey has no visible back chevron in the ref; Android keeps the milky back.
- Legal link colour is accent + underline rather than the iOS ink tint. Body wrapping differs slightly at 411 dp.

Status stays `close` until a Mac Pixel 7 recapture. Do not mark `matched`. These screens are not user-approved yet.
