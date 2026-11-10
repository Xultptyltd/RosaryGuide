# Accessibility notes

This is not a claim of full accessibility compliance. Layout, contrast and VoiceOver work continue; the notes below record known audit gaps so they are not ignored casually.

## Unbindable Pray hit-region audit

`performAccessibilityAudit` on the default-size prayer flow still reports one “Hit area is too small” issue whose `XCUIElement` does not bind: the element is nil or type 0, the frame is infinite or 0×0, and the label is empty. There is no element screenshot.

What was already fixed or ruled out:

- The reserved language-toggle spacer and the 0-pt UIKit scheme-sync and navigation-font probes (those were the 0×0 Others at the centre of the screen).
- Prayer chrome buttons now use a 44 pt hit frame.
- System scroll-indicator thumbs are hidden on prayer text views.
- Decorative scroll-anchor `Color.clear`s and measurement probes are hidden from accessibility.
- A 0-pt tab-bar `safeAreaInset` is no longer installed (it created a 440×0 `TouchBlocker`).
- The tab interface is hidden from accessibility while the prayer cover is open.

An in-app walk of UIKit `accessibilityElements` found no bindable, unlabelled hit target that matched the issue. The UI tests ignore only this unbindable hit-region node — not hit-area failures with a real label or a measurable frame.

Custom-font contrast flags on Home (mystery titles, theme summary / date, “Today’s mysteries”, Appearance “Light” / “Dark”) were measured against screenshot pixels and remain above WCAG AA; those are ignored only as documented false positives in `AccessibilityAuditUITests`.

## What the tokens provide automatically

Using a design-system path picks up the behaviour below. This is still not a claim of full accessibility compliance.

**Automatic when you use the token or shared component**

- `AppTheme.TypeRole` fonts (and `AppTheme.sans` / `serif`) scale with Dynamic Type through `UIFontMetrics` and are not capped.
- Colour tokens on `ThemePalette`, including `textSecondary` (`#5C5C5C` in light) and `success` for toggle tints.
- `GuideChoiceControl` becomes a vertical stack of full-width buttons at accessibility sizes, and its padding uses `Space.scaled` (capped at 1.5×). At the default Large size those paddings match the design constants.
- `guidePressable()` / `GuidePressStyle` apply a 44 pt minimum hit target. Pill buttons use `frame(minHeight: Component.pillHeight)` so the label can grow.
- `guideAnimation(_:value:)` and `Motion.animation(_:reduceMotion:)` honour Reduce Motion. Prefer these over a local check.
- `WordSafeText` / `GuideWrappingText` wrap long words at accessibility sizes and expose a VoiceOver label, but only where they are used.
- `guideTabBarPadding()` clears the tab bar on a `ScrollView` that opts in. The extra margin is a fixed `Space` value (not scaled, so art and chrome stay put).

**Each screen still has to do**

- HStack-to-VStack (or other) reflow at accessibility sizes, except inside `GuideChoiceControl`.
- VoiceOver labels, hints, traits, and hiding decorative views, except on shared components that already set them.
- Text-adjacent padding should use `Space.scaled` or `guidePadding`. Leave raw `Space` constants for art frames and fixed chrome.
- Unscaled `Space` values do not grow with Dynamic Type. That is deliberate, so artwork is not stretched at AX5.

`DesignSystemGuardTests` fails the suite if a `RosaryGuide/` source bypasses these rules (system fonts, un-relative custom fonts, `Color(hex:)` or `Color(uiColor: .system…)` outside the theme, exact `frame(height: Component.pillHeight)`).
