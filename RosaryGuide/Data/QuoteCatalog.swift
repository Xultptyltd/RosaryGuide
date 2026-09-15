import Foundation

enum QuoteCatalog {
    static let all: [CompletionQuote] = [
        CompletionQuote(
            id: "jp2",
            text: "The Rosary is my favorite prayer. A marvelous prayer! Marvelous in its simplicity and its depth.",
            attribution: "St. John Paul II"
        ),
        CompletionQuote(
            id: "fatima",
            text: "Say the Rosary every day, to bring peace to the world and the end of the war.",
            attribution: "Our Lady of Fatima"
        ),
        CompletionQuote(
            id: "montfort",
            text: "Never will anyone who says his Rosary every day be led astray. This is a statement that I would gladly sign with my blood.",
            attribution: "St. Louis de Montfort"
        ),
        CompletionQuote(
            id: "pio",
            text: "The Rosary is the weapon for these times.",
            attribution: "St. Pio of Pietrelcina"
        ),
        CompletionQuote(
            id: "escriva",
            text: "The holy Rosary is a powerful weapon. Use it with confidence and you will be amazed at the results.",
            attribution: "St. Josemaría Escrivá"
        ),
        CompletionQuote(
            id: "leo13",
            text: "The Rosary is the most excellent form of prayer and the most efficacious means of attaining eternal life.",
            attribution: "Pope Leo XIII"
        ),
        CompletionQuote(
            id: "dominic",
            text: "One day, through the Rosary and the Scapular, Our Lady will save the world.",
            attribution: "St. Dominic"
        ),
        CompletionQuote(
            id: "piusix",
            text: "Give me an army saying the Rosary and I will conquer the world.",
            attribution: "Bl. Pope Pius IX"
        ),
        CompletionQuote(
            id: "teresa",
            text: "The greatest method of praying is to pray the Rosary.",
            attribution: "St. Francis de Sales"
        ),
        CompletionQuote(
            id: "alphonsus",
            text: "If you want to lead a life of continual prayer, say the Rosary well.",
            attribution: "St. Alphonsus Liguori"
        ),
        CompletionQuote(
            id: "benedict",
            text: "The Rosary is a school of contemplation and silence.",
            attribution: "Pope Benedict XVI"
        ),
        CompletionQuote(
            id: "piusv",
            text: "The Rosary is a powerful weapon to put the demons to flight.",
            attribution: "St. Pius V"
        )
    ]

    static func quote(for date: Date = .now, calendar: Calendar = .current) -> CompletionQuote {
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        return all[day % all.count]
    }

    static func quote(at index: Int) -> CompletionQuote {
        all[((index % all.count) + all.count) % all.count]
    }
}
