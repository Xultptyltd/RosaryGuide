import SwiftUI

struct MysteryArtworkView: View {
    var set: MysterySetKind
    var mysteryNumber: Int?
    var slug: String?
    var kind: Kind = .plate

    enum Kind { case plate, plateWide, heroTall, heroWide }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.palette) private var palette

    var body: some View {
        GeometryReader { geo in
            let wide = kind == .plateWide || kind == .heroWide || geo.size.width > geo.size.height * 1.15
            bundleImage(wide: wide)
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
    private func bundleImage(wide: Bool) -> some View {
        switch kind {
        case .heroTall, .heroWide:
            let path = ArtCatalog.heroPath(set: set, scheme: colorScheme, tall: kind == .heroTall || !wide)
            FocusedRasterImage(
                directory: path.directory,
                name: path.name,
                focus: UnitPoint(x: 0.5, y: kind == .heroTall || !wide ? 0.28 : 0.42)
            )
        case .plate, .plateWide:
            if let slug {
                let path = ArtCatalog.platePath(set: set, slug: slug, scheme: colorScheme, wide: kind == .plateWide || wide)
                let number = mysteryNumber ?? 1
                FocusedRasterImage(
                    directory: path.directory,
                    name: path.name,
                    focus: (kind == .plateWide || wide) ? ArtCatalog.bandFocus(set: set, number: number) : ArtCatalog.focus(set: set, number: number)
                )
                .overlay { plateScrim }
            } else {
                palette.card2
            }
        }
    }

    private var plateScrim: some View {
        let fade = kind == .plateWide ? palette.bg : palette.card
        return LinearGradient(
            stops: [
                .init(color: fade.opacity(0.28), location: 0),
                .init(color: .clear, location: 0.22),
                .init(color: .clear, location: 0.62),
                .init(color: fade.opacity(0.92), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
                LinearGradient(
                    stops: [
                        .init(color: scrim.opacity(0.55), location: 0),
                        .init(color: scrim.opacity(0.12), location: 0.08),
                        .init(color: .clear, location: 0.22),
                        .init(color: .clear, location: 0.78),
                        .init(color: scrim.opacity(0.55), location: 0.92),
                        .init(color: scrim, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
    }

    private var scrim: Color {
        colorScheme == .light ? .white : AppTheme.darkBg
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
                .font(AppTheme.sans(13, weight: .medium))
            Text(season.liturgicalColorName)
                .font(AppTheme.sans(12))
                .foregroundStyle(palette.dim)
        }
        .foregroundStyle(palette.ink)
    }
}

struct BilingualStack: View {
    var text: BilingualText
    var language: PrayerLanguage
    var font: Font = AppTheme.serif(21)
    var alignment: TextAlignment = .leading
    @Environment(\.palette) private var palette

    var body: some View {
        if language == .bilingual {
            HStack(alignment: .top, spacing: 22) {
                Text(text.english)
                    .font(font)
                    .foregroundStyle(palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(text.latin)
                    .font(font)
                    .italic()
                    .foregroundStyle(palette.dim)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else if language == .latin {
            Text(text.latin)
                .font(font)
                .italic()
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(alignment)
                .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
        } else {
            Text(text.english)
                .font(font)
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(alignment)
                .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
        }
    }
}

struct Hairline: View {
    @Environment(\.palette) private var palette
    var body: some View {
        Rectangle()
            .fill(palette.hair)
            .frame(height: 1)
    }
}

struct PillButton: View {
    var title: String
    var filled: Bool = true
    var action: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.sans(16, weight: filled ? .semibold : .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(filled ? palette.accent : Color.clear, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(filled ? Color.clear : palette.dim.opacity(0.45), lineWidth: 1)
                }
                .foregroundStyle(filled ? palette.onAccent : palette.ink)
        }
        .buttonStyle(.plain)
    }
}
