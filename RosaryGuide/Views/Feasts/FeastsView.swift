import SwiftUI

struct FeastsView: View {
    @Binding var prayLaunch: PrayLaunch?
    @Environment(SettingsStore.self) private var settings
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    @State private var filter: FeastScope = .all
    @State private var visibleMonth: Date = Date()
    @State private var selectedDay: Date?
    @State private var titleScrollOffset: CGFloat = 0
    @State private var navigationPath = NavigationPath()

    private var calendar: Calendar { .current }

    private var todayStart: Date { calendar.startOfDay(for: Date()) }

    private var resolvedSelectedDay: Date {
        selectedDay ?? todayStart
    }

    private var feastDaysInVisibleMonth: [Date: [DatedFeast]] {
        let year = calendar.component(.year, from: visibleMonth)
        let month = calendar.component(.month, from: visibleMonth)
        var items = FeastCatalog.dated(in: year) + FeastCatalog.dated(in: year + 1) + FeastCatalog.dated(in: year - 1)
        items = items.filter {
            calendar.component(.year, from: $0.date) == year
                && calendar.component(.month, from: $0.date) == month
        }
        if filter == .marian {
            items = items.filter(\.feast.isMarian)
        }
        return Dictionary(grouping: items, by: { calendar.startOfDay(for: $0.date) })
    }

    /// Feasts on the currently selected day (filter-aware).
    private var selectedDayFeasts: [DatedFeast] {
        var items = FeastCatalog.feasts(on: resolvedSelectedDay)
        if filter == .marian {
            items = items.filter(\.feast.isMarian)
        }
        return items
    }

    /// When the selected day is empty, the next upcoming feast for the “Next” focus.
    private var nextFeastAfterSelection: DatedFeast? {
        let start = calendar.startOfDay(for: resolvedSelectedDay)
        var items = FeastCatalog.upcoming(from: calendar.date(byAdding: .day, value: 1, to: start) ?? start, limit: 36)
        if filter == .marian {
            items = items.filter(\.feast.isMarian)
        }
        return items.first
    }

    private var focusedFeasts: [DatedFeast] {
        if !selectedDayFeasts.isEmpty { return selectedDayFeasts }
        if let next = nextFeastAfterSelection { return [next] }
        return []
    }

    private var focusedShowsSelectedDay: Bool {
        !selectedDayFeasts.isEmpty
    }

    private var focusedPrimary: DatedFeast? {
        focusedFeasts.first
    }

    private var upcomingItems: [DatedFeast] {
        var items: [DatedFeast]
        if filter == .marian {
            items = Array(FeastCatalog.upcoming(from: Date(), limit: 48).filter(\.feast.isMarian))
        } else {
            items = FeastCatalog.upcoming(from: Date(), limit: 18)
        }
        // Avoid duplicating the focused feast(s) in the Upcoming list.
        let focusedIDs = Set(focusedFeasts.map(\.id))
        return Array(items.filter { !focusedIDs.contains($0.id) }.prefix(9))
    }



    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Space.xl) {
                    VStack(spacing: 0) {
                        CollapsingTitleSpacer()

                        Picker("Scope", selection: $filter) {
                            ForEach(FeastScope.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .guideSegmentedControl()
                        .frame(maxWidth: .infinity)
                    }
                    // Visible gap from the scope tabs' track to the calendar card: 16pt.
                    // The stack's spacing is 24; the track overhangs its frame slightly.
                    .padding(
                        .bottom,
                        AppTheme.Space.lg + AppTheme.Component.segmentedControlVisualOverflow - AppTheme.Space.xl
                    )

                    FeastMonthCalendar(
                        month: $visibleMonth,
                        selectedDay: $selectedDay,
                        feastDays: feastDaysInVisibleMonth
                    )

                    focusedDaySection

                    upcomingSection

                }
                .padding(.horizontal, AppTheme.gutter)
                .padding(.top, AppTheme.Space.sm)
                .padding(.bottom, 108)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .tint(palette.accent)
            .guidePageChrome()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .collapsingTitleChrome("Feasts", scrollOffset: $titleScrollOffset)
            .onAppear {
                if selectedDay == nil {
                    selectedDay = todayStart
                }
            }
        }
    }

    // MARK: - Focused day

    private var focusedDaySection: some View {
        Group {
            if !focusedFeasts.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Space.sm) {
                    VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
                        GuideSectionLabel(text: focusedSectionTitle, prominence: .strong)

                        VStack(spacing: 0) {
                            ForEach(Array(focusedFeasts.enumerated()), id: \.element.id) { index, item in
                                NavigationLink {
                                    FeastDetailView(prayLaunch: $prayLaunch, item: item)
                                } label: {
                                    FeastTimelineRow(item: item)
                                }
                                .buttonStyle(.plain)

                                if index < focusedFeasts.count - 1 {
                                    Hairline()
                                        .padding(.leading, 62)
                                }
                            }
                        }
                        .guideNavList(pageGutter: AppTheme.gutter)
                    }

                    if focusedShowsSelectedDay, let primary = focusedPrimary {
                        feastActionRow(for: primary)
                    }
                }
            }
        }
    }

    private var focusedSectionTitle: String {
        if focusedShowsSelectedDay {
            if calendar.isDateInToday(resolvedSelectedDay) {
                return "Today"
            }
            return resolvedSelectedDay.formatted(.dateTime.day().month(.wide))
        }
        return "Next"
    }

    private func feastActionRow(for item: DatedFeast) -> some View {
        HStack(spacing: AppTheme.Space.sm) {
            NavigationLink {
                FeastDetailView(prayLaunch: $prayLaunch, item: item)
            } label: {
                Text("Learn")
                    .font(AppTheme.TypeRole.callout(weight: .semibold))
                    .foregroundStyle(palette.secondaryButtonText)
                    .padding(.horizontal, 28)
                    .frame(height: AppTheme.Component.pillHeight)
                    .background(palette.secondaryButtonFill, in: Capsule())
            }
            .buttonStyle(.plain)
            .guidePressable()

            Button {
                let set = item.feast.suggestedMysterySet
                    ?? MysteryCalendar.assignment(on: item.date).set
                prayLaunch = .fresh(set)
            } label: {
                HStack(spacing: 8) {
                    Text("Pray this Rosary")
                        .font(AppTheme.TypeRole.callout(weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(AppTheme.TypeRole.label(weight: .semibold))
                }
                .foregroundStyle(palette.primaryButtonText)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Component.pillHeight)
                .background(palette.primaryButtonFill, in: Capsule())
            }
            .buttonStyle(.plain)
            .guidePressable()
        }
    }

    // MARK: - Upcoming

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            GuideSectionLabel(
                text: filter == .marian ? "Upcoming Marian feasts" : "Upcoming",
                prominence: .strong
            )

            VStack(spacing: 0) {
                ForEach(Array(upcomingItems.enumerated()), id: \.element.id) { index, item in
                    NavigationLink {
                        FeastDetailView(prayLaunch: $prayLaunch, item: item)
                    } label: {
                        FeastTimelineRow(item: item)
                    }
                    .buttonStyle(.plain)

                    if index < upcomingItems.count - 1 {
                        Hairline()
                            .padding(.leading, 62)
                    }
                }
            }
            .guideNavList(pageGutter: AppTheme.gutter)
        }
    }


    // MARK: - Week strip feast lookup


}

// MARK: - Month calendar

private struct FeastMonthCalendar: View {
    @Binding var month: Date
    @Binding var selectedDay: Date?
    var feastDays: [Date: [DatedFeast]]

    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    private var calendar: Calendar { .current }

    private var monthTitle: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var dayRows: [[Date?]] {
        let cells = days
        var rows: [[Date?]] = []
        var i = 0
        while i < cells.count {
            let end = min(i + 7, cells.count)
            var row = Array(cells[i..<end])
            while row.count < 7 { row.append(nil) }
            rows.append(row)
            i = end
        }
        return rows
    }

    private var days: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        let weekCount = calendar.range(of: .weekOfMonth, in: .month, for: month)?.count ?? 6
        var cursor = firstWeek.start
        var cells: [Date?] = []
        for _ in 0..<(7 * weekCount) {
            if calendar.isDate(cursor, equalTo: month, toGranularity: .month) {
                cells.append(cursor)
            } else {
                cells.append(nil)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return cells
    }

    var body: some View {
        VStack(spacing: AppTheme.Space.md) {
            HStack {
                Button {
                    shiftMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .guideSymbol(size: 14, weight: .semibold)
                        .foregroundStyle(palette.ink)
                        .frame(width: AppTheme.controlSize, height: AppTheme.controlSize)
                        .background(palette.surface, in: Circle())
                }
                .buttonStyle(.plain)
                .guideHitTarget()
                .accessibilityLabel("Previous month")

                Spacer(minLength: 0)
                Text(monthTitle)
                    .font(AppTheme.TypeRole.body)
                    .foregroundStyle(palette.ink)
                Spacer(minLength: 0)

                Button {
                    shiftMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .guideSymbol(size: 14, weight: .semibold)
                        .foregroundStyle(palette.ink)
                        .frame(width: AppTheme.controlSize, height: AppTheme.controlSize)
                        .background(palette.surface, in: Circle())
                }
                .buttonStyle(.plain)
                .guideHitTarget()
                .accessibilityLabel("Next month")
            }

            VStack(spacing: AppTheme.Space.sm) {
                HStack(spacing: 0) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(AppTheme.TypeRole.caption(weight: .medium))
                            .tracking(0.4)
                            .textCase(.uppercase)
                            .foregroundStyle(palette.faint)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 2)
                    }
                }

                ForEach(Array(dayRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, day in
                            if let day {
                                dayCell(day)
                            } else {
                                Color.clear
                                    .frame(height: 40)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }

        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        .guideSoftShadow(elevated: colorScheme == .light)
    }

    @ViewBuilder
    private func dayCell(_ day: Date) -> some View {
        let start = calendar.startOfDay(for: day)
        let feasts = feastDays[start] ?? []
        let hasFeast = !feasts.isEmpty
        let hasMarian = feasts.contains(where: \.feast.isMarian)
        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        let isToday = calendar.isDateInToday(day)

        Button {
            withAnimation(MotionTokens.selection) {
                selectedDay = start
            }
        } label: {
            VStack(spacing: AppTheme.Space.xs) {
                Text("\(calendar.component(.day, from: day))")
                    .font(AppTheme.TypeRole.bodySmall(weight: isSelected || isToday ? .semibold : .regular))
                    .foregroundStyle(isSelected ? palette.primaryButtonText : (hasFeast ? palette.ink : palette.dim))
                    .frame(width: 32, height: 32)
                    .background {
                        if isSelected {
                            Circle().fill(palette.primaryButtonFill)
                        } else if isToday {
                            Circle().strokeBorder(palette.primaryButtonFill.opacity(0.55), lineWidth: 1.2)
                        }
                    }

                HStack(spacing: AppTheme.Space.xs) {
                    if hasMarian {
                        Circle()
                            .fill(isSelected ? palette.primaryButtonText.opacity(0.9) : palette.primaryButtonFill)
                            .frame(width: 4, height: 4)
                    } else if hasFeast {
                        Circle()
                            .fill(isSelected ? palette.primaryButtonText.opacity(0.7) : palette.faint)
                            .frame(width: 4, height: 4)
                    } else {
                        Color.clear.frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppTheme.Accessibility.minHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: day, feasts: feasts, isToday: isToday))
        .accessibilityHint(hasFeast ? "Selects this feast day" : "Selects this date")
    }

    private func accessibilityLabel(for day: Date, feasts: [DatedFeast], isToday: Bool) -> String {
        var parts: [String] = [day.formatted(.dateTime.weekday(.wide).month(.wide).day())]
        if isToday { parts.append("Today") }
        if !feasts.isEmpty {
            parts.append(feasts.map(\.feast.shortTitle).joined(separator: ", "))
        }
        return parts.joined(separator: ", ")
    }

    private func shiftMonth(_ delta: Int) {
        guard let next = calendar.date(byAdding: .month, value: delta, to: month) else { return }
        withAnimation(MotionTokens.selection) {
            month = next
            if let selectedDay, calendar.isDate(selectedDay, equalTo: next, toGranularity: .month) {
                return
            }
            // Prefer today when jumping back to the current month; otherwise first of month.
            if calendar.isDate(next, equalTo: Date(), toGranularity: .month) {
                selectedDay = calendar.startOfDay(for: Date())
            } else if let first = calendar.date(from: calendar.dateComponents([.year, .month], from: next)) {
                selectedDay = first
            }
        }
    }
}

// MARK: - Scope

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
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(spacing: 0) {
                Text(item.date.formatted(.dateTime.day()))
                    .font(AppTheme.TypeRole.sectionTitle)
                    .foregroundStyle(palette.ink)
                Text(item.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(AppTheme.TypeRole.caption(weight: .medium))
                    .tracking(1.1)
                    .foregroundStyle(palette.dim)
            }
            .frame(width: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.feast.shortTitle)
                    .font(AppTheme.TypeRole.bodySmall(weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .lineLimit(2)
                Text(item.feast.rank.title)
                    .font(AppTheme.TypeRole.label)
                    .foregroundStyle(palette.dim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .guideSymbol(size: 12, weight: .semibold)
                .foregroundStyle(palette.faint)
        }
        .padding(.vertical, 14)
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
                    .minimumScaleFactor(0.78)
                    .padding(.top, 8)

                Text(feast.summary)
                    .font(AppTheme.TypeRole.body)
                    .foregroundStyle(palette.dim)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)

                feastGuideSections
                    .padding(.top, 26)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.bottom, 108)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(palette.bg)
        // Keep native navigation visible so level-2 screens always have back navigation.
        // The system back gesture remains available from the far-left edge.
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(feast.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if expandedPrayerID == nil {
                expandedPrayerID = prayersForDay.first?.id
            }
        }
    }

    private var featuredPrayer: FeastRelatedPrayer? {
        feast.relatedPrayersForDay.first
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
            atAGlanceCard
            meaningSection
            keepTheDaySection
            prayersForDaySection
            scriptureRosarySection

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
                            .font(AppTheme.TypeRole.bodySmall.weight(.semibold))
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
        VStack(alignment: .leading, spacing: 12) {
            GuideSectionLabel(text: "Prayers for this day", prominence: .strong)
                .padding(.bottom, AppTheme.sectionTitleGap - 12)
            ForEach(prayersForDay) { prayer in
                prayerCard(prayer)
            }
        }
    }

    private var scriptureRosarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                                .font(AppTheme.TypeRole.bodySmall.weight(.semibold))
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

    private var devotionalMeditation: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            GuideSectionLabel(text: "Reflection", prominence: .strong)
            Text(devotionalCopy)
                .font(AppTheme.TypeRole.body)
                .foregroundStyle(palette.ink)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)

            Hairline()
                .padding(.top, 2)

            Text(reflectionPrompt)
                .font(AppTheme.TypeRole.bodySmall)
                .foregroundStyle(palette.dim)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.surface)
    }

    private var devotionalCopy: String {
        let source = feast.aboutText == feast.summary ? feast.summary : feast.aboutText
        let sentences = source
            .split(separator: ".", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let compact = sentences.prefix(2).map { "\($0)." }.joined(separator: " ")
        return compact.isEmpty ? feast.summary : compact
    }

    private var reflectionPrompt: String {
        if feast.isMarian {
            return "Ask Mary to help you receive this mystery with a quiet and faithful heart."
        }
        if feast.id == "michael" || feast.id == "guardian-angels" {
            return "Where do you need God’s guidance, protection, or healing today?"
        }
        if feast.rank == .solemnity {
            return "Let this solemnity draw your attention back to Christ, and begin from there."
        }
        return "Pause here for a moment. What grace do you want to ask for as you pray today?"
    }

    private var prayWithFeastButton: some View {
        Button {
            prayLaunch = .fresh(feast.suggestedMysterySet ?? feastDayAssignment.set)
        } label: {
            HStack(spacing: AppTheme.Space.lg) {
                Image(systemName: "hands.sparkles.fill")
                    .guideSymbol(size: 20, weight: .medium)
                    .foregroundStyle(palette.primaryButtonText)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: AppTheme.Space.xs) {
                    Text("Pray with this feast")
                        .font(AppTheme.TypeRole.callout(weight: .semibold))
                        .foregroundStyle(palette.primaryButtonText)
                    Text(prayWithFeastSubtitle)
                        .font(AppTheme.TypeRole.label)
                        .foregroundStyle(palette.primaryButtonText.opacity(0.72))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(AppTheme.TypeRole.label(weight: .semibold))
                    .foregroundStyle(palette.primaryButtonText)
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 64)
            .background(palette.primaryButtonFill, in: Capsule())
        }
        .buttonStyle(.plain)
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
            MysteryArtworkView(set: set, mysteryNumber: 1, slug: MysteryCatalog.mysteries(for: set).first?.artSlug, kind: .plate)
                .frame(width: 56, height: 56)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
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

    private func relatedPrayerPreview(_ prayer: FeastRelatedPrayer) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
            GuideSectionLabel(text: "Related prayer", prominence: .strong)
            Text(prayer.title)
                .font(AppTheme.TypeRole.titleSmall(weight: .semibold))
                .foregroundStyle(palette.ink)

            Text(prayerText(prayer))
                .font(AppTheme.TypeRole.bodySmall)
                .foregroundStyle(palette.dim)
                .lineSpacing(8)
                .lineLimit(5)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                FeastRelatedPrayersView(feast: feast)
                    .environment(settings)
            } label: {
                HStack {
                    Text("Pray this prayer")
                        .font(AppTheme.TypeRole.label(weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(AppTheme.TypeRole.caption(weight: .semibold))
                }
                .foregroundStyle(palette.ink)
                .padding(.top, 2)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .guideCard(radius: AppTheme.containerRadius, fill: palette.surface)
    }

    private var supportingLinks: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionTitleGap) {
            GuideSectionLabel(text: "More for this feast", prominence: .strong)
            infoRows
                .guideNavList(pageGutter: AppTheme.gutter)
        }
    }

    private var detailHero: some View {
        ZStack {
            FeastHeroBanner(feast: feast, height: 330, cornerRadius: 0)
                .frame(maxWidth: .infinity)
            LinearGradient(
                colors: [.clear, palette.bg.opacity(0.58), palette.bg],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: 330)
        .padding(.horizontal, -AppTheme.gutter)
        .padding(.top, -8)
        .ignoresSafeArea(edges: .top)
    }

    private var detailActions: some View {
        HStack(spacing: AppTheme.Space.md) {
            detailAction("Remind me", icon: "bell.fill")
            Button {
                prayLaunch = .fresh(feast.suggestedMysterySet ?? feastDayAssignment.set)
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "hands.sparkles.fill")
                        .guideSymbol(size: 20, weight: .medium)
                    Text("Pray")
                        .font(AppTheme.TypeRole.caption(weight: .medium))
                }
                .foregroundStyle(palette.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
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
        VStack(spacing: 8) {
            Image(systemName: icon)
                .guideSymbol(size: 20, weight: .medium)
                .foregroundStyle(palette.accent)
            Text(title)
                .font(AppTheme.TypeRole.caption(weight: .medium))
                .foregroundStyle(palette.ink)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 76)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.nestedRadius, style: .continuous)
                .strokeBorder(palette.subtleStroke, lineWidth: AppTheme.Component.panelStrokeWidth)
        }
    }

    private var infoRows: some View {
        VStack(spacing: 0) {
            NavigationLink {
                FeastReadMoreView(feast: feast)
            } label: {
                infoRow("Read more")
            }
            .buttonStyle(.plain)
            Hairline()
            NavigationLink {
                FeastRelatedPrayersView(feast: feast)
                    .environment(settings)
            } label: {
                infoRow("Related prayers")
            }
            .buttonStyle(.plain)
            Hairline()
            NavigationLink {
                FeastPatronagesView(feast: feast)
            } label: {
                infoRow("Patronages")
            }
            .buttonStyle(.plain)
            Hairline()
            NavigationLink {
                FeastScriptureView(feast: feast)
            } label: {
                infoRow("In Scripture")
            }
            .buttonStyle(.plain)
        }
    }

    private func infoRow(_ title: String) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(AppTheme.TypeRole.serifBody)
                .foregroundStyle(palette.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .guideSymbol(size: 12, weight: .semibold)
                .foregroundStyle(palette.faint)
        }
        .padding(.vertical, 17)
        .contentShape(Rectangle())
    }

    private func feastChip(_ label: String) -> some View {
        Text(label)
            .font(AppTheme.TypeRole.caption(weight: .medium))
            .foregroundStyle(palette.ink)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(palette.surface, in: Capsule())
            .overlay {
                Capsule().strokeBorder(palette.hair, lineWidth: 1)
            }
    }

    private func narrativeSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.md) {
            GuideSectionLabel(text: title, color: palette.dim)
            Text(body)
                .font(AppTheme.TypeRole.serifBody)
                .foregroundStyle(palette.ink)
                .lineSpacing(13)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var prayersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                withAnimation(.easeInOut(duration: 0.18)) {
                    expandedPrayerID = isExpanded ? nil : prayer.id
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Text(prayer.title)
                        .font(AppTheme.TypeRole.bodySmall.weight(.semibold))
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .guideSymbol(size: 12, weight: .semibold)
                        .foregroundStyle(palette.faint)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.18), value: isExpanded)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(prayer.title)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(isExpanded ? "Collapses the prayer" : "Expands the prayer")

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
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .guideRowGroup()
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
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                .strokeBorder(palette.hair, lineWidth: AppTheme.Component.panelStrokeWidth)
        }
    }
}

private struct FeastReadMoreView: View {
    var feast: Feast
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        FeastSecondaryPage(title: "Read more", feast: feast) {
            VStack(alignment: .leading, spacing: 28) {
                FeastTextPanel(title: "The feast", text: feast.aboutText)

                if let history = feast.historyText {
                    FeastTextPanel(title: "In the Church", text: history)
                }

                if let indulgence = feast.indulgenceNote {
                    FeastTextPanel(title: "Indulgence", text: indulgence)
                }
            }
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
            VStack(alignment: .leading, spacing: AppTheme.Space.lg) {
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
                withAnimation(.easeInOut(duration: 0.18)) {
                    expandedPrayerID = isExpanded ? nil : prayer.id
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Text(prayer.title)
                        .font(AppTheme.TypeRole.bodySmall.weight(.semibold))
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .guideSymbol(size: 12, weight: .semibold)
                        .foregroundStyle(palette.faint)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(prayer.title)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(isExpanded ? "Collapses the prayer" : "Expands the prayer")

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
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
        .overlay(alignment: .bottom) {
            Hairline()
        }
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
            VStack(alignment: .leading, spacing: 24) {
                Text("Traditions associated with this feast.")
                    .font(AppTheme.TypeRole.serifBody)
                    .foregroundStyle(palette.dim)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(patronages, id: \.self) { patronage in
                    VStack(alignment: .leading, spacing: 8) {
                        GuideSectionLabel(text: "Patronage", color: palette.faint)
                        Text(patronage)
                            .font(AppTheme.TypeRole.serifTitle)
                            .foregroundStyle(palette.ink)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 20)
                    .overlay(alignment: .bottom) {
                        Hairline()
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
            VStack(alignment: .leading, spacing: 24) {
                if passages.isEmpty {
                    FeastTextPanel(
                        title: "Scripture",
                        text: "\(feast.shortTitle) is held within the Church's living memory of Scripture, prayer, and worship."
                    )
                } else {
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
                        .overlay(alignment: .bottom) {
                            Hairline()
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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                FeastHeroBanner(feast: feast, height: 238, cornerRadius: 0)
                    .padding(.horizontal, -AppTheme.gutter)
                    .padding(.top, -8)
                    .padding(.bottom, 22)

                GuideSectionLabel(text: feast.rank.title, color: palette.dim)

                Text(title)
                    .font(AppTheme.TypeRole.serifDisplay)
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)

                Text(feast.shortTitle)
                    .font(AppTheme.TypeRole.serifBody)
                    .foregroundStyle(palette.dim)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .padding(.bottom, 30)

                content()

                Spacer(minLength: 34)
            }
            .padding(.horizontal, AppTheme.gutter)
            .padding(.bottom, 108)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(palette.bg)
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

// MARK: - Hero placeholder

private struct FeastHeroBanner: View {
    var feast: Feast
    var height: CGFloat = 200
    var cornerRadius: CGFloat = AppTheme.containerRadius
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
                    focus: UnitPoint(x: 0.5, y: 0.42)
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

            LinearGradient(
                colors: [
                    palette.bg.opacity(colorScheme == .light ? 0.28 : 0.40),
                    palette.bg.opacity(0.45),
                    palette.bg.opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            palette.bg.opacity(colorScheme == .light ? 0.14 : 0.22)

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
