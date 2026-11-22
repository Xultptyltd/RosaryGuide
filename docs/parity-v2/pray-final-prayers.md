# pray-final-prayers

Closing prayers, Hail, holy Queen, `pray_step=77`. Progress “Closing prayers”. Last track stage filled. Bead rail at the closing locus (full loop filled). Next + language. Hail Holy Queen is long; on Pro Max it still uses the short-prayer footer (Next pill, not the scroll circle). If Pixel 7’s shorter frame flips it into the scroll template, that is an aspect-ratio exception to explain.

iOS hook: `-RGDebugStep 77`.
Android: `open_pray`, `force_fresh_pray`, `pray_step=77`, `mystery_set=joyful`.

iOS source: `Views/Pray/PrayView.swift` / `CompletionView.swift` / `RosarySettingsSheet`.
Android: `feature/pray` (`PrayScreen`, `CompletionScreen`, `SaintMichaelScreen`, `BeadRail`, `MysteryPlate`).
Full-screen cover; page colour `palette.prayBg` (plain `#FFFFFF` / `#000000`).
Chrome (except completion and post-completion Michael): circular Back (after the first prayer, and on the intention step), gear, one-line progress title (`TypeRole.label` medium), circular X, seven-stage track.
Prayer title: `TypeRole.modalTitle` (22 / 28, Instrument Sans). Prayer body: `TypeRole.prayerText` (sans 18, line-height 21). Title-to-body gap: 22 (`prayerTitleBodyGap`), or `Space.lg` on Sign of the Cross and plates.
Short prayers: text is vertically centered in the room above the bead shelf; beads sit above the footer (`Space.xl` above the rail). Long prayers use the scroll-to-continue morph (`GuideScrollActionButton`).
Footer: pill height 52; Next is the filled Marian-blue capsule; Complete decade is the unfilled tertiary pill; language is Eng / Lat / Both.
Beads hide for bilingual, plates, finis, and completion.
Captured on Pixel 7 (1080×2400, 2.625×), `en-AU`, `clock_date=2026-11-17`, Joyful Mysteries, demo-mode 9:41. Judge by frame fractions within 2%.

Landmarks: title, body, beads, Next (or scroll circle, if the frame overflows).
