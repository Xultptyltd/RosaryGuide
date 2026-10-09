import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Shared mystery avatar for Learn and Journey History.
struct MysterySetIcon: View {
    let set: MysterySetKind

    var body: some View {
        ZStack {
            Circle().fill(set.letterFill)
            MysterySetLineGlyph(set: set)
                .stroke(style: AppTheme.MysteryIcon.strokeStyle)
                .frame(width: AppTheme.MysteryIcon.glyphSize, height: AppTheme.MysteryIcon.glyphSize)
                .foregroundStyle(set.letterOn)
        }
        .frame(width: AppTheme.MysteryIcon.circleSize, height: AppTheme.MysteryIcon.circleSize)
        .accessibilityHidden(true)
    }
}

struct MysteryArtworkView: View {
    var set: MysterySetKind
    var mysteryNumber: Int?
    var slug: String?
    var kind: Kind = .plate
    /// Soft bottom dissolve into the surrounding card. Off for a hard image/body edge.
    var bottomFade: Bool = true
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
        .accessibilityLabel(Text(label))
    }

    private var label: String {
        if let mysteryNumber {
            return "\(set.shortName) mystery \(mysteryNumber)"
        }
        return "\(set.shortName) mysteries"
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
                    focus: wide ? ArtCatalog.bandFocus(set: set, number: number) : ArtCatalog.focus(set: set, number: number)
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
        HStack(spacing: 8) {
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
        .padding(.horizontal, 12)
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
        if language == .bilingual {
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
            prayerColumn(text.latin, color: palette.ink, italic: false)
        } else {
            prayerColumn(text.english, color: palette.ink, italic: false)
        }
    }

    @ViewBuilder
    private func prayerColumn(_ raw: String, color: Color, italic: Bool) -> some View {
        let paras = raw.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        VStack(alignment: alignment == .center ? .center : .leading, spacing: 32) { // prayer paragraph gap
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

/// Shared full-bleed section boundary with 16pt clear space on both sides.
struct GuideSectionBoundary: View {
    var gutter: CGFloat = AppTheme.gutter
    var body: some View {
        GuideSectionDivider()
            .padding(.horizontal, -gutter)
            .padding(.vertical, AppTheme.Space.lg)
    }
}

/// Section label row used with `GuideSectionDivider` for count headings such as
/// "Featured (4)" while staying on the app typography and colour token paths.
struct GuideDividerSectionHeader: View {
    @Environment(\.palette) private var palette
    var title: String
    var count: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            GuideSectionDivider()
            GuideSectionLabel(text: label, prominence: .strong)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var label: String {
        guard let count else { return title }
        return "\(title) (\(count))"
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
struct GuideTextButtonLabel: View {
    let title: String
    var fillsWidth = true
    @Environment(\.palette) private var palette

    var body: some View {
        Text(title)
            .font(AppTheme.TypeRole.buttonTertiary)
            .underline()
            .foregroundStyle(palette.textPrimary)
            .multilineTextAlignment(.leading)
            .padding(.vertical, AppTheme.Component.textButtonVerticalPadding)
            .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .leading)
            .contentShape(Rectangle())
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
                .font(AppTheme.TypeRole.callout)
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
