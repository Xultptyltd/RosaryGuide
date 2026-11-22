# Learn group — parity spec (audit-sprint-native)

Scope: the Learn tab root and every screen/sheet under it that has iOS refs in `/workspace/ios-parity-refs-v2`. Feasts results from Learn search and Today’s `mystery-detail-sheet` stay with their own groups. HowToPray / standalone article pushes are unused in the live hub and have no matching iOS refs.

Source: iOS `PrayHubView` (Learn tab), `LearnMysteryDetailView`, `AllPrayersView`, `LearnPrayerDetailView` / `PrayerReaderBlock`, `RosaryWalkthroughView` / `OnboardingPageView`, `AppTheme.TypeRole` / `Space`, on branch `audit-sprint-native`. Typography and spacing: `docs/parity-v2/learn-typography.md`.

## Screens

| screen-id | iOS source | Android | What the ref shows |
| --- | --- | --- | --- |
| learn | Learn tab, large title, empty query | `LearnScreen` | Intro card, mystery tiles, prayer tiles below the fold, FAQ below that |
| learn-faq | Same hub, scrolled to Common questions, first question expanded | `LearnScreen(initialScrollToQuestions, initialExpandedArticleId)` | Collapsed “Learn” title, accordion |
| learn-search | Query `Hail` | `LearnScreen(initialQuery)` | Flat prayer list (no section heading), search field with icon + clear |
| learn-search-empty | Query `zzzznotfoundxyz` | same | “Nothing can be found. Try another search” |
| learn-mystery-detail | Joyful set, all rows collapsed | `MysterySetScreen` | Hero, title, intro, numbered accordion, Pray CTA may sit under the tab bar |
| rosary-prayers | Pushed list, grouped | `RosaryPrayersScreen` | Opening / Each decade / Closing groups |
| all-prayers | Pushed library | `AllPrayersScreen` | Search field + flat A–Z list |
| prayer-reader | Apostles’ Creed, English | `PrayerReaderScreen` | 32 pt title, Latin `themeSummary`, 44 pt language control, 18/29.96 body |
| walkthrough-1…5 | Full-screen walkthrough, pages 0–4 | `RosaryWalkthroughScreen(initialPage)` | Edge-to-edge art, no status bar, centred 32/41.04 title, milky close chip |

## Tokens that must stay typo-accurate

- Titles: `headingPrimaryPray` 32/39.04; walkthrough title `headingPrimaryWalkthrough` 32/41.04 centred.
- Intro subtitle, FAQ answers, walkthrough body: `themeSummary` 16/24.52.
- Row titles: `bodyPray` 16/19.52 regular (regularized semibold).
- Prayer body: `prayerTextMichael` 18/29.96; Latin title is sans `themeSummary`, not serif italic.
- Language control height: 44 dp.
- Section labels: strong `bodyPray`. Cards on the grouped page use `cardSurface(Grouped)` (white in light).
- Mystery set avatars: 56 dp Marian-blue circles with the iOS `MysteryIcon*` glyphs, not photographic thumbs.

## Capture

Roborazzi Pixel 7, inset-faithful harness (`Pixel7DeviceFrame`). The Mac Pixel 7 emulator was still unreachable this pass. Light and dark. Walkthrough tests hide the status bar so art can go edge-to-edge, matching the iOS refs. Tab roots include the pushed Learn screens, with Learn selected.

Do not overwrite approved Today / onboarding / Pray Android frames when copying new shots.
