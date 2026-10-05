import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Compact circle icon: mystery-set letter on a soft fill (Learn list rows).
struct MysterySetLetterIcon: View {
    var set: MysterySetKind
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(set.letterFill)
            Text(set.letter)
                .font(AppTheme.TypeRole.avatarLetter(for: size))
                .foregroundStyle(set.letterOn)
        }
        .frame(width: size, height: size)
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

struct PillButton: View {
    var title: String
    var filled: Bool = true
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
                .font(AppTheme.TypeRole.callout(weight: filled ? .semibold : .medium))
                .foregroundStyle(filled ? palette.primaryButtonText : palette.learnMoreButtonText)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Component.pillHeight)
                .background(filled ? palette.primaryButtonFill : palette.learnMoreButtonFill, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
