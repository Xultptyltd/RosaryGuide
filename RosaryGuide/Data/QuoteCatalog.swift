import Foundation

enum QuoteCatalog {
    /// Legacy key from the random picker; read once to continue after that quote, then removed.
    private static let lastCompletionQuoteKey = "rosary.completion.lastQuoteId"
    private static let nextCompletionQuoteKey = "rosary.completion.nextQuoteIndex"

    /// Verified Rosary quotes; exact wording and sources in the Rosary quote fact-check.
    static let all: [CompletionQuote] = [
        CompletionQuote(id: "montfort-treasure", text: "The Rosary is a priceless treasure which is inspired by God.", attribution: "St Louis de Montfort"),
        CompletionQuote(id: "fatima-peace", text: "Pray the Rosary every day, in order to obtain peace for the world, and the end of the war.", attribution: "Our Lady of Fatima"),
        CompletionQuote(id: "escriva-weapon", text: "The holy Rosary is a powerful weapon. Use it with confidence and you will be amazed at the results.", attribution: "St Josemaría Escrivá"),
        CompletionQuote(id: "montfort-devils", text: "The devils have an overwhelming fear of the Rosary.", attribution: "St Louis de Montfort"),
        CompletionQuote(id: "jp2-burdens", text: "To pray the Rosary is to hand over our burdens to the merciful hearts of Christ and his Mother.", attribution: "St John Paul II"),
        CompletionQuote(id: "jp2-accompanied", text: "The Rosary has accompanied me in moments of joy and in moments of difficulty.", attribution: "St John Paul II"),
        CompletionQuote(id: "escriva-monotony", text: "Blessed be that monotony of Hail Marys which purifies the monotony of your sins!", attribution: "St Josemaría Escrivá"),
        CompletionQuote(id: "jp2-peacemakers", text: "In a word, by focusing our eyes on Christ, the Rosary also makes us peacemakers in the world.", attribution: "St John Paul II"),
        CompletionQuote(id: "francis-school", text: "The Rosary is a school of prayer, the Rosary is a school of faith!", attribution: "Pope Francis"),
        CompletionQuote(id: "longo-chain", text: "O Blessed Rosary of Mary, sweet chain which unites us to God… we will never abandon you.", attribution: "Bl. Bartolo Longo"),
        CompletionQuote(id: "longo-spreads", text: "Whoever spreads the Rosary is saved!", attribution: "Bl. Bartolo Longo"),
        CompletionQuote(id: "jp2-favourite", text: "The Rosary is my favourite prayer. A marvellous prayer! Marvellous in its simplicity and its depth.", attribution: "St John Paul II"),
        CompletionQuote(id: "jp2-rhythm", text: "The simple prayer of the Rosary marks the rhythm of human life.", attribution: "St John Paul II"),
        CompletionQuote(id: "jp2-contemplate", text: "To recite the Rosary is nothing other than to contemplate with Mary the face of Christ.", attribution: "St John Paul II")
    ]

    /// Short enough to show fully on the completion screen without truncation.
    static let maxCompletionCharacters = 99

    static var shortQuotes: [CompletionQuote] {
        all.filter { $0.text.count <= maxCompletionCharacters }
    }

    /// Prefer a short quote so the completion screen never truncates.
    static func quote(for date: Date = .now, calendar: Calendar = .current) -> CompletionQuote {
        let pool = shortQuotes.isEmpty ? all : shortQuotes
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        return pool[day % pool.count]
    }

    /// Index of the quote the next completed Rosary will show. Cycles through every quote
    /// in catalog order, so none repeats until all have been seen.
    static func nextCompletionIndex(defaults: UserDefaults = .standard) -> Int {
        let pool = shortQuotes.isEmpty ? all : shortQuotes
        if defaults.object(forKey: nextCompletionQuoteKey) != nil {
            return max(0, defaults.integer(forKey: nextCompletionQuoteKey)) % pool.count
        }
        // Migrate from the old random picker: continue after the last quote shown.
        if let lastId = defaults.string(forKey: lastCompletionQuoteKey),
           let last = pool.firstIndex(where: { $0.id == lastId }) {
            return (last + 1) % pool.count
        }
        return 0
    }

    /// The quote for this completion, without writing `UserDefaults`. Writing during a view
    /// update posts a defaults notification and the scene update never returns.
    static func selectCompletionQuote(defaults: UserDefaults = .standard) -> CompletionQuote {
        let pool = shortQuotes.isEmpty ? all : shortQuotes
        return pool[nextCompletionIndex(defaults: defaults)]
    }

    /// Advance the cycle past `quote`. Call once per completed Rosary.
    static func rememberCompletionQuote(_ quote: CompletionQuote, defaults: UserDefaults = .standard) {
        let pool = shortQuotes.isEmpty ? all : shortQuotes
        let shown = pool.firstIndex(where: { $0.id == quote.id }) ?? nextCompletionIndex(defaults: defaults)
        defaults.set((shown + 1) % pool.count, forKey: nextCompletionQuoteKey)
        defaults.removeObject(forKey: lastCompletionQuoteKey)
    }

    /// Pick this completion's quote and advance the cycle.
    static func freshCompletionQuote(defaults: UserDefaults = .standard) -> CompletionQuote {
        let selected = selectCompletionQuote(defaults: defaults)
        rememberCompletionQuote(selected, defaults: defaults)
        return selected
    }
}
