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

    var streakText: String { streak == 1 ? "1 day" : "\(streak) days" }

    var caption: String {
        if streak == 0 { return "Pray a rosary to start your rhythm." }
        if prayedToday && prayedEachDayThisWeek { return "You've prayed each day this week." }
        if prayedToday { return "Keep going, pray again tomorrow." }
        return "Pray today to keep it going."
    }

    var accessibilityLabel: String {
        let days = prayedDaysThisMonth == 1 ? "1 day" : "\(prayedDaysThisMonth) days"
        return "Prayer rhythm, \(streak) day streak, prayed \(days) in \(monthName). \(caption)"
    }
}

/// "Your prayer rhythm" card: current streak on the left, this month's prayed days
/// as a dot grid on the right (prayed = accent, missed = faint, future = fainter).
struct PrayerRhythmCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    var rhythm: PrayerRhythm

    private let dotSize: CGFloat = 8
    private let dotSpacing: CGFloat = 7

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: AppTheme.Space.lg) {
                summary
                Spacer(minLength: 0)
                monthGrid
            }
            VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
                summary
                monthGrid
            }
        }
        .padding(AppTheme.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rhythm.accessibilityLabel)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "calendar.badge.checkmark")
                .guideSymbol(size: 22, weight: .regular)
                .foregroundStyle(palette.ink)
                .padding(.bottom, AppTheme.Space.lg)

            Text("Your prayer rhythm")
                .font(AppTheme.TypeRole.bodySmall)
                .foregroundStyle(palette.dim)

            Text(rhythm.streakText)
                .font(AppTheme.TypeRole.title)
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, AppTheme.Space.xs)

            Text(rhythm.caption)
                .font(AppTheme.TypeRole.label(weight: .regular))
                .foregroundStyle(palette.dim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AppTheme.Space.sm)
        }
    }

    private var monthGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .guideSymbol(size: 12, weight: .medium)
                Text(rhythm.monthName)
                    .font(AppTheme.TypeRole.label)
                    .lineLimit(1)
            }
            .foregroundStyle(palette.dim)

            Grid(horizontalSpacing: dotSpacing, verticalSpacing: dotSpacing) {
                ForEach(rhythm.weeks.indices, id: \.self) { row in
                    GridRow {
                        ForEach(0..<7, id: \.self) { column in
                            dot(rhythm.weeks[row][column])
                        }
                    }
                }
            }
        }
        .fixedSize()
    }

    @ViewBuilder
    private func dot(_ day: PrayerRhythm.Day?) -> some View {
        if let day {
            Circle()
                .fill(fill(for: day))
                .frame(width: dotSize, height: dotSize)
                .overlay {
                    if day.isToday {
                        // Today: a quiet ring just outside the dot.
                        Circle()
                            .strokeBorder(day.prayed ? palette.accent.opacity(0.55) : palette.ink.opacity(0.45), lineWidth: 1)
                            .frame(width: dotSize + 5, height: dotSize + 5)
                    }
                }
        } else {
            Color.clear.frame(width: dotSize, height: dotSize)
        }
    }

    private func fill(for day: PrayerRhythm.Day) -> Color {
        if day.prayed { return palette.accent }
        if day.isFuture { return palette.ink.opacity(colorScheme == .dark ? 0.10 : 0.08) }
        return palette.ink.opacity(colorScheme == .dark ? 0.24 : 0.18)
    }
}
