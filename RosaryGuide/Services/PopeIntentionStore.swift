import Foundation

struct PopeMonthIntention: Codable, Hashable, Sendable {
    /// "2026-09"
    var yearMonth: String
    var title: String
    var note: String?

    var monthLabel: String {
        let parts = yearMonth.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))
        else { return yearMonth }
        return date.formatted(.dateTime.month(.wide).year())
    }
}

/// Bundled annual papal intentions, updated manually once a year.
@Observable
final class PopeIntentionStore {
    static let shared = PopeIntentionStore()

    private(set) var intentions: [PopeMonthIntention] = []

    init() {
        intentions = loadBundled()
    }

    func intention(for date: Date = Date()) -> PopeMonthIntention? {
        let key = Self.yearMonth(for: date)
        return intentions.first { $0.yearMonth == key }
    }

    private func loadBundled() -> [PopeMonthIntention] {
        guard let url = Bundle.main.url(forResource: "PopeIntentions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([PopeMonthIntention].self, from: data)
        else { return [] }
        return decoded.sorted { $0.yearMonth < $1.yearMonth }
    }

    private static func yearMonth(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

}
