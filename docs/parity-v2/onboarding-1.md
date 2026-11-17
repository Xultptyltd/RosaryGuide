# onboarding-1

iOS: `OnboardingView` page (`App/OnboardingView.swift`).
Android: `OnboardingScreen` (`initialPage` 0/1/2).


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

- Page colour `palette.bg` (`#FFFFFF` / `#000000`).
- **Light appearance hides the status bar** (`statusBarHidden` when scheme is light, `:87`). Dark keeps the status bar (icons light on the hero). Inferred: the 9:41 override may be invisible on the light frames.
- No nav bar, no tab bar. System home indicator remains.
- Hero is `OnboardingPanel`: inset `SignInLayout.panelInset` **24 dp** from the left/right edges, bleeds under the status bar (`padding.top = -safeArea.top`), bottom corners `panelRadius` **32 dp** continuous. Height is `SignInLayout.panelHeight(screenHeight)` = `round(screenHeight × 0.5)` (or `× 0.45` if height < 820). Measured on the 956 pt iPhone 17 Pro Max ref: image left 24 pt, image bottom ≈ 468.7 pt.
- A short fade in the panel fill sits behind the status-bar icons (height `safeArea.top + Space.xl`). Light mode hides those icons, so the hero is flush with the top edge.
- Image asset `OnboardingRosaryDaily`, alignment `top` (`top` or `center`), cropped inside the panel.
- Controls reserve `OnboardingLayout.controlsHeight` = **132 dp** above the home indicator. Continue / Begin is a 52 dp pill, gutter 16, fill `buttonPrimaryFill` `#0054FF`, label `pillLabel` / `body` 16 regular Instrument Sans in `onAccent` `#FFFFFF`. Measured: button 408 × 52 pt, gutter 16, bottom inset below the pill 74 pt (home indicator + `Space.xl` 24).
- Page dots: 8 dp active / 7 dp inactive circles, 8 dp gap, active `palette.ink`, inactive `palette.strokeStrong`. Measured cluster sits ~22 pt above the pill.

## Type and spacing

- Title: `TypeRole.title` / `headingPrimary`, 32 regular Instrument Sans, line height 38, `palette.ink`, centred. Copy is hard-wrapped on two lines as below.
- Body: `TypeRole.body`, 16 regular Instrument Sans, `palette.dim` (`#5C5C5C` / `#AEAEAE`), centred.
- Vertical stack spacing title↔body is `Space.lg` **16 dp**. Bottom padding of the text block `Space.xl` **24 dp** (`OnboardingView.swift:154, :172`).
- Measured on `onboarding-1-light`: title ink starts ≈ 547 pt from the top; body follows after the 16 dp gap.

## Copy (verbatim)

Title:

```
Make room\nfor prayer.
```

Body:

```
Slow down and draw closer to God\nthrough the Rosary.
```

Primary pill: **Continue**

## M3 mapping

| iOS | Android |
| --- | --- |
| `OnboardingPanel` (custom clipped hero) | Custom `Box` + `Image`, 24 dp inset, 32 dp bottom corners (not an M3 card) |
| `PillButton` 52 pt | `GuidePrimaryButton` / M3 `Button` at `pillHeight` 52, 20 dp corners, label regular (not semibold) |
| `TabView` page dots | Custom dots (not `HorizontalPager` indicators if they disagree with size/colour) |
| Hidden status bar (light only) | `WindowInsetsController.hide(statusBars)` while this screen is shown in light mode |
