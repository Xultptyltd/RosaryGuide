# mystery-detail-sheet

iOS: system sheet from `HomeView` mystery rail (`:1134` region), opened by `-RGDebugMysteryDetailSheet` / tapping a rail card. The v2 hook is the first Sorrowful Mystery.
Android: `ModalBottomSheet` + `MysteryDetailPagerSheet`.


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

- System / M3 sheet, same detents and drag indicator as `week-feast-sheet`. Corner radius 20. Fill `palette.bg`.
- Horizontal pager through the current set (Sorrowful on 17 Nov 2026). Page dots under the pager: active `palette.ink`, inactive `palette.dim`.
- Art: mystery artwork, aspect close to `mysteryCardArtAspect` 1.3 (Android currently uses 1.4 — retune to 1.3), corners `containerRadius` 20, gutter 16.

## Type and copy (first Sorrowful Mystery)

- Eyebrow: `{ordinal} mystery · {set.shortName}` (e.g. `First mystery · Sorrowful`), `TypeRole.caption` 12, `palette.dim`.
- Title: `mystery.title` in `headingPrimary` 32 regular, `palette.ink`. First Sorrowful: **The Agony in the Garden** (catalog English title — confirm against the ref).
- Scripture excerpt: `TypeRole.body` 16, `palette.ink`. Reference: `TypeRole.caption` 12, `palette.dim` (`scriptureReference(isMystery:)` is 11 on mystery plates; this sheet uses the 12 caption unless the iOS source specifies the mystery size).
- Fruit: `Fruit of the mystery: {fruit}`, `supportingLabel` 15 regular, `palette.ink`.
- CTA: **`Pray this decade`** — outline / secondary pill, dismisses the sheet and opens Pray at that decade (`onPrayDecade`).

## M3 mapping

| iOS | Android |
| --- | --- |
| System `.sheet` + horizontal paging | M3 `ModalBottomSheet` + `HorizontalPager` |
| Outline CTA | `GuideOutlineButton` |
