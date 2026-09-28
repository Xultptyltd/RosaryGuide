import Foundation

struct PopeMonthIntention: Codable, Hashable, Sendable {
    /// "2026-09"
    var yearMonth: String
    var title: String
    var note: String?
    var description: String?
    var extract: [String]?
    var sourceTitle: String?
    var sourceURL: String?

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

/// Bundled papal intentions with optional remote refresh.
/// Set `remoteURL` to a JSON file you control (Netlify / GitHub raw) to update without an App Store release.
@Observable
final class PopeIntentionStore {
    static let shared = PopeIntentionStore()
    static let defaultRemoteURL = URL(string: "https://raw.githubusercontent.com/Xultptyltd/RosaryGuide/main/RosaryGuide/Data/PopeIntentions.json")

    /// Override for tests or a future hosted endpoint.
    var remoteURL: URL?

    private(set) var intentions: [PopeMonthIntention] = []
    private let cacheKey = "offer.popeIntentions.cache"
    private let cacheDateKey = "offer.popeIntentions.cacheDate"

    init(remoteURL: URL? = PopeIntentionStore.defaultRemoteURL) {
        self.remoteURL = remoteURL
        intentions = loadCached() ?? loadBundled()
    }

    func intention(for date: Date = Date()) -> PopeMonthIntention? {
        let key = Self.yearMonth(for: date)
        return intentions.first { $0.yearMonth == key }
    }

    @MainActor
    func refreshIfNeeded(force: Bool = false) async {
        guard let remoteURL else { return }
        if !force,
           let cachedAt = UserDefaults.standard.object(forKey: cacheDateKey) as? Date,
           Date().timeIntervalSince(cachedAt) < 12 * 60 * 60 {
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                return
            }
            let decoded = try JSONDecoder().decode([PopeMonthIntention].self, from: data)
            guard Self.isValid(decoded) else { return }
            intentions = decoded.sorted { $0.yearMonth < $1.yearMonth }
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheDateKey)
        } catch {
            // Keep bundled / last cache quietly.
        }
    }

    private func loadBundled() -> [PopeMonthIntention] {
        guard let url = Bundle.main.url(forResource: "PopeIntentions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([PopeMonthIntention].self, from: data)
        else { return [] }
        return decoded.sorted { $0.yearMonth < $1.yearMonth }
    }

    private func loadCached() -> [PopeMonthIntention]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([PopeMonthIntention].self, from: data),
              !decoded.isEmpty
        else { return nil }
        return decoded.sorted { $0.yearMonth < $1.yearMonth }
    }

    private static func yearMonth(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    private static func isValid(_ intentions: [PopeMonthIntention]) -> Bool {
        !intentions.isEmpty
            && intentions.allSatisfy {
                $0.yearMonth.range(of: #"^\d{4}-\d{2}$"#, options: .regularExpression) != nil
                    && !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
    }
}
