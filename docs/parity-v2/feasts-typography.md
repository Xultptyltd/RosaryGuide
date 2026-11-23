# Feasts typography and spacing

Source: iOS `FeastsView.swift` (`FeastsView`, `FeastTimelineRow`, `FeastDetailView`, `FeastSecondaryPage`, `FeastRelatedPrayersView`, `FeastPatronagesView`, `FeastScriptureView`, `FeastHeroBanner`) and `AppTheme.TypeRole` / `Space` / `Component`.

pt → dp 1:1 and pt → sp 1:1. Fonts: Instrument Sans / Newsreader. `TypeRole.regularized` maps semibold/bold back to regular; medium stays medium.

SwiftUI typo line height = size × 1.22. Compose `includeFontPadding = false`. Historical tokens used by approved Today / onboarding / Pray / Learn frames are unchanged. Feasts uses the typo-accurate `*Pray` / feast-only roles below.

## Type roles on live Feasts screens

| Role (iOS) | Size / weight / pitch | Android |
| --- | --- | --- |
| Large “Feasts” title | `h1Navigation` / large nav | Feasts-only title row, `h1Navigation` (shared `GuideLargeTopAppBar` unchanged) |
| Scope capsules | `segmentedControl` 14 medium | `segmentedControlPray` 14 medium |
| “November 2026” | `callout(weight: .medium)` 16 medium, typo 19.52 | `calendarMonthTitle` 16/19.52 medium |
| “Today” text button | body / callout 16 | `bodyPray`, `actionForeground` (AA in dark) |
| Weekday header (M Tu W Th F Sa Su) | `caption` 12, typo 14.64 | `captionPray` 12/14.64 |
| Calendar day number | `calendarDay` 16 regularized, typo 19.52 | `calendarDay` 16/19.52 |
| Timeline date number | `calendarDateNumber` 22, typo 26.84 | `calendarDateNumber` 22/26.84 |
| Timeline month abbrev | `calendarCaptionMedium` 12 medium + `Component.eyebrowTracking` 2 | `calendarMonthAbbrev` 12/14.64, tracking 2 |
| Timeline title | `calloutUIFont(weight: .semibold)` regularized to 16 regular | `feastTimelineTitle` 16/19.52 |
| Timeline rank | `caption` 12 | `captionPray` |
| Agenda section label (“Next”) | `GuideSectionLabel` prominence `.strong` = body 16 | `bodyPray`, `strong = true` |
| Empty copy | `bodySmall` / callout 16 | `bodyPray` |
| Learn / Pray this Rosary | `pillLabel` 16 regular | `body` on the shared pill buttons |
| Detail nav title / secondary nav title | `navigationTitle` 17 medium | `navigationTitlePray` 17 medium |
| Detail eyebrow (`21 NOVEMBER. MEMORIAL`) | `sectionLabel` / caption 12, typo 14.64 | `captionPray` |
| Detail title | `screenTitle` / `title2` = `headingPrimary` 32, typo 39.04 | `headingPrimaryPray` 32/39.04 |
| Detail summary | `body` 16 + `lineSpacing(7)`, typo 19.52 + 7 = 26.52 | `bodyFeastSummary` |
| Meaning paragraphs | `bodySmall` / callout 16 + `lineSpacing(7)` | `bodySmallFeast` |
| At-a-glance label / value | caption 12 / bodySmall 16 | `captionPray` / `bodyPray` |
| “Keep the day” / “Prayers…” / “Scripture and Rosary” | strong section label = body 16 | `bodyPray`, `strong = true` |
| Practice title / body | `sectionHeading` (body 16) / `themeSummary` 16 + `lineSpacing(5)` | `bodyPray` / `themeSummary` |
| Prayer accordion title / body | `sectionHeading` 16 / `bodySmall` + `lineSpacing(8)` | `bodyPray` / `bodySmallFeastPrayer` |
| Secondary page title | `serifDisplay` 40 / 46 (optical 44) | `serifDisplay` 40/46 |
| Feast short title under it | `serifBody` 20 / 29 | `serifBody` 20/29 |
| Patronage intro | `serifBody` 20 + `lineSpacing(4)` | `serifBody` with lineHeight 33 |
| Patronage name | `serifTitle` 24 + `lineSpacing(4)` | `serifTitle` with lineHeight 34 |
| Scripture heading / excerpt | `serifTitle` 24 / `serifBody` 20 + `lineSpacing(5)` | `serifTitle` / `serifBody` lineHeight 34 |

## Layout spacing

| Location | iOS | Android |
| --- | --- | --- |
| Page gutter | `gutter` 16 | 16 |
| Root content top under the large title | `GuideRootChrome.contentTop` = `Space.lg` 16 | 16 under the Feasts title row |
| Scope control height | `segmentedControlHeight` = `minHitTarget` 44 | 44 |
| Month row min height | `minHitTarget` 44 | `calendarHitTarget` 44 (not the shared 48 used on approved screens) |
| Weekday header | 20 tall, `Space.sm` 8 below | 20 / 8 |
| Calendar day row | `feastCalendarDayHeight` 52 | 52 |
| Expanded weeks | 5 rows, `Space.xs` 4 gutters | 5 × 52 + 4 × 4 |
| Selected / today disc | `minHitTarget` 44 circle, fill `accent`, today stroke 1 | 44, `palette.accent`, 1 dp stroke |
| Feast dots | 4 × 4, `palette.accent`, `calendarHandleDotGap` 12 above the handle | 4 / 12 |
| Calendar handle | 36 × 4 | 36 × 4 |
| Handle → section divider | `calendarHandleDividerGap` 2, then divider, then `Space.md` 12 | 2 / official `GuideSectionDivider` / 12 |
| Agenda section title gap | `sectionTitleGap` 20 | 20 |
| Timeline date column / row gap | 56 / 20 | 56 / 20 |
| In-group hairline | 1 px, leading inset 76 | `Hairline` 1 px, start 76 |
| Between agenda sections | `GuideSectionBoundary` (8 / 16 × 40 caps) | `SectionBand` |
| Detail hero | 330, bottom fade 0.18, 8 pt underlap under the nav, art starts just below the bar | `330 × (width/440)` (308 dp on Pixel 7), same fade and 8 dp underlap; cover is not given the status+nav height |
| Secondary hero | 238, same fade and 8 pt underlap | `238 × (width/440)` (222 dp on Pixel 7), same fade and underlap |
| Metadata → title | `Space.sm` 8 | 8 |
| Title → summary | `Space.md` 12 | 12 |
| Summary → meaning | 26 | 26 |
| Meaning paragraph gap | `Space.xl` 24 | 24 |
| Quick-fact / practice row vertical pad | 15 | 15 |
| Label column | 88 | 88 |
| Prayer header inset | 18 / `Space.lg` 16 | 18 / 16 (0 horizontal when flush on secondary pages) |
| Info rows (Related prayers / Patronages / In Scripture) | `serifBody`, vertical 17 (present in source, not in the live detail body) | same, below the fold after Scripture |
| Tab roots / pushes in the Feasts stack | `guideTabBarPadding` + system tab | `tabBarContentClearance` + `GuideTabBar` + 90 dp scrim |
