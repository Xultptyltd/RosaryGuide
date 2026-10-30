import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Shared mystery avatar for Learn and Journey History.
struct MysterySetIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    let set: MysterySetKind
    var size: CGFloat = AppTheme.MysteryIcon.circleSize

    var body: some View {
        let dark = colorScheme == .dark
        ZStack {
            Circle().fill(dark ? set.letterFill.opacity(0.18) : set.letterFill)
            Image(set.iconAssetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size * AppTheme.MysteryIcon.assetRatio, height: size * AppTheme.MysteryIcon.assetRatio)
                .foregroundStyle(dark ? set.letterFill : set.letterOn)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Filled intention glyph from the asset catalog, or the line glyph where no asset exists.
struct IntentionGlyphImage: View {
    let glyph: AppTheme.IntentionIcon.Glyph
    let size: CGFloat

    var body: some View {
        if let name = AppTheme.IntentionIcon.assetName(for: glyph) {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            IntentionLineGlyph(glyph: glyph)
                .stroke(style: AppTheme.LineIcon.strokeStyle)
                .frame(width: size * AppTheme.LineIcon.glyphRatio / AppTheme.MysteryIcon.assetRatio,
                       height: size * AppTheme.LineIcon.glyphRatio / AppTheme.MysteryIcon.assetRatio)
        }
    }
}

struct MysteryArtworkView: View {
    var set: MysterySetKind
    var mysteryNumber: Int?
    var slug: String?
    var kind: Kind = .plate
    /// Soft bottom dissolve into the surrounding card. Off for a hard image/body edge.
    var bottomFade: Bool = true
    /// Use scene-specific framing for the Home mystery cards.
    var cardFraming: Bool = false
    /// Finish hero only. Top of the visible image, as a fraction of the artwork.
    var cropTop: CGFloat? = nil

    enum Kind { case plate, plateWide, heroTall, heroWide }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.palette) private var palette

    var body: some View {
        GeometryReader { geo in
            bundleImage()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        // Decorative: titles and buttons around the art name the mystery.
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func bundleImage() -> some View {
        switch kind {
        case .heroTall, .heroWide:
            let tall = kind == .heroTall
            let path = ArtCatalog.heroPath(set: set, scheme: colorScheme, tall: tall)
            FocusedRasterImage(
                directory: path.directory,
                name: path.name,
                focus: UnitPoint(x: 0.5, y: tall ? 0.28 : 0.42),
                cropTop: tall ? cropTop : nil
            )
        case .plate, .plateWide:
            if let slug {
                let wide = kind == .plateWide
                let path = ArtCatalog.platePath(set: set, slug: slug, scheme: colorScheme, wide: wide)
                let number = mysteryNumber ?? 1
                FocusedRasterImage(
                    directory: path.directory,
                    name: path.name,
                    focus: cardFraming ? ArtCatalog.cardFocus(set: set, number: number) : (wide ? ArtCatalog.bandFocus(set: set, number: number) : ArtCatalog.focus(set: set, number: number))
                )
                .overlay { plateScrim }
            } else {
                palette.surface
            }
        }
    }

    private var plateScrim: some View {
        let fade = kind == .plateWide ? palette.bg : palette.surface
        let stops: [Gradient.Stop] = bottomFade
            ? [
                .init(color: fade.opacity(0.28), location: 0),
                .init(color: .clear, location: 0.22),
                .init(color: .clear, location: 0.62),
                .init(color: fade.opacity(0.92), location: 1)
            ]
            : [
                .init(color: fade.opacity(0.22), location: 0),
                .init(color: .clear, location: 0.28),
                .init(color: .clear, location: 1)
            ]
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
            .allowsHitTesting(false)
    }
}

struct PlateArtView: View {
    var fitsArtwork: Bool = false
    var fitAlignment: Alignment = .top
    var mystery: Mystery
    var wide: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let path = ArtCatalog.platePath(
            set: mystery.set,
            slug: mystery.artSlug,
            scheme: colorScheme,
            wide: wide
        )
        FocusedRasterImage(
            contentMode: fitsArtwork ? .fit : .fill,
            fitAlignment: fitAlignment,
            directory: path.directory,
            name: path.name,
            focus: wide ? ArtCatalog.bandFocus(set: mystery.set, number: mystery.number) : ArtCatalog.focus(set: mystery.set, number: mystery.number)
        )
            .overlay {
                // Top vignette only — bottom dissolve is owned by the pray hero so fills match.
                LinearGradient(
                    stops: [
                        .init(color: scrim.opacity(0.55), location: 0),
                        .init(color: scrim.opacity(0.12), location: 0.1),
                        .init(color: .clear, location: 0.28),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
    }

    private var scrim: Color {
        Color(uiColor: .systemBackground)
    }
}

struct SeasonBadge: View {
    var season: LiturgicalSeason
    var language: PrayerLanguage
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: AppTheme.Space.sm) {
            Circle()
                .fill(AppTheme.color(for: season))
                .frame(width: 8, height: 8)
            Text(season.name.primary(for: language))
                .font(AppTheme.TypeRole.label(weight: .medium))
            Text(season.liturgicalColorName)
                .font(AppTheme.TypeRole.caption)
                .foregroundStyle(palette.dim)
        }
        .foregroundStyle(palette.ink)
        .padding(.horizontal, AppTheme.Space.md)
        .padding(.vertical, 7)
        .background(palette.surface, in: Capsule())
    }
}

struct BilingualStack: View {
    var text: BilingualText
    var language: PrayerLanguage
    var font: Font = AppTheme.TypeRole.body
    /// Point size used when targeting CSS line-height 1.85.
    var pointSize: CGFloat = 21
    var alignment: TextAlignment = .leading
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Generous prayer reading line height using the app sans text system.
    private var lineExtra: CGFloat {
        #if canImport(UIKit)
        let ui = FontRegistrar.sansUI(pointSize)
        let scale = ui.pointSize > 0.1 ? (pointSize / ui.pointSize) : 1
        let native = ui.lineHeight * scale
        return max(0, pointSize * 1.65 - native)
        #else
        return max(0, pointSize * 0.45)
        #endif
    }

    var body: some View {
        if language == .bilingual && text.hasDistinctLatin {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: alignment == .center ? .center : .leading, spacing: AppTheme.Space.xl) {
                    prayerColumn(text.english, color: palette.ink, italic: false)
                    prayerColumn(text.latin, color: palette.dim, italic: false)
                }
            } else {
                HStack(alignment: .top, spacing: AppTheme.Space.xl) {
                    prayerColumn(text.english, color: palette.ink, italic: false)
                    prayerColumn(text.latin, color: palette.dim, italic: false)
                }
            }
        } else if language == .latin {
            prayerColumn(text.latinOrEnglish, color: palette.ink, italic: false)
        } else {
            prayerColumn(text.english, color: palette.ink, italic: false)
        }
    }

    @ViewBuilder
    private func prayerColumn(_ raw: String, color: Color, italic: Bool) -> some View {
        let paras = raw.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        VStack(alignment: alignment == .center ? .center : .leading, spacing: AppTheme.Space.xxl) { // prayer paragraph gap
            ForEach(Array(paras.enumerated()), id: \.offset) { _, para in
                Text(Self.joinedLines(para))
                    .font(font)
                    .italic(italic)
                    .foregroundStyle(color)
                    .lineSpacing(lineExtra)
                    .multilineTextAlignment(alignment)
                    .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension BilingualStack {
    /// Source line breaks are soft and become spaces, except before a
    /// versicle (V.) or response (R.) line, which always starts its own line.
    static func joinedLines(_ para: String) -> String {
        let lines = para.components(separatedBy: "\n")
        var out = ""
        for (i, line) in lines.enumerated() {
            if i > 0 {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let isVersicleOrResponse = ["V.", "R.", "℣", "℟"].contains { trimmed.hasPrefix($0) }
                out += isVersicleOrResponse ? "\n" : " "
            }
            out += line
        }
        return out
    }
}

struct Hairline: View {
    @Environment(\.palette) private var palette
    var body: some View {
        Rectangle()
            .fill(palette.hair)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

/// Shared section divider using the surface colour token and mirrored PNG endpoints.
struct GuideSectionDivider: View {
    @Environment(\.palette) private var palette
    var inset: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            endpoint("SectionDividerLeft")
            Rectangle()
                .fill(fill)
                .frame(height: AppTheme.Component.sectionDividerHeight)
            endpoint("SectionDividerRight")
        }
        .padding(.horizontal, inset)
        .frame(maxWidth: .infinity)
        .frame(height: AppTheme.Component.sectionDividerEndpointHeight)
        .accessibilityHidden(true)
    }

    private func endpoint(_ name: String) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .foregroundStyle(fill)
            .frame(width: AppTheme.Component.sectionDividerEndpointWidth,
                   height: AppTheme.Component.sectionDividerEndpointHeight)
    }

    private var fill: Color { palette.surface }
}

/// Shared full-bleed section boundary with 16pt clear space above and below.
struct GuideSectionBoundary: View {
    var gutter: CGFloat = AppTheme.gutter
    /// Set to zero when the enclosing stack already supplies the section spacing.
    var verticalSpacing: CGFloat = AppTheme.Space.lg
    var body: some View {
        GuideSectionDivider()
            .padding(.horizontal, -gutter)
            .padding(.vertical, verticalSpacing)
    }
}

// MARK: - Row dividers (no hairline under the last row)

extension EnvironmentValues {
    /// Whether a list row draws its bottom divider. `DividedRows` sets this to
    /// false for its last row, so lists never end on a hairline.
    @Entry var showsRowDivider: Bool = true
}

/// Vertical list of rows that draw their own bottom divider (via
/// `rowBottomDivider()` or a divider reading `showsRowDivider`). Every row
/// except the last keeps its divider; conditional rows are handled because the
/// last row is resolved from the actual subviews.
struct DividedRows<Content: View>: View {
    var alignment: HorizontalAlignment = .center
    var spacing: CGFloat = 0
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            Group(subviews: content) { subviews in
                let lastID = subviews.last?.id
                ForEach(subviews) { subview in
                    subview.environment(\.showsRowDivider, subview.id != lastID)
                }
            }
        }
    }
}

private struct RowBottomDivider: ViewModifier {
    @Environment(\.showsRowDivider) private var showsRowDivider

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if showsRowDivider {
                Hairline()
            }
        }
    }
}

extension View {
    /// Bottom hairline for a list row; hidden on the last row of a `DividedRows`.
    func rowBottomDivider() -> some View {
        modifier(RowBottomDivider())
    }
}

/// Shared label for plain text actions; the enclosing Button owns its action.
/// Underlined text-button label. Sized to its text; it never stretches, so it
/// can't widen a hit area. Use `GuideTextButton` for a tappable text button.
struct GuideTextButtonLabel: View {
    let title: String
    @Environment(\.palette) private var palette

    var body: some View {
        Text(title)
            .font(AppTheme.TypeRole.buttonTertiary)
            .underline()
            .foregroundStyle(palette.textPrimary)
            .multilineTextAlignment(.leading)
            .padding(.vertical, AppTheme.Component.textButtonVerticalPadding)
    }
}

/// The one text / link button. Tap area is the label plus `hitSlop` (12pt) on
/// every side; negative padding keeps the visual position unchanged. Alignment
/// in the row is done outside the hit area (`alignment`), never by stretching it.
struct GuideTextButton: View {
    let title: String
    var accessibilityLabel: String?
    /// Leading / trailing placement in the row; nil = sized to content only.
    var alignment: Alignment? = .leading
    let action: () -> Void

    static let hitSlop: CGFloat = AppTheme.Space.md

    var body: some View {
        let button = Button(action: action) {
            GuideTextButtonLabel(title: title)
                .padding(Self.hitSlop)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .guidePressable()
        .accessibilityLabel(accessibilityLabel ?? title)
        .padding(-Self.hitSlop)

        if let alignment {
            // The frame has no content shape, so the extra width isn't tappable.
            button.frame(maxWidth: .infinity, alignment: alignment)
        } else {
            button
        }
    }
}

/// Shared circle-to-pill action used by scrolling prayers and learning guides.
struct GuideScrollActionButton: View {
    var showScroll: Bool
    var title: String
    var scrollLabel: String
    var primary: Bool = false
    /// Pushes the circle to the trailing edge. Off when it shares a row with another button.
    var pinsTrailing: Bool = true
    var onScroll: () -> Void
    var onAdvance: () -> Void
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack {
            if showScroll && pinsTrailing { Spacer(minLength: 0) }
            Button(action: showScroll ? onScroll : onAdvance) {
                let side = AppTheme.Component.mysteryPlateActionCircle
                ZStack {
                    Capsule().fill(primary && !showScroll ? palette.primaryButtonFill : palette.secondaryButtonFill)
                    if showScroll {
                        Image(systemName: "chevron.down")
                            .guideSymbol(size: 17, weight: .semibold)
                            .foregroundStyle(palette.secondaryButtonText)
                            .transition(.identity)
                    } else {
                        Text(title)
                            .font(AppTheme.TypeRole.pillLabel())
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(primary ? palette.primaryButtonText : palette.secondaryButtonText)
                            .transition(.identity)
                    }
                }
                .frame(maxWidth: showScroll ? side : .infinity)
                .frame(width: showScroll ? side : nil, height: AppTheme.Component.pillHeight)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showScroll ? scrollLabel : title)
        }
        .animation(reduceMotion ? nil : MotionTokens.reveal, value: showScroll)
    }
}

struct PillButton: View {
    var title: String
    var filled: Bool = true
    /// Tertiary token (surface fill). Only read when `filled` is false.
    var tertiary: Bool = false
    var action: () -> Void
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        Button {
            HapticService.play(.light, enabled: settings.hapticsEnabled)
            action()
        } label: {
            Text(title)
                .font(AppTheme.TypeRole.pillLabel())
                .foregroundStyle(filled ? palette.primaryButtonText : (tertiary ? palette.tertiaryButtonText : palette.learnMoreButtonText))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Component.pillHeight)
                .background(filled ? palette.primaryButtonFill : (tertiary ? palette.tertiaryButtonFill : palette.learnMoreButtonFill), in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Shape adapter for the canonical theme paths.
struct MysterySetLineGlyph: Shape {
    let set: MysterySetKind

    func path(in rect: CGRect) -> Path {
        AppTheme.MysteryIcon.path(for: set, in: rect)
    }
}


/// Shape adapter for the shared intention paths.
struct IntentionLineGlyph: Shape {
    let glyph: AppTheme.IntentionIcon.Glyph

    func path(in rect: CGRect) -> Path {
        AppTheme.IntentionIcon.path(for: glyph, in: rect)
    }
}


struct MilestoneLineGlyph: Shape {
    let glyph: AppTheme.MilestoneIcon.Glyph
    func path(in rect: CGRect) -> Path {
        AppTheme.MilestoneIcon.path(for: glyph, in: rect)
    }
}

/// Shared progress treatment for the Home mystery rail and teaching walkthrough.
struct GuidePageDots: View {
    var current: Int
    var count: Int
    var alignment: Alignment = .leading
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: AppTheme.Space.sm) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? palette.accent : palette.accent.opacity(0.28))
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Screen \(current + 1) of \(count)")
    }
}

/// A quiet notice that something could not sync. Shown for real failures, never for being
/// offline or for changes still waiting to upload.
struct SyncNotice: View {
    @Environment(\.palette) private var palette
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Space.sm) {
            Image(systemName: "exclamationmark.triangle")
                .guideSymbol(size: 14, weight: .medium)
                .foregroundStyle(palette.dim)

            Text(message)
                .font(AppTheme.TypeRole.caption())
                .foregroundStyle(palette.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Sync notice") {
    SyncNotice("Settings and prayer history are saved on this device but could not sync")
        .padding(AppTheme.Space.lg)
}

/// The "Fruit" line under a mystery: hairline, then label and fruit on one baseline.
/// Shared by the Rosary flow and the mystery screen opened from Home.
struct MysteryFruitLine: View {
    let fruit: String
    var isMystery: Bool = true
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: isMystery ? AppTheme.Space.sm : AppTheme.Space.md) {
            Hairline()
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.sm) {
                Text("Fruit")
                    .font(AppTheme.TypeRole.body(weight: .medium))
                    .tracking(isMystery ? AppTheme.RosaryFlow.fruitTracking : 0)
                    .foregroundStyle(palette.textSecondary)
                // Normal body size (Dynamic Type), same as the "Fruit" label; ink keeps it primary.
                Text(fruit)
                    .font(AppTheme.TypeRole.body)
                    .foregroundStyle(palette.ink)
            }
        }
    }
}
