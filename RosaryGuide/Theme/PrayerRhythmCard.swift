import SwiftUI

/// Streak and month summary derived from the prayed-day history.
struct PrayerRhythm: Equatable {
    /// Consecutive prayed days ending today, or yesterday when today is not prayed yet.
    var streak: Int
    var prayedToday: Bool
    /// Every day of this week so far (locale's first weekday through today) is prayed,
    /// and at least two days of the week have passed.
    var prayedEachDayThisWeek: Bool
    var monthName: String
    var prayedDaysThisMonth: Int
    /// Month grid in weeks of 7 cells; nil cells are blank (before the 1st / after the last day).
    var weeks: [[Day?]]

    struct Day: Equatable, Hashable {
        var number: Int
        var prayed: Bool
        var isToday: Bool
        var isFuture: Bool
    }

    init(prayedDayStarts: Set<TimeInterval>, now: Date = Date(), calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        func prayed(_ day: Date) -> Bool {
            prayedDayStarts.contains(calendar.startOfDay(for: day).timeIntervalSince1970)
        }

        prayedToday = prayed(today)
        var cursor = prayedToday ? today : (calendar.date(byAdding: .day, value: -1, to: today) ?? today)
        var count = 0
        while prayed(cursor), count < 400 {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        streak = count

        if let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start {
            let daysSoFar = (calendar.dateComponents([.day], from: weekStart, to: today).day ?? 0) + 1
            prayedEachDayThisWeek = daysSoFar >= 2 && streak >= daysSoFar
        } else {
            prayedEachDayThisWeek = false
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .current
        formatter.setLocalizedDateFormatFromTemplate("LLLL")
        monthName = formatter.string(from: today)

        var cells: [Day?] = []
        var monthCount = 0
        if let month = calendar.dateInterval(of: .month, for: today),
           let dayRange = calendar.range(of: .day, in: .month, for: today) {
            let leading = (calendar.component(.weekday, from: month.start) - calendar.firstWeekday + 7) % 7
            cells.append(contentsOf: Array(repeating: nil, count: leading))
            for offset in 0..<dayRange.count {
                guard let date = calendar.date(byAdding: .day, value: offset, to: month.start) else { continue }
                let isPrayed = prayed(date)
                if isPrayed { monthCount += 1 }
                cells.append(Day(
                    number: offset + 1,
                    prayed: isPrayed,
                    isToday: calendar.isDate(date, inSameDayAs: today),
                    isFuture: date > today
                ))
            }
            let trailing = (7 - cells.count % 7) % 7
            cells.append(contentsOf: Array(repeating: nil, count: trailing))
        }
        prayedDaysThisMonth = monthCount
        weeks = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<min($0 + 7, cells.count)]) }
    }

    /// Some prayer to show: a prayed day in the shown month or a live streak.
    /// Drives the tick in the card's calendar icon.
    var hasPrayed: Bool { streak > 0 || prayedDaysThisMonth > 0 }

    var streakText: String { streak == 1 ? "1 day" : "\(streak) days" }

    var caption: String {
        if streak == 0 { return "Start your rhythm today" }
        if prayedToday && prayedEachDayThisWeek { return "Every day this week" }
        if prayedToday { return "See you tomorrow" }
        return "Pray today to keep it"
    }

    var accessibilityLabel: String {
        let days = prayedDaysThisMonth == 1 ? "1 day" : "\(prayedDaysThisMonth) days"
        return "Prayer rhythm, \(streak) day streak, prayed \(days) in \(monthName). \(caption)."
    }
}

/// "Your prayer rhythm" card: current streak on the left, this month's prayed days
/// as a dot grid on the right (prayed = glowing accent, missed = grey, future = darker grey).
/// Proportions follow the design mockup (436 x 172 at ~0.85pt per px).
struct PrayerRhythmCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var rhythm: PrayerRhythm

    private enum Metric {
        static let radius: CGFloat = AppTheme.containerRadius
        static let horizontalPadding: CGFloat = 20
        static let topPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 16
        static let iconSize = CGSize(width: 24, height: 26)
        static let iconToText: CGFloat = 14
        static let columnGap: CGFloat = 8
        static let dotSize: CGFloat = 8
        static let dotColumnSpacing: CGFloat = 8
        static let dotRowSpacing: CGFloat = 9
        static let headerGlyph = CGSize(width: 16, height: 18)
    }

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Group {
            if dynamicTypeSize < .xxLarge {
                sideBySide
            } else {
                stacked
            }
        }
        .padding(.horizontal, Metric.horizontalPadding)
        .padding(.top, Metric.topPadding)
        .padding(.bottom, Metric.bottomPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { cardSurface }
        .clipShape(RoundedRectangle(cornerRadius: Metric.radius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rhythm.accessibilityLabel)
    }

    /// Mockup layout: icon top-left with the text block bottom-aligned under it;
    /// month header level with the icon and the dot grid level with the text.
    private var sideBySide: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                icon
                Spacer(minLength: Metric.iconToText)
                summaryText
            }
            .frame(maxHeight: .infinity, alignment: .leading)
            .layoutPriority(1)

            Spacer(minLength: Metric.columnGap)

            VStack(alignment: .leading, spacing: 0) {
                monthHeader
                    .frame(height: Metric.iconSize.height)
                Spacer(minLength: Metric.iconToText)
                dotGrid
                    .padding(.bottom, 3)
            }
            .frame(maxHeight: .infinity)
            .fixedSize(horizontal: true, vertical: false)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Larger text: the month sits under the summary so nothing truncates.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: 0) {
            icon
            summaryText
                .padding(.top, Metric.iconToText)
            monthHeader
                .padding(.top, AppTheme.Space.xl)
            dotGrid
                .padding(.top, AppTheme.Space.md)
        }
    }

    // MARK: Surface

    /// Flat surface token, same as the other cards on My prayer.
    private var cardSurface: some View {
        RoundedRectangle(cornerRadius: Metric.radius, style: .continuous)
            .fill(palette.surface)
    }

    // MARK: Left column

    private var icon: some View {
        CalendarCheckGlyph(showsCheck: rhythm.hasPrayed)
            .stroke(palette.ink.opacity(isDark ? 0.88 : 0.82),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            .frame(width: Metric.iconSize.width, height: Metric.iconSize.height)
    }

    private var summaryText: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your prayer rhythm")
                .font(AppTheme.sans(16, relativeTo: .callout))
                .foregroundStyle(palette.ink.opacity(isDark ? 0.9 : 0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(rhythm.streakText)
                .font(AppTheme.sans(32, relativeTo: .title))
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 2)

            // One line like the mockup; step down a point before wrapping.
            ViewThatFits(in: .horizontal) {
                caption(size: 14).lineLimit(1)
                caption(size: 13).lineLimit(1)
                caption(size: 13).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
        }
    }

    private func caption(size: CGFloat) -> some View {
        Text(rhythm.caption)
            .font(AppTheme.sans(size, relativeTo: .subheadline))
            .foregroundStyle(palette.ink.opacity(isDark ? 0.72 : 0.62))
    }

    // MARK: Right column

    private var monthHeader: some View {
        HStack(spacing: 12) {
            CalendarFilledGlyph()
                .foregroundStyle(palette.ink.opacity(isDark ? 0.86 : 0.78))
                .frame(width: Metric.headerGlyph.width, height: Metric.headerGlyph.height)
            Text(rhythm.monthName)
                .font(AppTheme.sans(15, relativeTo: .subheadline))
                .foregroundStyle(palette.ink.opacity(isDark ? 0.82 : 0.75))
                .lineLimit(1)
        }
    }

    private var dotGrid: some View {
        Grid(horizontalSpacing: Metric.dotColumnSpacing, verticalSpacing: Metric.dotRowSpacing) {
            ForEach(rhythm.weeks.indices, id: \.self) { row in
                GridRow {
                    ForEach(0..<7, id: \.self) { column in
                        dot(rhythm.weeks[row][column])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dot(_ day: PrayerRhythm.Day?) -> some View {
        let size = Metric.dotSize
        if let day {
            ZStack {
                if day.prayed {
                    // Soft halo, then a bright core fading out to the accent rim.
                    Circle()
                        .fill(palette.accent.opacity(isDark ? 0.45 : 0.30))
                        .frame(width: size + 6, height: size + 6)
                        .blur(radius: 2.5)
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.white.opacity(0.95), palette.accent.opacity(0.9), palette.accent],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        ))
                        .frame(width: size, height: size)
                } else {
                    Circle()
                        .fill(day.isFuture
                              ? palette.ink.opacity(isDark ? 0.13 : 0.08)
                              : palette.ink.opacity(isDark ? 0.30 : 0.20))
                        .frame(width: size, height: size)
                }
                if day.isToday {
                    Circle()
                        .strokeBorder(day.prayed ? palette.accent.opacity(0.7) : palette.ink.opacity(0.5), lineWidth: 1)
                        .frame(width: size + 6, height: size + 6)
                }
            }
            .frame(width: size, height: size)
        } else {
            Color.clear.frame(width: size, height: size)
        }
    }
}

/// Outline calendar: rounded body, header rule, two ring tabs, and a centred check
/// when `showsCheck`. Drawn on a 24 x 26 design box and scaled to the frame.
private struct CalendarCheckGlyph: Shape {
    var showsCheck = true

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 24, sy = rect.height / 26
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy) }
        var path = Path()
        path.addRoundedRect(
            in: CGRect(origin: p(0.8, 3.2), size: CGSize(width: 22.4 * sx, height: 22 * sy)),
            cornerSize: CGSize(width: 5 * sx, height: 5 * sy),
            style: .continuous
        )
        path.move(to: p(0.8, 9.2)); path.addLine(to: p(23.2, 9.2))
        path.move(to: p(7, 0.8)); path.addLine(to: p(7, 5.4))
        path.move(to: p(17, 0.8)); path.addLine(to: p(17, 5.4))
        if showsCheck {
            path.move(to: p(7.6, 17.2)); path.addLine(to: p(10.6, 20.2)); path.addLine(to: p(16.4, 14.2))
        }
        return path
    }
}

/// Filled calendar with a header rule and a grid of day marks knocked out.
private struct CalendarFilledGlyph: View {
    var body: some View {
        Canvas { context, size in
            let sx = size.width / 16, sy = size.height / 18
            func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: x * sx, y: y * sy, width: w * sx, height: h * sy)
            }
            let ink = GraphicsContext.Shading.foreground
            context.fill(Path(roundedRect: r(0, 2, 16, 16), cornerRadius: 3 * sx, style: .continuous), with: ink)
            context.fill(Path(roundedRect: r(3.4, 0, 1.8, 4), cornerRadius: 0.9 * sx), with: ink)
            context.fill(Path(roundedRect: r(10.8, 0, 1.8, 4), cornerRadius: 0.9 * sx), with: ink)
            context.blendMode = .destinationOut
            context.fill(Path(r(0, 5.6, 16, 1.2)), with: .color(.black))
            for row in 0..<3 {
                for column in 0..<4 {
                    let x = 2.6 + CGFloat(column) * 3.0
                    let y = 8.6 + CGFloat(row) * 2.9
                    context.fill(Path(r(x, y, 1.9, 1.7)), with: .color(.black))
                }
            }
        }
    }
}
