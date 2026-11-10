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
