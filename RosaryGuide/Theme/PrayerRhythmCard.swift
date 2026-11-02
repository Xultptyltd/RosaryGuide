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
    var currentWeek: [Day]
    var weekdayLabels: [String]

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
        currentWeek = (0..<7).map { offset in
            let date = addDays(offset, to: thisWeek)
            return Day(number: calendar.component(.day, from: date), prayed: prayed(date),
                       isToday: calendar.isDate(date, inSameDayAs: today), isFuture: date > today)
        }
        let symbols = calendar.shortStandaloneWeekdaySymbols
        weekdayLabels = (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }
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

    private func dayCount(_ n: Int) -> String { n == 1 ? "1 day" : "\(n) days" }

    /// Card left column: big text and a short caption (no full stops).
    var card: (big: String, caption: String) {
        if !hasEverPrayed || (weekRun == 0 && dailyRun < 3) { return ("0 days", "Start this week") }
        if isMilestone { return (streakText, caption) }
        if isWelcomeBack { return (dayCount(prayedDaysThisWeek), "Welcome back") }
        if dailyRun >= 3 { return (streakText, "In a row") }
        if weekRun == 1 && prayedDaysThisWeek > 0 { return (dayCount(prayedDaysThisWeek), "This week") }
        return (streakText, "In a row")
    }

    var accessibilityLabel: String {
        let days = prayedDaysThisMonth == 1 ? "1 day" : "\(prayedDaysThisMonth) days"
        return "Your prayer, \(card.big). \(card.caption). Prayed \(days) in \(monthName)."
    }
}

/// Compact weekly preview; its parent button opens the full prayer calendar.
struct PrayerRhythmCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var rhythm: PrayerRhythm

    private var weeklySummary: String {
        let days = rhythm.prayedDaysThisWeek
        // Zero state for this week: an invitation rather than "0 days this week".
        guard days > 0 else { return "Find room for prayer" }
        return "\(days) \(days == 1 ? "day" : "days") this week"
    }

    private var calendarChevron: some View {
        Image(systemName: "chevron.right")
            .font(AppTheme.TypeRole.caption(weight: .medium))
            .foregroundStyle(palette.faint)
            .accessibilityHidden(true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.none) {
            HStack(spacing: AppTheme.Space.sm) {
                Text("Your prayer")
                    .font(AppTheme.TypeRole.supportingLabel)
                    .foregroundStyle(palette.textSecondary)
                Spacer(minLength: AppTheme.PrayerPreview.headerGap)
                calendarChevron
            }

            Text(weeklySummary)
                .font(AppTheme.TypeRole.prayerPreviewSummary)
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AppTheme.PrayerPreview.summaryGap)

            HStack(alignment: .top, spacing: AppTheme.Space.none) {
                ForEach(rhythm.currentWeek.indices, id: \.self) { index in
                    VStack(spacing: AppTheme.PrayerPreview.dayLabelGap) {
                        Text(dynamicTypeSize.isAccessibilitySize
                             ? String(rhythm.weekdayLabels[index].prefix(1))
                             : rhythm.weekdayLabels[index])
                            .font(AppTheme.TypeRole.calendarCaption)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(1)
                        dayMarker(rhythm.currentWeek[index])
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, AppTheme.PrayerPreview.weekGap)
        }
        .padding(AppTheme.PrayerPreview.cardInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .guideSurface(in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your prayer, \(weeklySummary). " + zip(rhythm.weekdayLabels, rhythm.currentWeek).map { label, day in
            "\(label): \(day.prayed ? "prayed" : day.isToday ? "today" : day.isFuture ? "upcoming" : "no prayer recorded")"
        }.joined(separator: ". "))
    }

    private func dayMarker(_ day: PrayerRhythm.Day) -> some View {
        ZStack {
            if day.prayed {
                Circle().fill(palette.accent)
                Image(systemName: "checkmark")
                    .guideSymbol(size: AppTheme.PrayerPreview.checkmarkSize, weight: AppTheme.PrayerPreview.checkmarkWeight)
                    .foregroundStyle(palette.onAccent)
            } else if day.isToday {
                Circle().strokeBorder(palette.strokeSelected, lineWidth: AppTheme.PrayerPreview.todayRingWidth)
                    .padding(AppTheme.PrayerPreview.todayRingInset)
            } else {
                Circle().fill(day.isFuture ? palette.strokeRegular : palette.strokeStrong)
                    .frame(width: AppTheme.PrayerPreview.inactiveDotSize, height: AppTheme.PrayerPreview.inactiveDotSize)
            }
        }
        .frame(width: AppTheme.PrayerPreview.markerSize, height: AppTheme.PrayerPreview.markerSize)
    }
}
