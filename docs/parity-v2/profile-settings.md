# Profile / Settings — parity pass (RGA-4)

IA: `/workspace/android/ia/ia-map.md` §§6–7. Navigation follows that map: Profile hub (rhythm → Journey, intentions list / editor, papal detail, guest backup → sign-in, gear → Settings). Settings is a full-screen page (iOS `HomeSettingsDrawer` settles full-screen). Replay welcome is Onboarding page 0 with `includesSignIn: false`. Profile sign-in is the same Sign-in screen as onboarding (Google + guest, no Apple). `intention-icon-picker` is not in the live iOS editor and stays removed.

iOS refs: `/workspace/ios-parity-refs-v2`. Android frames: Roborazzi Pixel 7, light and dark (`+night`), clock 17 Nov 2026 so the week-dot “today” is Tuesday and the guest headline is “11 days” (earliest activity 6 Nov 2026).

## Screens in this group

Hub and auth: `profile`, `profile-backup`, `profile-sign-in`, `replay-welcome`.

Intentions and journey: `all-intentions`, `archived-intentions`, `intention-detail`, `intention-editor`, `papal-intention-detail`, `prayer-journey-milestones`, `prayer-journey-history`, `journey-day-sheet`.

Settings: `settings`, `settings-rosary`, `settings-reset-rosary`, `settings-notifications`, `settings-app-icon`, `settings-legal-terms`, `settings-legal-privacy`, `settings-acknowledgements`, `settings-license`, `settings-report-problem`, `settings-mail-unavailable`, `settings-clear-history`.

Not captured this pass (iOS refs exist): `delete-intention`, `journey-prayer-sheet`. No iOS refs: `settings-delete-account`, `settings-sign-out`, `settings-notifications-picker`, `archived-intentions-empty`, `profile-empty` (now a duplicate of the empty signed-in `profile`).

## What was aligned

- Profile hub uses the Marian wash, large title, milky 40 dp gear on the title row, compact rhythm card (“Your prayer” + 22 pt weekly summary + week dots, no “0 days” / calendar icon), iOS empty-intentions card (44 dp Marian circle + heart asset), papal card with a 96 dp square Pope Leo photo flush left, section labels outside the card, and the shared `GuestBackupCard`. Milestones were removed from the hub (they live on Journey).
- `profile-backup` scrolls the guest backup card on screen. The large title does not collapse to a compact centred title (see remaining differences).
- Settings uses compact milky-back chrome on a flat `palette.bg` (no ambient orbs), section labels outside grouped cards, trailing values, 56 dp rows, hairline dividers in `palette.hair`, leading SF-style stand-in icons, and an external-link arrow on Help rows. Color theme reads “System”. Guest backup sits between General and Help with no Account heading. Switches stay Marian accent (allowed M3 swap).
- All intentions is titled “All intentions”, uses the wash, a milky more chip, the tab bar, and the iOS sample titles. No extra “Add intention” button on the list.
- Replay welcome and profile sign-in reuse the approved onboarding-1 and sign-in screens.
- `settings-license` seeds the first Android `LicenseEntry` (AndroidX Core), not iOS Abseil.

Typography table: `docs/parity-v2/profile-settings-typography.md`.

Status stays `close` until a Mac Pixel 7 recapture. Do not mark `matched`.
