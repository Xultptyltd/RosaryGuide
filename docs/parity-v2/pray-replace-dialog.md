# pray-replace-dialog

“Start a new rosary?” when a fresh launch happens while a resumable session exists. Copy: “You already have a rosary in progress today. Starting fresh will replace it once you move past the first step.” Actions: Replace saved place (destructive) and Cancel (cancel; closes the Pray cover).

iOS presents a system alert over a dimmed Pray cover. Android uses `AlertDialog` (Material 3). Copy matches; the chrome of the alert itself is a platform component difference. Measure the dialog’s vertical placement as a frame fraction.

iOS hook: `-RGDebugRosaryFlow` without `-RGDebugReplaceSavedRosary`, after a session exists.
Android: `show_replace_dialog`, `mystery_set=joyful`.

iOS source: `Views/Pray/PrayView.swift` / `CompletionView.swift` / `RosarySettingsSheet`.
Android: `feature/pray` (`PrayScreen`, `CompletionScreen`, `SaintMichaelScreen`, `BeadRail`, `MysteryPlate`).
Full-screen cover; page colour `palette.prayBg` (plain `#FFFFFF` / `#000000`).
Chrome (except completion and post-completion Michael): circular Back (after the first prayer, and on the intention step), gear, one-line progress title (`TypeRole.label` medium), circular X, seven-stage track.
Prayer title: `TypeRole.modalTitle` (22 / 28, Instrument Sans). Prayer body: `TypeRole.prayerText` (sans 18, line-height 21). Title-to-body gap: 22 (`prayerTitleBodyGap`), or `Space.lg` on Sign of the Cross and plates.
Short prayers: text is vertically centered in the room above the bead shelf; beads sit above the footer (`Space.xl` above the rail). Long prayers use the scroll-to-continue morph (`GuideScrollActionButton`).
Footer: pill height 52; Next is the filled Marian-blue capsule; Complete decade is the unfilled tertiary pill; language is Eng / Lat / Both.
Beads hide for bilingual, plates, finis, and completion.
Captured on Pixel 7 (1080×2400, 2.625×), `en-AU`, `clock_date=2026-11-17`, Joyful Mysteries, demo-mode 9:41. Judge by frame fractions within 2%.

Landmarks: dialog top/bottom, title, buttons.
