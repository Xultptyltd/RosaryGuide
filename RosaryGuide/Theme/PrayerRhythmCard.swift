import SwiftUI

/// Streak, caption and month summary derived from the prayed-day history.
///
/// Big number: a daily run of 3+ days shows "N days"; otherwise the run of calendar
/// weeks (user's `firstWeekday`) with at least one prayed day shows "N weeks".
/// Captions follow a first-match rule table (see `caption`).
struct PrayerRhythm: Equatable {
    enum Unit: Equatable { case day, week }

    /// Consecutive prayed days ending today, or yesterday when today is not prayed yet.
    var dailyRun: Int
    /// Consecutive calendar weeks with at least one prayed day, ending this week, or
    /// last week when nothing is prayed yet this week.
    var weekRun: Int
    var prayedToday: Bool
    /// Distinct prayed days in the current calendar week (through today).
    var prayedDaysThisWeek: Int
    /// Any prayed day on or before today.
    var hasEverPrayed: Bool
    /// Prayed this week, nothing last week, and some prayer before that.
    var isWelcomeBack: Bool
    /// The number and unit the card shows big.
    var bigNumber: Int
    var unit: Unit
    var caption: String
    /// True when `caption` is a daily/week milestone (card shows a flame instead of the calendar).
    var isMilestone: Bool

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
        let todayStart = today.timeIntervalSince1970
        // Normalise to day starts; ignore anything after today.
        let prayedDays: Set<TimeInterval> = Set(prayedDayStarts.compactMap { start in
            let day = calendar.startOfDay(for: Date(timeIntervalSince1970: start)).timeIntervalSince1970
            return day <= todayStart ? day : nil
        })
        func prayed(_ day: Date) -> Bool {
            prayedDays.contains(calendar.startOfDay(for: day).timeIntervalSince1970)
        }
        func addDays(_ n: Int, to date: Date) -> Date {
            calendar.date(byAdding: .day, value: n, to: date) ?? date
        }
        func weekStart(_ date: Date) -> Date {
            calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        }
        func addWeeks(_ n: Int, to date: Date) -> Date {
            calendar.date(byAdding: .weekOfYear, value: n, to: date) ?? date
        }

        hasEverPrayed = !prayedDays.isEmpty

        // Daily run.
        prayedToday = prayed(today)
        var cursor = prayedToday ? today : addDays(-1, to: today)
        var days = 0
        while prayed(cursor), days < 400 {
            days += 1
            cursor = addDays(-1, to: cursor)
        }
        dailyRun = days
        let dailyRunStart = addDays(1, to: cursor)

        // Week run (calendar weeks with >= 1 prayed day).
        let prayedWeeks = Set(prayedDays.map { weekStart(Date(timeIntervalSince1970: $0)).timeIntervalSince1970 })
        let thisWeek = weekStart(today)
        prayedDaysThisWeek = prayedDays.filter { $0 >= thisWeek.timeIntervalSince1970 }.count
        let prayedThisWeek = prayedDaysThisWeek > 0
        var weekCursor = prayedThisWeek ? thisWeek : addWeeks(-1, to: thisWeek)
        var weeksCount = 0
        while prayedWeeks.contains(weekCursor.timeIntervalSince1970), weeksCount < 60 {
            weeksCount += 1
            weekCursor = addWeeks(-1, to: weekCursor)
        }
        weekRun = weeksCount
        let weekRunStartWeek = addWeeks(1, to: weekCursor).timeIntervalSince1970
        // First prayed day of the week run (for "Every week since <month>").
        let weekRunFirstDay = prayedDays.filter { $0 >= weekRunStartWeek }.min()
            .map { Date(timeIntervalSince1970: $0) } ?? today

        let hasPrayerBeforeThisWeek = prayedDays.contains { $0 < thisWeek.timeIntervalSince1970 }
        isWelcomeBack = prayedThisWeek && weekRun == 1 && hasPrayerBeforeThisWeek

        let monthFormatter = DateFormatter()
        monthFormatter.calendar = calendar
        monthFormatter.locale = calendar.locale ?? .current
        monthFormatter.setLocalizedDateFormatFromTemplate("LLLL")
        let dayMonthFormatter = DateFormatter()
        dayMonthFormatter.calendar = calendar
        dayMonthFormatter.locale = calendar.locale ?? .current
        dayMonthFormatter.setLocalizedDateFormatFromTemplate("dMMM")
        monthName = monthFormatter.string(from: today)

        // Big number + caption: first matching rule wins.
        let result = Self.rule(
            hasEverPrayed: hasEverPrayed,
            dailyRun: dailyRun,
            prayedToday: prayedToday,
            weekRun: weekRun,
            prayedThisWeek: prayedThisWeek,
            prayedDaysThisWeek: prayedDaysThisWeek,
            isWelcomeBack: isWelcomeBack,
            dailyRunStartDay: dayMonthFormatter.string(from: dailyRunStart),
            dailyRunStartMonth: monthFormatter.string(from: dailyRunStart),
            weekRunStartMonth: monthFormatter.string(from: weekRunFirstDay)
        )
        bigNumber = result.number
        unit = result.unit
        caption = result.caption
        isMilestone = result.isMilestone

        // Month grid.
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

    /// The caption rule table. Captions have no full stops.
    static func rule(
        hasEverPrayed: Bool,
        dailyRun: Int,
        prayedToday: Bool,
        weekRun: Int,
        prayedThisWeek: Bool,
        prayedDaysThisWeek: Int,
        isWelcomeBack: Bool,
        dailyRunStartDay: String,
        dailyRunStartMonth: String,
        weekRunStartMonth: String
    ) -> (number: Int, unit: Unit, caption: String, isMilestone: Bool) {
        // 1. Never prayed.
        guard hasEverPrayed else { return (0, .day, "Start your rhythm this week", false) }

        // 2. Daily mode (3+ days in a row); milestones only on the day they're reached.
        if dailyRun >= 3 {
            let milestone: String? = prayedToday ? {
                switch dailyRun {
                case 3: return "Three days in a row"
                case 5: return "Finding your rhythm"
                case 7: return "Every day this week"
                case 10: return "Every day since \(dailyRunStartDay)"
                case 14: return "A fortnight of prayer"
                case 30, 60, 100: return "Every day since \(dailyRunStartMonth)"
                case 40: return "Forty days, like Lent"
                case 54: return "A full novena"
                case 90: return "A whole season"
                default: return nil
                }
            }() : nil
            if let milestone {
                return (dailyRun, .day, milestone, true)
            }
            return (dailyRun, .day, prayedToday ? "See you tomorrow" : "Pray today to keep it", false)
        }

        // Lapsed: prayed before, but not this week or last week.
        guard weekRun > 0 else { return (0, .week, "Start your rhythm this week", false) }

        // 3. Welcome back after a gap of at least one empty week.
        if isWelcomeBack { return (1, .week, "Welcome back", false) }

        // 4. Getting started: first week of the run, by distinct prayed days this week.
        if weekRun == 1 && prayedThisWeek {
            switch prayedDaysThisWeek {
            case 1: return (1, .day, "Once this week", false)
            case 2: return (1, .week, "Twice this week", false)
            case 3: return (1, .week, "Three days this week", false)
            case 4: return (1, .week, "Four days this week", false)
            case 5: return (1, .week, "Five days this week", false)
            case 6: return (1, .week, "Six days this week", false)
            default: break
            }
        }

        // 5. Week milestones, during the week they're reached.
        if prayedThisWeek {
            let milestone: String? = {
                switch weekRun {
                case 2: return "Two weeks running"
                case 3: return "Becoming a habit"
                case 4: return "A month of weeks"
                case 8: return "Every week since \(weekRunStartMonth)"
                case 12: return "Three months steady"
                case 26: return "Half a year faithful"
                case 52: return "A year of prayer"
                default: return nil
                }
            }()
            if let milestone { return (weekRun, .week, milestone, true) }
        }

        // 6. Week mode otherwise.
        return (weekRun, .week, prayedThisWeek ? "See you next week" : "Pray this week to keep it", false)
    }

    /// Some prayer to show: a prayed day in the shown month or a live run.
    /// Drives the tick in the card's calendar icon.
    var hasPrayed: Bool { dailyRun > 0 || weekRun > 0 || prayedDaysThisMonth > 0 }

    private var unitWord: String { unit == .day ? "day" : "week" }

    var streakText: String { bigNumber == 1 ? "1 \(unitWord)" : "\(bigNumber) \(unitWord)s" }

    var accessibilityLabel: String {
        let days = prayedDaysThisMonth == 1 ? "1 day" : "\(prayedDaysThisMonth) days"
        return "Prayer rhythm, \(bigNumber) \(unitWord) streak, prayed \(days) in \(monthName). \(caption)."
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
    var isLocked = false

    private enum Metric {
        static let radius: CGFloat = AppTheme.containerRadius
        static let horizontalPadding: CGFloat = 20
        static let trailingPadding: CGFloat = 12
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
        .padding(.leading, Metric.horizontalPadding)
        .padding(.trailing, Metric.trailingPadding)
        .padding(.top, Metric.topPadding)
        .padding(.bottom, Metric.bottomPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { cardSurface }
        .clipShape(RoundedRectangle(cornerRadius: Metric.radius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rhythm.accessibilityLabel)
    }

    /// Mockup layout: icon top-left with the streak + caption bottom-aligned under it;
    /// month header level with the icon and the dot grid level with the text, so the
    /// grid sets the card height and the streak's baseline block meets the grid bottom.
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

            Color.clear
                .frame(width: 12)

            trailingAffordance
                .frame(maxHeight: .infinity, alignment: .center)
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
            trailingAffordance
                .padding(.top, AppTheme.Space.md)
                .frame(maxWidth: .infinity, alignment: .trailing)
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
        Group {
            if rhythm.isMilestone {
                // Accent flame for daily/week milestone captions.
                Image(systemName: "flame.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(palette.accent)
                    .symbolRenderingMode(.hierarchical)
            } else {
                CalendarCheckGlyph(showsCheck: rhythm.hasPrayed)
                    .stroke(palette.ink.opacity(isDark ? 0.88 : 0.82),
                            style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: Metric.iconSize.width, height: Metric.iconSize.height)
        .accessibilityHidden(true)
    }

    private var summaryText: some View {
        // No visible title: the streak leads (VoiceOver still says "Prayer rhythm").
        VStack(alignment: .leading, spacing: 0) {
            Text(rhythm.streakText)
                .font(AppTheme.sans(32, relativeTo: .title))
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

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
            .foregroundStyle(palette.textSecondary)
    }

    // MARK: Right column

    private var monthHeader: some View {
        HStack(spacing: 12) {
            CalendarFilledGlyph()
                .foregroundStyle(palette.ink.opacity(isDark ? 0.86 : 0.78))
                .frame(width: Metric.headerGlyph.width, height: Metric.headerGlyph.height)
            Text(rhythm.monthName)
                .font(AppTheme.sans(15, relativeTo: .subheadline))
                .foregroundStyle(palette.textSecondary)
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

    private var trailingAffordance: some View {
        HStack(spacing: 6) {
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("Guide+")
                    .font(AppTheme.TypeRole.caption)
            }
        }
        .foregroundStyle(isLocked ? palette.accent : palette.ink.opacity(isDark ? 0.62 : 0.52))
        .padding(.horizontal, isLocked ? 8 : 0)
        .padding(.vertical, isLocked ? 5 : 0)
        .background {
            if isLocked {
                Capsule(style: .continuous)
                    .fill(palette.accent.opacity(isDark ? 0.18 : 0.12))
            }
        }
        .accessibilityHidden(true)
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
