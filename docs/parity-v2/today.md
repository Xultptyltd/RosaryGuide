# today

iOS: `HomeView` (`Views/Home/HomeView.swift`).
Android: `TodayScreen`.


## Shared tokens (from iOS `spec.md` + `AppTheme.swift`)

Measurements at 3× (pixels ÷ 3 = pt = dp). Instrument Sans regular unless noted. Newsreader only where a serif role is named.

### Colour

| Token | Light | Dark |
| --- | --- | --- |
| `background` / `bg` / `palette.bg` | `#FFFFFF` | `#000000` |
| `groupedBackground` | `#F8F8FA` | `#000000` |
| `textPrimary` / `ink` | `#000000` | `#FFFFFF` |
| `textSecondary` / `dim` | `#5C5C5C` | `#AEAEAE` |
| `surface` | `#EBEBED` | `#1C1C1E` |
| `accent` / `buttonPrimaryFill` / `marianBlue` | `#0054FF` | `#0054FF` (fill stays Marian blue) |
| `onAccent` / `buttonPrimaryText` | `#FFFFFF` | `#FFFFFF` |
| `accentText` | `#0054FF` | `#3D7DFF` |
| `tabSelected` | `#0054FF` | `#7DA8FF` |
| `launchCanvas` | `#0054FF` | `#0054FF` |
| `brandCanvas` | `#0054FF` | `#000000` (dark sign-in panel is page black, not Marian blue) |
| `buttonSecondaryFill` | `#000000` | `#FFFFFF` |
| `strokeSubtle` | ink @ 7% | ink @ 12% |
| `strokeStrong` | (inactive dots) | |
| `googleButtonFill` | `#FFFFFF` | `#131314` |
| `googleButtonStroke` | `#747775` | `#8E918F` |
| `googleButtonText` | `#1F1F1F` | `#E3E3E3` |
| `todayPillFill` / `todayPillText` | `#FFFFFF` / `#000000` | `#FFFFFF` / `#000000` |

### Type (Dynamic Type Large)

| Role | Size / weight / family / line height |
| --- | --- |
| `headingPrimary` / `title` / `screenTitle` | 32 / regular / Instrument Sans / 38 |
| `headingSecondary` | 22 / regular / Instrument Sans / 28 |
| `headingCard` | 26 / regular / Instrument Sans / 32 |
| `h1Navigation` | 44 / regular / Instrument Sans / 48 |
| `navigationTitle` | 17 / medium / Instrument Sans / 22 |
| `body` / `callout` / `themeSummary` / `buttonTertiary` | 16 / regular / Instrument Sans / 23 (themeSummary adds 5 pt line spacing) |
| `pillLabel` | 16 / regular (semibold is regularized) / Instrument Sans / 23 |
| `supportingLabel` | 15 / regular / Instrument Sans / 20 |
| `segmentedControl` | 14 / medium / Instrument Sans / 18 |
| `caption` / `label` / `sectionLabel` | 12 / regular / Instrument Sans / 16 |
| `serifTitle` | 24 / regular / Newsreader / 30 |
| `serifDisplay` | 40 / regular / Newsreader display / 46 |
| Home display title | `homeTitleSize(width)` = clamp(43.2, width × 0.115, 56); at 440 pt → 50.6; line height 1.02 × size; Instrument Sans regular |

### Space

gutter 16 · xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · section 44 · sectionTitleGap 20 · containerRadius 20 · featureRadius 24 · panelRadius 32 · nestedRadius 12 · pillHeight 52 · minHitTarget 44 (Android M3 hit target may be 48 on native controls) · tabBarContentClearance 108 · mysteryCardWidthFraction 0.85 · mysteryCardArtAspect 1.3 · OnboardingLayout.controlsHeight 132 · SignInLayout.panelInset 24 · SignInLayout.quoteSize 32 · SignInLayout.loopBottomPadding 40 · sheetOverlap 56 · titleLineHeight 1.02


## Chrome

- Navigation bar **hidden**. Grouped ambient background: `palette.groupedBackground` (`#F8F8FA` / `#000000`). The hero dissolves into that colour (not into plain white).
- The tab bar stays visible. On iOS it is a **custom floating capsule** (liquid glass), not `UITabBar`. Android must use a matching custom floating bar (selected `#0054FF` / `#7DA8FF`, unselected `textSecondary`, labels 12 regular). Content clearance `tabBarContentClearance` 108 dp.
- Status bar is visible, 9:41 in refs. Home `ignoresSafeArea(edges: .top)` so the hero runs under the status bar.
- Appearance chip (custom glass capsule, trailing, sitting on the hero just below the status-bar trailing items): label “Light” + `sun.max.fill` or “Dark” + `moon.fill`, `TypeRole.label` 12 medium, `palette.ink`, horizontal padding 14, min height 44. Menu: Light / Dark / System. This is live product UI, not a debug overlay.
- No in-content “Today” large title (iOS hides the nav bar and does not draw a page title).

## Hero

- `MysteryArtworkView(set: currentSet, kind: .heroTall)` full-bleed width, height `homeHeroHeight(viewport) + topInset + artworkTop`.
- `homeHeroHeight(viewport) = min(max(320, viewport × 0.46), 464)`. The call passes `viewport.height + topInset` (the full window height). On a 956 pt phone this is 439.8 pt, plus the status-bar inset and a 60% status-bar top band (`artworkTop = rounded(topInset × 0.6)` unless collapsed).
- Gradient dissolve into `groupedBackground` (stops: 0: grouped @ 0.18 light / 0.34 dark, 0.22: clear, 0.64: grouped @ 0.55, 0.86–1: grouped).
- The sheet content overlaps the hero by **36 dp** (`.padding(.top, -36)`).

## Sheet content (horizontal gutter 16, top padding `Space.sm` 8 after the overlap)

- Date: `today.formatted(.dateTime.weekday(.wide).month(.wide).day())` in en-AU with no year and no comma: **`Tuesday 17 November`**. `TypeRole.label` 12 regular, `palette.dim`. Padding below: `Space.md` 12. Measured ≈ 476 pt from the top of the 956 pt frame.
- Title: `GuideDisplayTitle` “`Sorrowful\nMysteries`” (or the selected set), size `homeTitleSize(width)` = clamp(43.2, width × 0.115, 56). At 440 pt → **50.6**; on a 411 dp Pixel 7 width → **47.3**. Instrument Sans regular, `palette.ink`, line height 1.02 × size.
- If the day offers a feast set, a feast line replaces the subtitle; otherwise `currentSet.themeSummary` with `guideThemeSummaryStyle()`: `TypeRole.themeSummary` 16 regular, `palette.dim`, +5 pt line spacing, padding top `Space.md` 12. For Sorrowful: **`The Passion and sacrifice of Jesus.`**
- Set picker (`GuideChoiceControl` / native iOS `Picker` segmented): options Joyful, Luminous, Sorrowful, Glorious (short names). Height 44 (`segmentedControlHeight`). Type 14 medium. A 4 dp ink (or faint) dot sits on today’s weekday set (`assignment.pickerDotSet`). Because this control is native on iOS, Android may use M3 `SingleChoiceSegmentedButtonRow`, but it must keep equal-width segments and the weekday dot. Padding top `Space.xl` 24. Track in the light ref is a gray capsule ≈ `#DCDCDF` with a white selected thumb (not a Marian-blue fill).
- Primary CTA: `PillButton` 52 dp, fill `#0054FF` both modes, label 16 regular `onAccent`. Padding top `Space.lg` 16, gutter 16 (measured 408 × 52 at y ≈ 743.7 pt). Copy is state-dependent:
  - default on today’s set: **`Pray today's mysteries`** (this is the 17 Nov 2026 ref)
  - browsing another set: **`Pray the ⟨shortName⟩ Mysteries`**
  - resumable session: the session’s continue title (`Continue`)
  - already completed today: **`Pray again`**
- “Today's mysteries” (or the set’s name when browsing) `GuideSectionLabel` prominence `.strong`, then a horizontal mystery rail. Cards are **85%** of the screen width (`mysteryCardWidthFraction`) so the next card peeks; spacing `Space.md` 12; art aspect **1.3**; card corners `featureRadius` 24; title `headingCard` 26 regular. Tapping a card opens `mystery-detail-sheet`. Padding top `Space.xxl` 32. This rail is below the fold on the 17 Nov Pro Max ref (the tab bar covers the start of the heading).
- Daily scripture on Home is archived (`showDailyScriptureOnHome = false`) — do not show it.
- `GuideSectionBoundary` then **`Upcoming feast days`** (strong section label) and the featured + secondary feast rows. “View all feasts” switches to the Feasts tab (not a new screen).
- Another section boundary, then **`This week`**. Tapping a feast day opens `week-feast-sheet`; tapping a non-feast day does not push. Today’s row uses a distinct surface; VoiceOver includes “today”.
- Footer tertiary pill: **`Share Rosary Guide`**, `TypeRole.callout` 16, `tertiaryButtonFill` / `tertiaryButtonText`, height 44, horizontal padding 16. Shares `https://rosaryguide.app` until an App Store / Play id is set.

## M3 mapping

| iOS | Android |
| --- | --- |
| Hidden `NavigationStack` bar, grouped chrome | No `TopAppBar`; `groupedBackground` on the screen |
| Custom liquid-glass tab bar | Custom floating capsule tab bar (not stock `NavigationBar` — iOS is not using `UITabBar`) |
| `GuideChoiceControl` native segmented `Picker` | M3 `SingleChoiceSegmentedButtonRow` plus the weekday dot overlay |
| `PillButton` | `GuidePrimaryButton` / M3 `Button`, 52 dp, regular 16 |
| `Menu` appearance chip (custom glass label) | Custom glass chip + M3 `DropdownMenu` (Light / Dark / System) |
| Mystery rail (custom cards) | Custom cards, 0.85 width, aspect 1.3, 26 regular title |
| `ShareLink` footer | M3 share `Intent` / `ACTION_SEND` from a custom tertiary pill |
| Upcoming feast / This week rows | Custom rows (existing `FeaturedFeastCard` / `WeekGlanceRow`, retuned to tokens) |
