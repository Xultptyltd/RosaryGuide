import SwiftUI

/// Stained-glass placeholder art until commissioned sacred images replace it.
struct MysteryArtworkView: View {
    var set: MysterySetKind
    var mysteryNumber: Int?
    var showsCaption: Bool = true

    var body: some View {
        VStack(spacing: 8) {
            Canvas { context, size in
                drawGlass(in: &context, size: size)
            }
            .aspectRatio(4 / 3, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(AppTheme.gold.opacity(0.55), lineWidth: 1)
            }
            .accessibilityLabel(Text(accessibilityLabel))

            if showsCaption {
                Text("Art placeholder")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
        }
    }

    private var accessibilityLabel: String {
        if let mysteryNumber {
            return "Placeholder artwork for mystery \(mysteryNumber) of the \(set.name.english)"
        }
        return "Placeholder artwork for the \(set.name.english)"
    }

    private func drawGlass(in context: inout GraphicsContext, size: CGSize) {
        let palette = palette(for: set)
        let rect = CGRect(origin: .zero, size: size)
        context.fill(Path(rect), with: .color(palette.background))

        let columns = 5
        let rows = 4
        let cellW = size.width / CGFloat(columns)
        let cellH = size.height / CGFloat(rows)
        let seed = (mysteryNumber ?? 0) + {
            switch set {
            case .joyful: 1
            case .sorrowful: 2
            case .glorious: 3
            case .luminous: 4
            }
        }()

        for row in 0..<rows {
            for col in 0..<columns {
                var cell = CGRect(x: CGFloat(col) * cellW, y: CGFloat(row) * cellH, width: cellW, height: cellH).insetBy(dx: 3, dy: 3)
                let index = (row * columns + col + seed).magnitude
                let color = palette.tiles[Int(index) % palette.tiles.count]
                var path = Path(roundedRect: cell, cornerRadius: 4)
                if (row + col + (mysteryNumber ?? 0)).isMultiple(of: 2) {
                    path = Path(ellipseIn: cell.insetBy(dx: 6, dy: 4))
                }
                context.fill(path, with: .color(color.opacity(0.9)))
                context.stroke(path, with: .color(AppTheme.deepNavy.opacity(0.45)), lineWidth: 1.2)
            }
        }

        let emblem = CGRect(
            x: size.width * 0.32,
            y: size.height * 0.22,
            width: size.width * 0.36,
            height: size.height * 0.56
        )
        var emblemPath = Path(ellipseIn: emblem)
        context.fill(emblemPath, with: .color(palette.emblem.opacity(0.88)))
        context.stroke(emblemPath, with: .color(AppTheme.gold), lineWidth: 3)

        let crossArm = CGRect(x: emblem.midX - 6, y: emblem.minY + 18, width: 12, height: emblem.height - 36)
        let crossBeam = CGRect(x: emblem.minX + 28, y: emblem.midY - 18, width: emblem.width - 56, height: 12)
        context.fill(Path(crossArm), with: .color(AppTheme.gold))
        context.fill(Path(crossBeam), with: .color(AppTheme.gold))

        if let mysteryNumber {
            let text = Text("\(mysteryNumber)")
                .font(.system(size: min(size.width, size.height) * 0.16, weight: .semibold, design: .serif))
                .foregroundColor(AppTheme.ivory)
            context.draw(text, at: CGPoint(x: size.width / 2, y: size.height * 0.86))
        }
    }

    private func palette(for set: MysterySetKind) -> (background: Color, tiles: [Color], emblem: Color) {
        switch set {
        case .joyful:
            return (Color(red: 0.45, green: 0.22, blue: 0.30), [
                Color(red: 0.86, green: 0.62, blue: 0.68),
                Color(red: 0.72, green: 0.38, blue: 0.44),
                Color(red: 0.94, green: 0.84, blue: 0.70),
                AppTheme.gold
            ], Color(red: 0.55, green: 0.18, blue: 0.28))
        case .sorrowful:
            return (Color(red: 0.22, green: 0.08, blue: 0.12), [
                Color(red: 0.42, green: 0.12, blue: 0.16),
                Color(red: 0.28, green: 0.10, blue: 0.18),
                Color(red: 0.55, green: 0.22, blue: 0.22),
                Color(red: 0.62, green: 0.50, blue: 0.28)
            ], Color(red: 0.32, green: 0.08, blue: 0.12))
        case .glorious:
            return (Color(red: 0.12, green: 0.18, blue: 0.38), [
                AppTheme.gold,
                Color(red: 0.95, green: 0.90, blue: 0.72),
                Color(red: 0.20, green: 0.32, blue: 0.58),
                Color(red: 0.72, green: 0.58, blue: 0.22)
            ], AppTheme.marianBlue)
        case .luminous:
            return (Color(red: 0.16, green: 0.22, blue: 0.18), [
                Color(red: 0.92, green: 0.78, blue: 0.32),
                Color(red: 0.98, green: 0.93, blue: 0.70),
                Color(red: 0.35, green: 0.50, blue: 0.38),
                AppTheme.gold
            ], Color(red: 0.22, green: 0.34, blue: 0.28))
        }
    }
}

struct SeasonBadge: View {
    var season: LiturgicalSeason
    var language: PrayerLanguage

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(AppTheme.color(for: season))
                .frame(width: 10, height: 10)
                .overlay { Circle().strokeBorder(.primary.opacity(0.2), lineWidth: 0.5) }
            Text(season.name.primary(for: language))
                .font(.subheadline.weight(.semibold))
            Text(season.liturgicalColorName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
    }
}

struct BilingualStack: View {
    var text: BilingualText
    var language: PrayerLanguage
    var font: Font = .body
    var alignment: TextAlignment = .leading

    var body: some View {
        VStack(alignment: alignment == .center ? .center : .leading, spacing: 12) {
            Text(text.primary(for: language))
                .font(font)
                .multilineTextAlignment(alignment)
            if language == .bilingual {
                Text(text.latin)
                    .font(font)
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(alignment)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    }
}
