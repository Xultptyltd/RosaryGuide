# Learn typography and spacing (audit-sprint-native)

Source: iOS `audit-sprint-native` (`AppTheme.TypeRole`, `AppTheme.Space`, `GuideSectionLabel`, `PrayHubView`, `LearnPrayerDetailView` / `PrayerReaderBlock`, `LearnMysteryDetailView`, `AllPrayersView`, `RosaryWalkthroughView` / `OnboardingPageView`).

pt → dp 1:1 and pt → sp 1:1. Fonts: Instrument Sans (UI) and Newsreader (serif, used on the unused How-to-pray reference page only). `TypeRole.regularized` maps semibold/bold back to regular; medium stays medium.

SwiftUI `.lineSpacing(s)` → Compose `lineHeight = typo LH + s`, `includeFontPadding = false`, `LineHeightStyle` trim `Both` when extra spacing is set, `None` otherwise.

Historical `RosaryType.body` (16/23) and `headingPrimary` (32/38) are unchanged so approved Today / onboarding / Pray-adjacent frames stay put. Learn uses the typo-accurate `*Pray` / `themeSummary` / `headingPrimaryWalkthrough` / `prayerTextMichael` roles.

## Type roles on live Learn screens

| Role (iOS) | Size / weight / pitch | Tracking | Old Android | New Android |
| --- | --- | --- | --- | --- |
| Large “Learn” title | `h1` / large nav (GuideLargeTopAppBar) | 0 | existing large bar | unchanged chrome |
| Intro / walkthrough / “The Rosary” / prayer titles | `headingPrimary` 32, typo 39.04 | 0 | `headingPrimary` 32/38 or `headingSecondary` 22 | `headingPrimaryPray` 32/39.04 |
| Walkthrough title | 32 + `lineSpacing(2)` → **41.04** | 0 | `headingSecondary` 22/28, left-aligned | `headingPrimaryWalkthrough` 32/41.04, centred |
| Walkthrough body; intro subtitle; FAQ answers | callout/body 16 + `lineSpacing(5)` → **24.52** | 0 | `body` 16/23 or `supportingLabel` 15/20 | `themeSummary` 16/24.52 |
| Body / callout / regularized semibold row titles | 16 regular, typo 19.52 | 0 | `body` 16/23, often `FontWeight.Medium` | `bodyPray` 16/19.52 regular |
| Caption / section labels (quiet) / weekday captions | 12, typo 14.64 | 0 | `caption` 12/16 | `captionPray` 12/14.64 |
| Strong section labels (“The mysteries”) | `sectionHeading` = body 16 | 0 | `GuideSectionLabel` default 15 | `bodyPray`, `strong = true` |
| Prayer reader body | `prayerText` 18 + `lineSpacing(8)` → **29.96** | 0 | `serifBody` / italic serif | `prayerTextMichael` 18/29.96, same sans on Latin |
| Prayer reader Latin title | `guideThemeSummaryStyle` 16+5 | 0 | `serifItalicBody` | `themeSummary` |
| Segmented language control | 14 medium, height 44 | 0 | M3 `SegmentedButton` | 44 dp custom capsule, `segmentedControlPray` |

## Layout spacing

| Location | iOS | Old Android | New Android |
| --- | --- | --- | --- |
| Hub after search | `Space.xl` 24 | 24 | 24 |
| Section title → content | `sectionTitleGap` 20 | label `xs` only | still label `xs` + existing stack (see measured table) |
| Mystery tiles | `Space.md` 12 between cards | 12 + 1 dp border | 12 |
| Intro / Rosary feature card padding | `Space.xl` 24 | 24 | 24 |
| Intro title stack | `Space.lg` 16 | 16 | 16 |
| FAQ row vertical pad | `Space.lg` 16 | 16 | 16 |
| FAQ answer paragraphs | `Space.md` 12 | 12 | 12 |
| Prayer reader title → Latin | `Space.sm` 8 | 4 | 8 |
| Title group → language → body | stack `xl` 24 + reader pad `lg` 16 | `lg` 16 | 24 + 16 |
| Prayer paragraph gap | `Space.xl` 24 | single `Text` / blank line | 24 between split paragraphs |
| Walkthrough panel | `OnboardingPanel` / `signInPanelHeight` (0.5 when height ≥ 820) | unframed full-bleed image | same black rounded-bottom panel as onboarding |
| Walkthrough title ↔ body | `Space.lg` 16, centred | `sm` 8, leading | 16, centred |
| All-prayers empty copy | (hub empty is “Nothing can be found…”) | “No prayers found…” on the all-prayers page | unchanged page-specific copy |

`minHitTarget` stays 48 dp on Android (iOS 44) except already-sized 40 dp close chips.


## Measured this pass (equal scale: iOS px/3 = pt, Android px/2.625 = dp)

Auto-detected medians are unreliable on screens that mix art, icons, and titles in the same crop. The rows below are the tight body / title-to-body figures that survived a manual check of the line list.

| Screen | Metric | iOS | Android | Δ |
| --- | --- | --- | --- | --- |
| learn-faq | FAQ answer line pitch (`themeSummary`) | 24.67 pt | 24.76 dp | 0.10 |
| learn-faq | Question → answer ink gap | 24.33 | 24.76 | 0.43 |
| learn-faq | Answer paragraph ink gap | 13.33 | 13.71 | 0.38 |
| prayer-reader | Prayer body pitch (`prayerTextMichael`) | 30.00 pt | 30.10 dp | 0.10 |
| prayer-reader | Title → Latin ink | 17.00 | 17.14 | 0.14 |
| prayer-reader | Latin → control / body ink | 20.67 | 20.57 | −0.10 |
| walkthrough-1…5 | Body pitch (`themeSummary`) | 24.67 pt | 24.76 dp | 0.10 |
| walkthrough-1…5 | Title → body ink (line1→2) | 28.33 | 28.19 | −0.14 |
| learn-mystery-detail | Title → body ink | 32.33 | 32.00 | −0.33 |
| learn-mystery-detail | Intro body pitch | 24.33 | 24.76 | 0.43 |
| learn-search-empty | Field → empty-copy ink | 46.33 | 46.10 | −0.24 |
| all-prayers | Row ink-to-ink (title band) | 65.00 | 62.10 | −2.90 |

Body pitch on FAQ, walkthrough, prayer reader, and mystery-detail intro is within the 0.5 sp budget. The all-prayers row band is 2.90 dp tighter than iOS (over the 1 dp gap budget) — listed as a remaining difference. Hub intro / search-row detectors mixed in chrome, so those screens were reviewed visually rather than from the auto median.

