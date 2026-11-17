# sign-in

iOS: `OnboardingSignInView` (`App/OnboardingView.swift:304`).
Android: `SignInScreen`. Profile’s guest cover (`profile-sign-in`) is the same view presented as a full-screen overlay; that capture is deferred to the Profile/Settings group.


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

- Page colour `palette.bg` (`#FFFFFF` / `#000000`). Status bar is **visible** (unlike light onboarding). The Marian / black hero bleeds under it.
- Hero is the same `OnboardingPanel` as onboarding: 24 dp side inset, 32 dp bottom corners, height `round(screenHeight × 0.5)` (0.45 if height < 820). Fill is `AppTheme.brandCanvas(colorScheme)`: `#0054FF` in light, `#000000` in dark. Dark refs are a black panel on a black page; do not paint the dark hero Marian blue.
- `RosaryBeadsFallPlayer` hangs in the panel: strands start `strandOverflow` 36 dp above the screen top; the loop sits `loopBottomPadding` 40 dp above the panel bottom.
- No nav bar, no tab bar.
- Button stack spacing `Space.md` (12). Bottom padding `Space.xl` (24). Horizontal gutter 16.

## Type

- Quote: `GuideDisplayTitle` at `SignInLayout.quoteSize` **32**, Instrument Sans regular (not Newsreader), colour `palette.ink`, centred, typographic quotes and a hard line break.
- Attribution: `TypeRole.body` (16 regular Instrument Sans), `palette.dim`, centred. Stack spacing between quote and attribution is `Space.md` (12).
- Then a spacer of at least `Space.xl` (24) before the buttons.
- Google (and, on iOS only, Apple) pill labels: `TypeRole.body(weight: .semibold)` / `pillLabel(weight: .semibold)` — both **regularized to regular**. 52 dp height, 20 dp corners.
- Google fill / stroke / text from `googleButton*` (1 dp stroke).
- Guest is `GuideTextButton`: `TypeRole.buttonTertiary` (16 regular), underlined, `palette.textPrimary` / `ink` (not dim caption).
- Legal footnote: `TypeRole.caption()` (12 regular) in `palette.dim`. Links are underlined; `tint` is `palette.ink` (not accent text). Two fixed lines, names “Terms & Conditions” and “Privacy Policy”.

## Copy (verbatim)

Quote (display, with typographic quotes and a line break):

```
“A chain that links
heaven and earth”
```

Attribution: `Attributed to St Thérèse of Lisieux`

Google pill: `Continue with Google` (or `Signing in` while in progress).

Guest: `Continue as guest`  
Accessibility: `Continue as guest. You can sign in later in Settings`

Legal:

```
By continuing you agree to our
Terms & Conditions and Privacy Policy.
```

URLs: `https://xult.ltd/terms/` and `https://xult.ltd/privacy/`.

iOS also has `Continue with Apple`. **Android v1 omits Apple** (product rule). Do not add it.

## M3 mapping

| iOS | Android |
| --- | --- |
| `OnboardingPanel` + `RosaryBeadsFallPlayer` (custom) | Same custom panel / Lottie (pixel-faithful) |
| Apple `OnboardingAuthButton` | Omitted on Android v1 |
| Google `OnboardingAuthButton` | `GuideGoogleButton` (M3 `OutlinedButton`) with official colours and regular 16 pt label |
| `GuideTextButton` guest | Clickable underlined 16 pt `Text` in `ink` |
| Legal `AttributedString` links | `LinkAnnotation` / `ClickableText`, caption 12, dim, links ink + underline |
