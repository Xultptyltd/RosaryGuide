import SwiftUI

/// Disjoint agenda groups relative to the selected day, including year boundaries.
struct FeastAgenda {
    struct Section: Identifiable {
        let title: String
        let items: [DatedFeast]
        var id: String { title }
    }
    let sections: [Section]

    init(items: [DatedFeast], selectedDay: Date, today: Date = Date(), calendar: Calendar = .current) {
        let start = calendar.startOfDay(for: selectedDay)
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: start)?.end
            ?? calendar.date(byAdding: .day, value: 7, to: start) ?? start
        let monthEnd = calendar.dateInterval(of: .month, for: start)?.end
            ?? calendar.date(byAdding: .month, value: 1, to: start) ?? start
        let nextMonthEnd = calendar.date(byAdding: .month, value: 1, to: monthEnd) ?? monthEnd
        let yearEnd = calendar.dateInterval(of: .year, for: start)?.end
            ?? calendar.date(byAdding: .year, value: 1, to: start) ?? start
        let horizon = calendar.date(byAdding: .year, value: 1, to: yearEnd) ?? yearEnd
        let upcoming = items.filter { $0.date >= start && $0.date < horizon }.sorted {
            $0.date == $1.date ? $0.id < $1.id : $0.date < $1.date
        }
        let selected = upcoming.filter { calendar.isDate($0.date, inSameDayAs: start) }
        let focus: [DatedFeast]
        if !selected.isEmpty {
            focus = selected
        } else if let next = upcoming.first, next.date < monthEnd {
            focus = upcoming.filter { calendar.isDate($0.date, inSameDayAs: next.date) }
        } else {
            focus = []
        }
        var result: [Section] = []
        if !focus.isEmpty {
            let title = selected.isEmpty ? "Next"
                : calendar.isDate(start, inSameDayAs: today) ? "Today" : ""
            result.append(Section(title: title, items: focus))
        }
        let focusedIDs = Set(focus.map(\.id))
        let remaining = upcoming.filter { !focusedIDs.contains($0.id) }
        let titles = ["This week", "This month", "Next month", "Later this year", "Next year"]
        var buckets = Array(repeating: [DatedFeast](), count: titles.count)
        for item in remaining {
            let index: Int
            if item.date < weekEnd && item.date < monthEnd { index = 0 }
            else if item.date < monthEnd { index = 1 }
            else if item.date < nextMonthEnd { index = 2 }
            else if item.date < yearEnd { index = 3 }
            else { index = 4 }
            buckets[index].append(item)
        }
        for index in titles.indices where !buckets[index].isEmpty {
            result.append(Section(title: titles[index], items: buckets[index]))
        }
        sections = result
    }
}

/// Month cells aligned to the user's first weekday, without dates from adjacent months.
struct FeastMonthLayout {
    let cells: [Date?]
    var rows: Int { cells.count / 7 }
    init(month: Date, calendar: Calendar = .current) {
        guard
            let start = calendar.dateInterval(of: .month, for: month)?.start,
            let count = calendar.range(of: .day, in: .month, for: start)?.count
        else {
            cells = []
            return
        }
        let leading = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        var days = Array<Date?>(repeating: nil, count: leading)
        days += (0..<count).map { calendar.date(byAdding: .day, value: $0, to: start) }
        days += Array<Date?>(repeating: nil, count: (7 - days.count % 7) % 7)
        cells = days
    }
}

struct FeastsView: View {
    @Binding var prayLaunch: PrayLaunch?
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var calendarExpanded = false
    @State private var calendarDrag: CGFloat?
    @State private var filter: FeastScope = .all
    @State private var weekOffset = 0
    @State private var expandedWeek: Int? = 0
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var navigationPath = NavigationPath()
    @State private var debugFeast: DatedFeast?

    private var calendar: Calendar { .current }
    @Environment(DayClock.self) private var dayClock
    private var today: Date { dayClock.today }
    private var feasts: [DatedFeast] {
        let year = LiturgicalCalendar.year(of: selectedDay)
        let all = (year...year + 1).flatMap { FeastCatalog.dated(in: $0, calendar: calendar) }
        return filter == .marian ? all.filter(\.feast.isMarian) : all
    }
    private var agenda: FeastAgenda { FeastAgenda(items: feasts, selectedDay: selectedDay) }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    GuideChoiceControl(title: "Scope", selection: $filter, options: FeastScope.allCases) { $0.title }
                    // Keep "today" selected when the day rolls over.
                    .onChange(of: dayClock.today) { oldDay, newDay in
                        if calendar.isDate(selectedDay, inSameDayAs: oldDay) { selectedDay = newDay }
                    }

                    HStack {
                        Text(weekStart(weekOffset).formatted(.dateTime.month(.wide).year()))
                            .font(AppTheme.TypeRole.callout(weight: .medium))
                            .foregroundStyle(palette.ink)
                        Spacer()
                        if weekOffset != 0 || !calendar.isDate(selectedDay, inSameDayAs: today) {
                            GuideTextButton(title: "Today", alignment: nil) {
                                selectedDay = today
                                withAnimation(reduceMotion ? nil : MotionTokens.calendarReturn) {
                                    if calendarExpanded {
                                        expandedWeek = 0
                                    } else {
                                        weekOffset = 0
                                        expandedWeek = 0
                                    }
                                }
                            }
                        }
                    }
                    .frame(minHeight: AppTheme.Accessibility.minHitTarget)
                    .padding(.top, AppTheme.Space.lg)

                    weekdayHeader
                    ZStack(alignment: .top) {
                        // Keep both scrollers mounted so settling never recreates their days.
                        rollingCalendar
                            .opacity(calendarExpanded ? 0 : 1)
                            .animation(nil, value: calendarExpanded)
                            .allowsHitTesting(!calendarExpanded && calendarDrag == nil)
                            .accessibilityHidden(calendarExpanded)
                        expandedCalendar
                            .opacity(calendarExpanded ? 1 : 0)
                            .animation(nil, value: calendarExpanded)
                            .allowsHitTesting(calendarExpanded && calendarDrag == nil)
                            .accessibilityHidden(!calendarExpanded)
                    }
                    .frame(height: revealedCalendarHeight, alignment: .top)
                    .clipped()
                    .contentShape(Rectangle())
                    calendarHandle
                    GuideSectionDivider()
                        .allowsHitTesting(false)
                        .padding(.horizontal, -AppTheme.gutter)
                        .padding(.top, AppTheme.Component.calendarHandleDividerGap)
                        .padding(.bottom, AppTheme.Space.md)

                    let sections = agenda.sections
                    if sections.isEmpty {
                        Text("No upcoming feasts for this selection.")
                            .font(AppTheme.TypeRole.bodySmall)
                            .foregroundStyle(palette.dim)
                    } else {
                        ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                            if index > 0 { GuideSectionBoundary() }
                            agendaSection(section)
                            // Selected-day block between the calendar divider and the next section boundary.
                            if index == 0, let primary = section.items.first,
                               calendar.isDate(primary.date, inSameDayAs: selectedDay) {
                                feastActionRow(for: primary)
                                    .padding(.top, AppTheme.Space.lg)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.gutter)
                .padding(.top, GuideRootChrome.contentTop)
                .guideTabBarPadding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDisabled(calendarDrag != nil)
            .tint(palette.accent)
            .guideRootChrome("Feasts", ambientBackground: true)
            #if DEBUG
            // `-RGDebugOpenFeast`: opens the first upcoming feast's page for screenshots;
            // `-RGDebugFeastID <id>` picks a feast (next occurrence) instead.
            .navigationDestination(item: $debugFeast) { FeastDetailView(prayLaunch: $prayLaunch, item: $0) }
            .task {
                guard DebugHooks.has("-RGDebugOpenFeast") else { return }
                try? await Task.sleep(for: .seconds(2))
                if let id = UserDefaults.standard.string(forKey: "RGDebugFeastID") {
                    let year = LiturgicalCalendar.year(of: today)
                    debugFeast = (year...year + 1).flatMap { FeastCatalog.dated(in: $0, calendar: calendar) }
                        .first { $0.feast.id == id && $0.date >= calendar.startOfDay(for: today) }
                } else {
                    debugFeast = agenda.sections.first?.items.first
                }
            }
            #endif
        }
    }

    private func weekStart(_ offset: Int) -> Date {
        let anchor = calendar.startOfDay(for: today)
        let start = calendar.dateInterval(of: .weekOfYear, for: anchor)?.start ?? anchor
        // Step by seven days. Adding `.weekOfYear` can skip or repeat a week at the year boundary.
        return calendar.date(byAdding: .day, value: offset * 7, to: start) ?? start
    }

    private func adding(days: Int, to start: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: start) ?? start
    }

    private var rollingCalendar: some View {
        let offsets = min(-12, weekOffset)...max(26, weekOffset)
        let firstYear = LiturgicalCalendar.year(of: weekStart(offsets.lowerBound))
        let stripEnd = adding(days: AppTheme.Component.feastCalendarWeekCount * 7 - 1, to: weekStart(offsets.upperBound))
        let lastYear = LiturgicalCalendar.year(of: stripEnd)
        let stripFeasts = (firstYear...lastYear).flatMap { FeastCatalog.dated(in: $0, calendar: calendar) }
            .filter { filter == .all || $0.feast.isMarian }
        let feastDays = Set(stripFeasts.map { calendar.startOfDay(for: $0.date) })
        return TabView(selection: $weekOffset) {
            ForEach(offsets, id: \.self) { offset in
                VStack(spacing: AppTheme.Space.xs) {
                    ForEach(0..<AppTheme.Component.feastCalendarWeekCount, id: \.self) { row in
                        HStack(spacing: AppTheme.Space.xs) {
                            ForEach(0..<7, id: \.self) { column in
                                let day = adding(days: row * 7 + column, to: weekStart(offset))
                                dayButton(day, hasFeast: feastDays.contains(calendar.startOfDay(for: day)), showsWeekday: false)
                            }
                        }
                        .frame(minHeight: calendarDayRowHeight)
                    }
                }
                .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: expandedCalendarHeight)
    }

    private var expandedCalendar: some View {
        let offsets = min(-52, weekOffset)...max(104, weekOffset)
        let firstYear = LiturgicalCalendar.year(of: weekStart(offsets.lowerBound))
        let lastYear = LiturgicalCalendar.year(of: adding(days: 6, to: weekStart(offsets.upperBound)))
        let items = (firstYear...lastYear).flatMap { FeastCatalog.dated(in: $0, calendar: calendar) }
            .filter { filter == .all || $0.feast.isMarian }
        let feastDays = Set(items.map { calendar.startOfDay(for: $0.date) })
        return ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: AppTheme.Space.xs) {
                ForEach(offsets, id: \.self) { offset in
                    HStack(spacing: AppTheme.Space.xs) {
                        ForEach(0..<7, id: \.self) { column in
                            let day = adding(days: column, to: weekStart(offset))
                            dayButton(day, hasFeast: feastDays.contains(calendar.startOfDay(for: day)), showsWeekday: false)
                        }
                    }
                    .frame(minHeight: calendarDayRowHeight)
                    .id(offset)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $expandedWeek, anchor: .top)
        .onChange(of: expandedWeek) { _, offset in
            if calendarExpanded, let offset { weekOffset = offset }
        }
        .onChange(of: weekOffset) { _, offset in
            if !calendarExpanded { expandedWeek = offset }
        }
        .frame(height: expandedCalendarHeight)
    }

    /// One week row. Accessibility text needs more than the 52pt design row.
    private var calendarDayRowHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 96 : AppTheme.Component.feastCalendarDayHeight
    }

    private var expandedCalendarHeight: CGFloat {
        let rows = AppTheme.Component.feastCalendarWeekCount
        return CGFloat(rows) * calendarDayRowHeight + CGFloat(rows - 1) * AppTheme.Space.xs
    }

    private var revealedCalendarHeight: CGFloat {
        let collapsed = calendarDayRowHeight
        let base = calendarExpanded ? expandedCalendarHeight : collapsed
        return min(expandedCalendarHeight, max(collapsed, base + (calendarDrag ?? 0)))
    }

    private var weekdayHeader: some View {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let weekdays = Array(symbols[first...] + symbols[..<first])
        return HStack(spacing: AppTheme.Space.xs) {
            ForEach(0..<7, id: \.self) { index in
                Text(weekdays[index])
                    .font(AppTheme.TypeRole.caption)
                    .foregroundStyle(palette.dim)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(minHeight: AppTheme.Component.calendarWeekdayHeaderHeight)
        .padding(.bottom, AppTheme.Space.sm)
    }

    private func toggleCalendarExpanded() {
        if !calendarExpanded { expandedWeek = weekOffset }
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.28, extraBounce: 0)) {
            calendarExpanded.toggle()
            calendarDrag = nil
        }
    }

    private var calendarHandle: some View {
        Capsule()
            .fill(palette.dim)
            .frame(width: AppTheme.Component.calendarHandleWidth, height: AppTheme.Component.calendarHandleHeight)
            .frame(maxWidth: .infinity)
            // Center the touch region on the visible capsule, including space below it.
            // Negative outer padding keeps the existing visual gaps without shrinking hit testing.
            .frame(height: AppTheme.Accessibility.minHitTarget)
            .contentShape(Rectangle())
            .highPriorityGesture(calendarHandleGesture, including: .all)
            .padding(.top, -((AppTheme.Accessibility.minHitTarget - AppTheme.Component.calendarHandleHeight) / 2
                - AppTheme.Component.calendarHandleDotGap))
            .padding(.bottom, -(AppTheme.Accessibility.minHitTarget - AppTheme.Component.calendarHandleHeight) / 2)
            .zIndex(1)
            .accessibilityLabel("Calendar")
            .accessibilityValue(calendarExpanded ? "Upcoming weeks" : "Week view")
            .accessibilityHint(calendarExpanded ? "Shows this week" : "Shows the upcoming weeks")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { toggleCalendarExpanded() }
    }

    // Measure in a stationary coordinate space: the handle itself moves during a pull.
    // Local coordinates feed that movement back into translation and make the rows jitter.
    private var calendarHandleGesture: some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .global)
                .onChanged { value in
                    guard abs(value.translation.height) > abs(value.translation.width) else { return }
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { calendarDrag = value.translation.height }
                }
                .onEnded { value in
                    guard calendarDrag != nil else { return }
                    let projected = value.predictedEndTranslation.height
                    let distance = value.translation.height
                    let threshold = AppTheme.Component.calendarSnapThreshold
                    let expanded = calendarExpanded
                        ? !(distance < -threshold || projected < -threshold)
                        : distance > threshold || projected > threshold
                    if expanded && !calendarExpanded { expandedWeek = weekOffset }
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.28, extraBounce: 0)) {
                        calendarExpanded = expanded
                        calendarDrag = nil
                    }
                }
    }

    private func dayButton(_ day: Date, hasFeast: Bool, showsWeekday: Bool = true) -> some View {
        let selected = calendar.isDate(day, inSameDayAs: selectedDay)
        let isToday = calendar.isDate(day, inSameDayAs: today)
        return Button { selectedDay = day } label: {
            VStack(spacing: AppTheme.Space.xs) {
                if showsWeekday {
                    Text(calendar.veryShortStandaloneWeekdaySymbols[calendar.component(.weekday, from: day) - 1])
                        .font(AppTheme.TypeRole.calendarCaption)
                        .foregroundStyle(palette.dim)
                }
                Text(day.formatted(.dateTime.day()))
                    .font(AppTheme.TypeRole.calendarDay(weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? palette.onAccent : palette.ink)
                    .frame(minWidth: AppTheme.Accessibility.minHitTarget, minHeight: AppTheme.Accessibility.minHitTarget)
                    .background(selected ? palette.accent : .clear, in: Circle())
                    .overlay { if isToday && !selected { Circle().stroke(palette.accent, lineWidth: 1) } }
                Circle()
                    .fill(hasFeast ? palette.accent : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            day.formatted(date: .complete, time: .omitted)
                + (isToday ? ", today" : "")
                + (hasFeast ? ", feast day" : "")
        )
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func agendaSection(_ section: FeastAgenda.Section) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            if !section.title.isEmpty {
                GuideSectionLabel(text: section.title, prominence: .strong)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(spacing: 0) {
                ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                    NavigationLink {
                        FeastDetailView(prayLaunch: $prayLaunch, item: item)
                    } label: {
                        FeastTimelineRow(item: item, topPadding: index == 0 ? 0 : 14,
                                         bottomPadding: index == section.items.count - 1 ? 0 : 14)
                    }
                    .guidePressable()
                    if index < section.items.count - 1 { Hairline().padding(.leading, 76) }
                }
            }
        }
    }

    /// Learn + Pray this Rosary under today's feast (restored from before the calendar redesign, f8aa293).
    private func feastActionRow(for item: DatedFeast) -> some View {
        HStack(spacing: AppTheme.Space.md) {
            NavigationLink {
                FeastDetailView(prayLaunch: $prayLaunch, item: item)
            } label: {
                Text("Learn")
                    .font(AppTheme.TypeRole.pillLabel())
                    .foregroundStyle(palette.learnMoreButtonText)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Component.pillHeight)
                    .background(palette.learnMoreButtonFill, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .guidePressable()

            PillButton(title: "Pray this Rosary") {
                prayLaunch = .fresh(item.feast.suggestedMysterySet ?? MysteryCalendar.assignment(on: item.date).set)
            }
        }
    }

}

private enum FeastScope: String, CaseIterable, Identifiable {
    case all
    case marian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All feasts"
        case .marian: "Marian feasts"
        }
    }
}

// MARK: - Row

private struct FeastTimelineRow: View {
    var item: DatedFeast
    var topPadding: CGFloat = 14
    var bottomPadding: CGFloat = 14
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(spacing: 0) {
                Text(item.date.formatted(.dateTime.day()))
                    .font(AppTheme.TypeRole.calendarDateNumber)
                    .foregroundStyle(palette.ink)
                Text(item.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(AppTheme.TypeRole.calendarCaptionMedium)
                    .tracking(AppTheme.Component.eyebrowTracking)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(palette.dim)
            }
            .frame(width: 56)

            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                WordSafeText(item.feast.shortTitle, font: AppTheme.TypeRole.calloutUIFont(weight: .semibold), color: palette.ink)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 6 : 2)
                WordSafeText(item.feast.rank.title, font: AppTheme.TypeRole.captionUIFont(), color: palette.dim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        }
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .contentShape(Rectangle())
    }
}

// MARK: - Detail

struct FeastDetailView: View {
    @Binding var prayLaunch: PrayLaunch?
    var item: DatedFeast
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    /// Nil = all collapsed — keeps feast detail from becoming a wall of prayer text.
    @State private var expandedPrayerID: String?
    /// How far the hero's top actually sits under the status + nav chrome at rest,
    /// measured in scroll-content space (constant while scrolling).
    @State private var heroChromeOverlap: CGFloat = 0

    private var feast: Feast { item.feast }
    private var feastDayAssignment: MysteryAssignment {
        MysteryCalendar.assignment(on: item.date)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                detailHero

                GuideSectionLabel(text: feastMetadata, color: palette.dim)
                    .padding(.top, 18)

                Text(feast.shortTitle)
                    .font(AppTheme.TypeRole.screenTitle)
                    .foregroundStyle(palette.ink)
                    .lineLimit(3)
                    .padding(.top, AppTheme.Space.sm)

                Text(feast.summary)
                    .font(AppTheme.TypeRole.body)
                    .foregroundStyle(palette.dim)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AppTheme.Space.md)

                feastGuideSections
                    .padding(.top, 26)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.bottom, 108)
            .frame(maxWidth: .infinity, alignment: .leading)
            .coordinateSpace(name: FeastHeroChrome.contentSpace)
        }
        // Plain page colour over the ambient layer; glass cards stay on.
        .guidePlainPageBackground()
        .guidePageChrome(ambientBackground: true)
        // Keep native navigation visible so level-2 screens always have back navigation.
        // The system back gesture remains available from the far-left edge.
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(feast.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var prayersForDay: [FeastRelatedPrayer] {
        if !feast.relatedPrayersForDay.isEmpty {
            return feast.relatedPrayersForDay
        }
        if feast.isMarian {
            return [
                FeastRelatedPrayer(
                    id: "hail-holy-queen-fallback",
                    title: PrayerCatalog.hailHolyQueen.title.english,
                    english: PrayerCatalog.hailHolyQueen.text.english,
                    latin: PrayerCatalog.hailHolyQueen.text.latin
                )
            ]
        }
        if feast.id == "michael" {
            return [
                FeastRelatedPrayer(
                    id: "saint-michael-fallback",
                    title: PrayerCatalog.saintMichael.title.english,
                    english: PrayerCatalog.saintMichael.text.english,
                    latin: PrayerCatalog.saintMichael.text.latin
                )
            ]
        }
        if feast.id == "guardian-angels" {
            return [
                FeastRelatedPrayer(
                    id: "angel-of-god-fallback",
                    title: PrayerCatalog.angelOfGod.title.english,
                    english: PrayerCatalog.angelOfGod.text.english,
                    latin: PrayerCatalog.angelOfGod.text.latin
                )
            ]
        }
        return [
            FeastRelatedPrayer(
                id: "our-father-fallback",
                title: PrayerCatalog.ourFather.title.english,
                english: PrayerCatalog.ourFather.text.english,
                latin: PrayerCatalog.ourFather.text.latin
            )
        ]
    }

    private var feastMetadata: String {
        "\(item.date.formatted(.dateTime.day().month(.wide))). \(feast.rank.title)".uppercased()
    }

    private var feastGuideSections: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
            VStack(alignment: .leading, spacing: 0) {
                meaningSection
                atAGlanceCard
                    .padding(.top, AppTheme.Space.xl)
                GuideSectionBoundary()
                keepTheDaySection
                GuideSectionBoundary()
                prayersForDaySection
                GuideSectionBoundary()
                scriptureRosarySection
            }

            if let indulgence = feast.indulgenceNote {
                guideTextCard(
                    eyebrow: "Indulgence",
                    title: "A grace attached to this day",
                    body: indulgence
                )
            }
        }
    }

    private var atAGlanceCard: some View {
        VStack(spacing: 0) {
            quickFactRow("Observed as", feast.rank.title)
            Hairline()
            quickFactRow("Date", item.date.formatted(.dateTime.day().month(.wide).year()))
            Hairline()
            quickFactRow("Rosary", prayWithFeastSubtitle)
            if isLikelyHolyDayOfObligation {
                Hairline()
                quickFactRow("Note", "May be a holy day of obligation depending on country and year")
            }
        }
        .padding(.horizontal, AppTheme.Space.lg)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.surface, elevated: false)
    }

    private func quickFactRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.lg) {
            Text(label)
                .font(AppTheme.TypeRole.sectionLabel)
                .foregroundStyle(palette.dim)
                .frame(width: 88, alignment: .leading)
            Text(value)
                .font(AppTheme.TypeRole.bodySmall)
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 15)
    }

    private var meaningSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
            meaningParagraphBlock(body: feast.aboutText)

            if let history = feast.historyText {
                meaningParagraphBlock(body: history)
            }
        }
    }

    /// Paragraph-only Learn prose with no eyebrow or subsection title.
    private func meaningParagraphBlock(body: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
            ForEach(meaningParagraphs(from: body), id: \.self) { paragraph in
                Text(paragraph)
                    .font(AppTheme.TypeRole.bodySmall)
                    .foregroundStyle(palette.ink)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func meaningParagraphs(from body: String) -> [String] {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let byBlank = trimmed
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if byBlank.count > 1 { return byBlank }

        // Split a single dense block into at most two short paragraphs on sentence boundaries.
        let sentences = trimmed
            .split(separator: ".", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.hasSuffix("?") || $0.hasSuffix("!") ? $0 : $0 + "." }
        guard sentences.count >= 2 else { return [trimmed] }
        let mid = sentences.count / 2
        let first = sentences[..<mid].joined(separator: " ")
        let second = sentences[mid...].joined(separator: " ")
        return [first, second]
    }

    private var keepTheDaySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            GuideSectionLabel(text: "Keep the day", prominence: .strong)
            VStack(spacing: 0) {
                ForEach(Array(dayPractices.enumerated()), id: \.offset) { index, practice in
                    VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                        Text(practice.title)
                            .font(AppTheme.TypeRole.sectionHeading)
                            .foregroundStyle(palette.ink)
                        Text(practice.body)
                            .font(AppTheme.TypeRole.themeSummary)
                            .foregroundStyle(palette.dim)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 15)

                    if index < dayPractices.count - 1 {
                        Hairline()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Space.lg)
            .guideRowGroup()
        }
    }

    private var prayersForDaySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            GuideSectionLabel(text: "Prayers for this day", prominence: .strong)
                .padding(.bottom, AppTheme.sectionTitleGap - 12)
            ForEach(prayersForDay) { prayer in
                prayerCard(prayer)
            }
        }
    }

    private var scriptureRosarySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            GuideSectionLabel(text: "Scripture and Rosary", prominence: .strong)
                .padding(.bottom, AppTheme.sectionTitleGap - 12)
            rosaryConnectionCard

            if feastScriptures.isEmpty {
                guideTextCard(
                    eyebrow: "Scripture",
                    title: "Held in the Church’s memory",
                    body: "\(feast.shortTitle) is kept through Scripture, prayer, worship, and the Church’s living tradition."
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(feastScriptures.prefix(3).enumerated()), id: \.element.id) { index, passage in
                        VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                            GuideSectionLabel(text: passage.reference, color: palette.dim)
                            Text(passage.title)
                                .font(AppTheme.TypeRole.sectionHeading)
                                .foregroundStyle(palette.ink)
                            Text(passage.excerpt)
                                .font(AppTheme.TypeRole.themeSummary)
                                .foregroundStyle(palette.dim)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 15)

                        if index < min(feastScriptures.count, 3) - 1 {
                            Hairline()
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Space.lg)
                .guideRowGroup()
            }
        }
    }

    private func guideTextCard(eyebrow: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            GuideSectionLabel(text: eyebrow, color: palette.dim)
            Text(title)
                .font(AppTheme.TypeRole.titleSmall)
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(body)
                .font(AppTheme.TypeRole.bodySmall)
                .foregroundStyle(palette.dim)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.surface, elevated: false)
    }

    private var feastScriptures: [FeastScripturePassage] {
        feast.scripturePassages
    }

    private var isLikelyHolyDayOfObligation: Bool {
        ["mary-mother-of-god", "assumption", "all-saints", "immaculate-conception", "christmas"].contains(feast.id)
    }

    private var dayPractices: [(title: String, body: String)] {
        switch feast.id {
        case "michael":
            return [
                ("Pray for protection", "Pray the Saint Michael Prayer for the Church, your family, and anyone in danger."),
                ("Remember the archangels", "Michael defends, Gabriel announces, and Raphael heals. Ask God for courage, clarity, and healing."),
                ("Pray the Glorious Mysteries", "The feast points toward heaven, the angels, and the victory of Christ.")
            ]
        case "guardian-angels":
            return [
                ("Ask for guidance", "Pause before decisions today and ask God to guide you through your guardian angel."),
                ("Pray for children and travelers", "This memorial is a natural day to pray for protection over the vulnerable and those on the road."),
                ("Give thanks", "Thank God for hidden help, providence, and care you may never fully see.")
            ]
        case "all-souls":
            return [
                ("Pray for the dead", "Offer the Rosary, the Eternal Rest prayer, or Mass for the faithful departed."),
                ("Visit a cemetery", "Catholics traditionally visit cemeteries and pray for the holy souls, especially in early November."),
                ("Offer today’s Rosary", "Name someone you love and offer the Sorrowful Mysteries for them.")
            ]
        case "rosary":
            return [
                ("Pray five decades", "This is the natural day to pray the full Rosary with attention and without hurry."),
                ("Pray as a family", "The memorial has long been connected with families and communities gathering around the beads."),
                ("Stay with one mystery", "If time is short, pray one decade slowly and carry that mystery through the day.")
            ]
        case "immaculate-conception":
            return [
                ("Attend Mass if obliged", "This solemnity is a holy day of obligation in some places, including the United States, subject to the local calendar."),
                ("Ask for purity of heart", "Pray for a clean beginning, a freer yes to God, and Mary’s help against sin."),
                ("Pray a Marian prayer", "The Memorare or Hail Holy Queen fits the day especially well.")
            ]
        case "assumption":
            return [
                ("Attend Mass if obliged", "This solemnity is a holy day of obligation in many places, subject to the local calendar."),
                ("Pray with hope", "The Assumption points to the resurrection of the body and the destiny God prepares for his saints."),
                ("Pray the Glorious Mysteries", "The fourth Glorious Mystery belongs directly to this day.")
            ]
        case "christmas":
            return [
                ("Attend Mass", "Christmas is one of the great solemnities of the Church’s year."),
                ("Pray the Joyful Mysteries", "The Nativity is the heart of the day; pray it slowly and simply."),
                ("Keep the octave", "The Church celebrates Christmas for eight days, then continues the season until the Baptism of the Lord.")
            ]
        default:
            if feast.isMarian {
                return [
                    ("Pray this Rosary", "Let the day lead you back to Christ through Mary."),
                    ("Pray a Marian prayer", "The Hail Holy Queen, Memorare, or Angelus is a simple way to keep the feast."),
                    ("Offer an intention", "Bring one person or need to Mary’s intercession today.")
                ]
            }
            if feast.rank == .solemnity {
                return [
                    ("Go to Mass if obliged", "Some solemnities are holy days of obligation depending on country and year."),
                    ("Pray the suggested mysteries", "Use the Rosary set connected to this mystery where the app suggests one."),
                    ("Mark the day", "Read the Gospel, pray slowly, and let the feast shape the whole day.")
                ]
            }
            return [
                ("Read the short meditation", "Begin with what the Church is remembering today."),
                ("Pray one related prayer", "Choose the prayer below and offer it for a real intention."),
                ("Carry one line", "Take one phrase from the feast into the rest of the day.")
            ]
        }
    }

    private var prayWithFeastSubtitle: String {
        if let set = feast.suggestedMysterySet {
            return "\(set.shortName) Mysteries"
        }
        return "\(feastDayAssignment.set.shortName) Mysteries"
    }

    private var rosaryConnectionCard: some View {
        let set = feast.suggestedMysterySet ?? feastDayAssignment.set
        return HStack(alignment: .center, spacing: AppTheme.Space.md) {
            MysterySetIcon(set: set, size: 56)

            VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                GuideSectionLabel(text: "Mystery set", prominence: .strong)
                Text(set.name.english)
                    .font(AppTheme.TypeRole.body(weight: .semibold))
                    .foregroundStyle(palette.ink)
            }

            Spacer(minLength: 6)
        }
        .padding(AppTheme.Space.lg)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.surface, elevated: false)
    }

    private var detailHero: some View {
        ZStack {
            FeastHeroBanner(
                feast: feast,
                height: 330,
                cornerRadius: 0,
                topChromeInset: heroChromeOverlap
            )
            .frame(maxWidth: .infinity)
            .modifier(FeastHeroChrome.OverlapReader(overlap: $heroChromeOverlap))
        }
        .frame(height: 330)
        .padding(.horizontal, -AppTheme.gutter)
        .padding(.top, -8)
        .background(alignment: .bottom) { feastHeroTopFill }
        .ignoresSafeArea(edges: .top)
    }

    /// Plain page colour above the banner (status bar, nav bar and overscroll), not the ambient tint.
    private var feastHeroTopFill: some View {
        palette.bg
            .frame(height: 330 + AppTheme.Space.section * 8)
            .padding(.horizontal, -AppTheme.gutter)
            .allowsHitTesting(false)
    }

    private var detailActions: some View {
        HStack(spacing: AppTheme.Space.md) {
            detailAction("Remind me", icon: "bell.fill")
            Button {
                prayLaunch = .fresh(feast.suggestedMysterySet ?? feastDayAssignment.set)
            } label: {
                VStack(spacing: AppTheme.Space.sm) {
                    Image(systemName: "hands.sparkles.fill")
                        .guideSymbol(size: 20, weight: .medium)
                    Text("Pray")
                        .font(AppTheme.TypeRole.caption(weight: .medium))
                }
                .foregroundStyle(palette.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .guideSurface(in: RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous)
                        .strokeBorder(palette.subtleStroke, lineWidth: AppTheme.Component.panelStrokeWidth)
                }
            }
            .buttonStyle(.plain)
            detailAction("Share", icon: "square.and.arrow.up")
        }
    }

    private func detailAction(_ title: String, icon: String) -> some View {
        VStack(spacing: AppTheme.Space.sm) {
            Image(systemName: icon)
                .guideSymbol(size: 20, weight: .medium)
                .foregroundStyle(palette.accentText)
            Text(title)
                .font(AppTheme.TypeRole.caption(weight: .medium))
                .foregroundStyle(palette.ink)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 76)
        .guideSurface(in: RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous)
                .strokeBorder(palette.subtleStroke, lineWidth: AppTheme.Component.panelStrokeWidth)
        }
    }

    private func infoRow(_ title: String) -> some View {
        HStack(spacing: AppTheme.Space.lg) {
            Text(title)
                .font(AppTheme.TypeRole.serifBody)
                .foregroundStyle(palette.ink)
            Spacer()
        }
        .padding(.vertical, 17)
        .contentShape(Rectangle())
    }

    private var prayersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            GuideSectionLabel(text: "Prayers for this day", color: palette.dim)

            ForEach(feast.relatedPrayersForDay) { prayer in
                prayerCard(prayer)
            }
        }
    }

    private func prayerCard(_ prayer: FeastRelatedPrayer) -> some View {
        let isExpanded = expandedPrayerID == prayer.id

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                expandedPrayerID = isExpanded ? nil : prayer.id
            } label: {
                HStack(alignment: .center, spacing: AppTheme.Space.md) {
                    Text(prayer.title)
                        .font(AppTheme.TypeRole.sectionHeading)
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .guideSymbol(size: 12, weight: .semibold)
                        .foregroundStyle(palette.faint)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, AppTheme.Space.lg)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(prayer.title)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(isExpanded ? "Collapses prayer" : "Expands prayer")

            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    Text(prayerText(prayer))
                        .font(AppTheme.TypeRole.bodySmall)
                        .foregroundStyle(palette.dim)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)

                    if settings.language == .bilingual, let latin = prayer.latin, !latin.isEmpty {
                        Text(latin)
                            .font(AppTheme.TypeRole.themeSummary)
                            .foregroundStyle(palette.faint)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let note = prayer.note {
                        Text(note)
                            .font(AppTheme.TypeRole.caption)
                            .foregroundStyle(palette.faint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
                    .transition(MotionTokens.accordionTransition)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .guideRowGroup()
        .guideAccordion(isExpanded: isExpanded)
    }

    private func prayerText(_ prayer: FeastRelatedPrayer) -> String {
        switch settings.language {
        case .latin:
            return prayer.latin ?? prayer.english
        case .english, .bilingual:
            return prayer.english
        }
    }

    private func mysteriesCard(_ set: MysterySetKind) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            GuideSectionLabel(text: "Suggested mysteries", color: palette.dim)

            Text(set.name.english)
                .font(AppTheme.TypeRole.serifTitle)
                .foregroundStyle(palette.ink)

            Text(set.name.latin)
                .font(AppTheme.TypeRole.serifItalicBody)
                .foregroundStyle(palette.dim)

            Text("The weekday set stays the default. You can pray the \(set.shortName) Mysteries for this feast if you wish.")
                .font(AppTheme.TypeRole.label)
                .foregroundStyle(palette.dim)
                .lineSpacing(3)
                .padding(.top, 2)

            PillButton(title: "Pray the \(set.shortName) Mysteries") {
                prayLaunch = .fresh(set)
            }
            .padding(.top, AppTheme.Space.xs)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .guideSurface(in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                .strokeBorder(palette.hair, lineWidth: AppTheme.Component.panelStrokeWidth)
        }
    }
}

private struct FeastRelatedPrayersView: View {
    var feast: Feast
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedPrayerID: String?

    private var prayers: [FeastRelatedPrayer] {
        if !feast.relatedPrayersForDay.isEmpty {
            return feast.relatedPrayersForDay
        }
        if feast.isMarian {
            return [
                FeastRelatedPrayer(
                    id: "hail-holy-queen-fallback",
                    title: PrayerCatalog.hailHolyQueen.title.english,
                    english: PrayerCatalog.hailHolyQueen.text.english,
                    latin: PrayerCatalog.hailHolyQueen.text.latin
                )
            ]
        }
        if feast.id == "michael" || feast.id == "guardian-angels" {
            return [
                FeastRelatedPrayer(
                    id: "saint-michael-fallback",
                    title: PrayerCatalog.saintMichael.title.english,
                    english: PrayerCatalog.saintMichael.text.english,
                    latin: PrayerCatalog.saintMichael.text.latin
                )
            ]
        }
        return [
            FeastRelatedPrayer(
                id: "our-father-fallback",
                title: PrayerCatalog.ourFather.title.english,
                english: PrayerCatalog.ourFather.text.english,
                latin: PrayerCatalog.ourFather.text.latin
            )
        ]
    }

    var body: some View {
        FeastSecondaryPage(title: "Related prayers", feast: feast) {
            DividedRows(alignment: .leading, spacing: AppTheme.Space.lg) {
                ForEach(prayers) { prayer in
                    prayerCard(prayer)
                }
            }
        }
        .onAppear {
            if expandedPrayerID == nil {
                expandedPrayerID = prayers.first?.id
            }
        }
    }

    private func prayerCard(_ prayer: FeastRelatedPrayer) -> some View {
        let isExpanded = expandedPrayerID == prayer.id

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                expandedPrayerID = isExpanded ? nil : prayer.id
            } label: {
                HStack(alignment: .center, spacing: AppTheme.Space.md) {
                    Text(prayer.title)
                        .font(AppTheme.TypeRole.sectionHeading)
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .guideSymbol(size: 12, weight: .semibold)
                        .foregroundStyle(palette.faint)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, AppTheme.Space.lg)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(prayer.title)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(isExpanded ? "Collapses prayer" : "Expands prayer")

            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                    Text(prayerText(prayer))
                        .font(AppTheme.TypeRole.bodySmall)
                        .foregroundStyle(palette.dim)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)

                    if settings.language == .bilingual, let latin = prayer.latin, !latin.isEmpty {
                        Text(latin)
                            .font(AppTheme.TypeRole.themeSummary)
                            .foregroundStyle(palette.faint)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let note = prayer.note {
                        Text(note)
                            .font(AppTheme.TypeRole.caption)
                            .foregroundStyle(palette.faint)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                }
                .padding(.bottom, 18)
                    .transition(MotionTokens.accordionTransition)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
        .rowBottomDivider()
        .guideAccordion(isExpanded: isExpanded)
    }

    private func prayerText(_ prayer: FeastRelatedPrayer) -> String {
        switch settings.language {
        case .latin:
            return prayer.latin ?? prayer.english
        case .english, .bilingual:
            return prayer.english
        }
    }
}

private struct FeastPatronagesView: View {
    var feast: Feast
    @Environment(\.palette) private var palette

    var body: some View {
        FeastSecondaryPage(title: "Patronages", feast: feast) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                Text("Traditions associated with this feast.")
                    .font(AppTheme.TypeRole.serifBody)
                    .foregroundStyle(palette.dim)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                DividedRows(alignment: .leading, spacing: AppTheme.Space.xl) {
                    ForEach(patronages, id: \.self) { patronage in
                        VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                            GuideSectionLabel(text: "Patronage", color: palette.faint)
                            Text(patronage)
                                .font(AppTheme.TypeRole.serifTitle)
                                .foregroundStyle(palette.ink)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, 20)
                        .rowBottomDivider()
                    }
                }
            }
        }
    }

    private var patronages: [String] {
        switch feast.id {
        case "mary-mother-of-god": return ["Mothers", "Peace", "The Church beginning the civil year"]
        case "lourdes": return ["The sick", "Pilgrims", "Those seeking healing"]
        case "joseph": return ["The universal Church", "Families", "Workers", "A holy death"]
        case "fatima": return ["Conversion", "Peace", "Families praying the Rosary"]
        case "carmel": return ["The Carmelite family", "Those who wear the Brown Scapular", "Contemplative prayer"]
        case "michael": return ["Police, soldiers, and first responders", "The protection of the Church", "Those in spiritual battle"]
        case "guardian-angels": return ["Children", "Travelers", "Daily protection"]
        case "rosary": return ["Those devoted to the Rosary", "Families", "Perseverance in prayer"]
        case "all-souls": return ["The faithful departed", "Those who grieve", "Prayer for the holy souls"]
        case "immaculate-conception": return ["The United States", "Purity of heart", "A new beginning in grace"]
        case "guadalupe": return ["The Americas", "The unborn", "Evangelization"]
        default:
            if feast.isMarian {
                return ["Those seeking Mary’s intercession", "Families", "Growth in faith, hope, and love"]
            }
            if feast.rank == .solemnity {
                return ["The whole Church", "Renewal in the mystery celebrated today"]
            }
            return ["Those who keep this feast", "A deeper love for Christ and his Church"]
        }
    }
}

private struct FeastScriptureView: View {
    var feast: Feast
    @Environment(\.palette) private var palette

    private var passages: [FeastScripturePassage] {
        feast.scripturePassages
    }

    var body: some View {
        FeastSecondaryPage(title: "In Scripture", feast: feast) {
            VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                if passages.isEmpty {
                    FeastTextPanel(
                        title: "Scripture",
                        text: "\(feast.shortTitle) is held within the Church's living memory of Scripture, prayer, and worship."
                    )
                } else {
                    DividedRows(alignment: .leading, spacing: AppTheme.Space.xl) {
                        ForEach(passages) { passage in
                            VStack(alignment: .leading, spacing: AppTheme.Space.md) {
                                GuideSectionLabel(text: passage.reference, color: palette.faint)
                                Text(passage.title)
                                    .font(AppTheme.TypeRole.serifTitle)
                                    .foregroundStyle(palette.ink)
                                Text(passage.excerpt)
                                    .font(AppTheme.TypeRole.serifBody)
                                    .foregroundStyle(palette.dim)
                                    .lineSpacing(5)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.bottom, 22)
                            .rowBottomDivider()
                        }
                    }
                }
            }
        }
    }
}

private struct FeastSecondaryPage<Content: View>: View {
    var title: String
    var feast: Feast
    @ViewBuilder var content: () -> Content
    @Environment(\.palette) private var palette
    @State private var heroChromeOverlap: CGFloat = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                FeastHeroBanner(
                    feast: feast,
                    height: 238,
                    cornerRadius: 0,
                    topChromeInset: heroChromeOverlap
                )
                    .modifier(FeastHeroChrome.OverlapReader(overlap: $heroChromeOverlap))
                    .padding(.horizontal, -AppTheme.gutter)
                    .padding(.top, -8)
                    // Plain page colour above the banner, not the ambient tint.
                    .background(alignment: .bottom) {
                        palette.bg
                            .frame(height: 238 + AppTheme.Space.section * 8)
                            .padding(.horizontal, -AppTheme.gutter)
                            .allowsHitTesting(false)
                    }
                    .padding(.bottom, 22)

                GuideSectionLabel(text: feast.rank.title, color: palette.dim)

                Text(title)
                    .font(AppTheme.TypeRole.serifDisplay)
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AppTheme.Space.sm)

                Text(feast.shortTitle)
                    .font(AppTheme.TypeRole.serifBody)
                    .foregroundStyle(palette.dim)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AppTheme.Space.sm)
                    .padding(.bottom, 30)

                content()

                Spacer(minLength: 34)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.bottom, 108)
            .frame(maxWidth: .infinity, alignment: .leading)
            .coordinateSpace(name: FeastHeroChrome.contentSpace)
        }
        // Plain page colour over the ambient layer; glass cards stay on.
        .guidePlainPageBackground()
        .guidePageChrome(ambientBackground: true)
        // Match FeastDetailView: native nav with hidden (translucent) bar material
        // so hero content can show through liquid glass.
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FeastTextPanel: View {
    var title: String
    var text: String
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            GuideSectionLabel(text: title, color: palette.faint)
            Text(text)
                .font(AppTheme.TypeRole.serifBody)
                .foregroundStyle(palette.ink)
                .lineSpacing(13)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 2)
    }
}

// MARK: - Hero chrome

/// Measures how far a feast hero's top sits under the status + nav chrome when the
/// page is at rest. The scroll content (VStack) origin is where the scroll view's
/// safe-area inset ends, i.e. the bottom of the chrome, so any negative minY of the
/// hero in that space is real overlap. Constant while scrolling, unlike global frames.
enum FeastHeroChrome {
    static let contentSpace = "feastHeroContent"

    struct OverlapReader: ViewModifier {
        @Binding var overlap: CGFloat

        func body(content: Content) -> some View {
            content.onGeometryChange(for: CGFloat.self) { proxy in
                proxy.frame(in: .named(FeastHeroChrome.contentSpace)).minY
            } action: { minY in
                let value = max(0, -minY).rounded()
                if abs(value - overlap) > 0.5 { overlap = value }
            }
        }
    }
}

// MARK: - Hero placeholder

private struct FeastHeroBanner: View {
    var feast: Feast
    var height: CGFloat = 200
    var cornerRadius: CGFloat = AppTheme.containerRadius
    /// Status + inline nav clearance for under-nav heroes. Home cards leave this at 0.
    var topChromeInset: CGFloat = 0
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    private var heroSymbol: String {
        if feast.isMarian { return "crown.fill" }
        switch feast.id {
        case "christmas", "epiphany", "baptism-movable": return "star.fill"
        case "easter", "divine-mercy", "ascension", "pentecost": return "sun.max.fill"
        case "ash-wednesday", "palm-sunday", "holy-thursday", "good-friday", "holy-saturday":
            return "cross.fill"
        case "michael", "guardian-angels": return "shield.fill"
        default: return "calendar"
        }
    }

    private var feastArtPath: (directory: String, name: String, ext: String)? {
        ArtCatalog.feastHeroPath(feastId: feast.id, scheme: colorScheme)
    }

    var body: some View {
        ZStack {
            if let path = feastArtPath {
                FocusedRasterImage(
                    directory: path.directory,
                    name: path.name,
                    ext: path.ext,
                    coversSubject: true,
                    topChromeInset: topChromeInset
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            } else if let set = feast.suggestedMysterySet {
                MysteryArtworkView(set: set, kind: .heroWide)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(1.04)
                    .blur(radius: 1.6)
                    .clipped()
            } else {
                LinearGradient(
                    colors: palette.feastArtworkFallbackGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // Artwork at full strength; only the lowest part dissolves into the page.
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 1 - AppTheme.FeastHero.bottomFade),
                    .init(color: palette.bg, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            if feastArtPath == nil, feast.suggestedMysterySet == nil {
                Image(systemName: heroSymbol)
                    .guideSymbol(size: 36, weight: .light)
                    .foregroundStyle(palette.ink.opacity(0.28))
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityLabel("Feast artwork for \(feast.shortTitle)")
    }
}
