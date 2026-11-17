# week-feast-sheet

iOS: system sheet from `HomeView` (`HomeView.swift:224-227`), opened by `-RGDebugWeekFeastSheet` / a This-week feast row.
Android: `ModalBottomSheet` + `WeekFeastSheet` inside `TodayScreen`.


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

- System / M3 sheet. Detents: height estimate + `.large`. Drag indicator visible. Corner radius `containerRadius` **20**.
- Sheet fill is `palette.bg` (plain `#FFFFFF` / `#000000`), not grouped. The Today page remains dimmed behind (iOS light ref: sheet starts ≈ 387 pt from the top, scrim above).
- Horizontal gutter 16, bottom padding `Space.xl` 24 plus the system home indicator.

## Type and copy (Presentation of Mary, 21 November 2026 — the v2 hook)

- Eyebrow / rank · date: `TypeRole.caption` 12 regular, `palette.textSecondary` / `dim`. Date format on Android is `d MMMM yyyy` in en-AU (e.g. `21 November 2026`) with the feast rank title.
- Title: feast `shortTitle` in `TypeRole.headingPrimary` 32 regular, `palette.ink`. For this capture: **Presentation of Mary** (confirm against the iOS ref if the catalog short title differs).
- Body: `NavigationIa.weekFeastDescription` / the iOS week-feast blurb, `TypeRole.body` 16 regular, `palette.ink`.
- CTA: **`Explore this feast`**. This is a secondary / outline pill (not the Marian primary fill). Tapping dismisses the sheet and pushes feast detail (plain page). Use `GuideOutlineButton` / M3 `OutlinedButton`.

## M3 mapping

| iOS | Android |
| --- | --- |
| System `.sheet` with detents + drag indicator, radius 20 | M3 `ModalBottomSheet` (`skipPartiallyExpanded = false`), shape 20 dp |
| `PillButton` / outline CTA | `GuideOutlineButton` |
