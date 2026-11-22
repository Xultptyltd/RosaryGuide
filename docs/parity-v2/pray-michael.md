# pray-michael

Post-completion `michaelLayer`, always offered from completion even if Saint Michael was already an in-flow step. Done / Close returns to completion, not Home. Own language toggle (English / Latin / English + Latin), not the in-flow Eng/Lat/Both chips. Title “Saint Michael the Archangel”, Latin subtitle, prayer text, Done. No beads, no track, circular X only.

There is no v2 iOS ref for the *in-flow* Saint Michael step (the setting is off by default in the captured customise sheet). This screen is the post-completion overlay.

iOS hook: `-RGDebugMichaelLayer`.
Android: `show_michael_layer`, `mystery_set=joyful`.

iOS source: `Views/Pray/PrayView.swift` / `CompletionView.swift` / `RosarySettingsSheet`.
Android: `feature/pray` (`PrayScreen`, `CompletionScreen`, `SaintMichaelScreen`, `BeadRail`, `MysteryPlate`).
Full-screen cover; page colour `palette.prayBg` (plain `#FFFFFF` / `#000000`).
Chrome (except completion and post-completion Michael): circular Back (after the first prayer, and on the intention step), gear, one-line progress title (`TypeRole.label` medium), circular X, seven-stage track.
Prayer title: `TypeRole.modalTitle` (22 / 28, Instrument Sans). Prayer body: `TypeRole.prayerText` (sans 18, line-height 21). Title-to-body gap: 22 (`prayerTitleBodyGap`), or `Space.lg` on Sign of the Cross and plates.
Short prayers: text is vertically centered in the room above the bead shelf; beads sit above the footer (`Space.xl` above the rail). Long prayers use the scroll-to-continue morph (`GuideScrollActionButton`).
Footer: pill height 52; Next is the filled Marian-blue capsule; Complete decade is the unfilled tertiary pill; language is Eng / Lat / Both.
Beads hide for bilingual, plates, finis, and completion.
Captured on Pixel 7 (1080×2400, 2.625×), `en-AU`, `clock_date=2026-11-17`, Joyful Mysteries, demo-mode 9:41. Judge by frame fractions within 2%.

Landmarks: title, language control, body, Done, close control.
