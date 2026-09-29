import Foundation

enum QuoteCatalog {
    static let all: [CompletionQuote] = [
        CompletionQuote(id: "m1", text: "When the Holy Rosary is said well, it gives Jesus and Mary more glory and is more meritorious than any other prayer.", attribution: "St. Louis de Montfort"),
        CompletionQuote(id: "m2", text: "Never will anyone who says his Rosary every day be led astray. This is a statement that I would gladly sign with my blood.", attribution: "St. Louis de Montfort"),
        CompletionQuote(id: "m3", text: "The Rosary is the most powerful weapon to touch the Heart of Jesus, Our Redeemer, who loves His Mother.", attribution: "St. Louis de Montfort"),
        CompletionQuote(id: "m4", text: "The rose is the queen of flowers, and so the Rosary is the rose of devotions and the most important one.", attribution: "St. Louis de Montfort"),
        CompletionQuote(id: "m5", text: "The Rosary is a priceless treasure inspired by God.", attribution: "St. Louis de Montfort"),
        CompletionQuote(id: "m6", text: "If you say the Rosary faithfully unto death… you will receive a never-fading crown of glory.", attribution: "St. Louis de Montfort"),
        CompletionQuote(id: "p1", text: "The Rosary is the weapon for these times.", attribution: "St. Padre Pio"),
        CompletionQuote(id: "p2", text: "Love the Madonna and pray the Rosary, for her Rosary is the weapon against the evils of the world today.", attribution: "St. Padre Pio"),
        CompletionQuote(id: "p3", text: "The Rosary is a powerful weapon to put the demons to flight.", attribution: "St. Padre Pio"),
        CompletionQuote(id: "pius9", text: "Give me an army saying the Rosary and I will conquer the world.", attribution: "Blessed Pope Pius IX"),
        CompletionQuote(id: "sales", text: "The greatest method of praying is to pray the Rosary.", attribution: "St. Francis de Sales"),
        CompletionQuote(id: "jp2a", text: "The Rosary is my favorite prayer. A marvelous prayer! Marvelous in its simplicity and its depth.", attribution: "St. John Paul II"),
        CompletionQuote(id: "jp2b", text: "How beautiful is the family that recites the Rosary every evening.", attribution: "St. John Paul II"),
        CompletionQuote(id: "piusx", text: "The Rosary is the most beautiful and the richest in graces of all prayers… if you wish peace to reign in your homes, recite the family Rosary.", attribution: "Pope St. Pius X"),
        CompletionQuote(id: "leo13", text: "The Rosary is the most excellent form of prayer and the most efficacious means of attaining eternal life.", attribution: "Pope Leo XIII"),
        CompletionQuote(id: "vianney", text: "All my works and labors are based on two things: The Mass and the Rosary.", attribution: "St. John Vianney"),
        CompletionQuote(id: "dominic", text: "One day, through the Rosary and the Scapular, Our Lady will save the world.", attribution: "Attributed to St. Dominic"),
        CompletionQuote(id: "alan1", text: "You shall obtain all you ask of me by the recitation of the Rosary.", attribution: "Our Lady to Blessed Alan de la Roche"),
        CompletionQuote(id: "alan2", text: "After the Holy Sacrifice of the Mass, there is nothing in the Church that I love as much as the Rosary.", attribution: "Our Lady to Blessed Alan de la Roche"),
        CompletionQuote(id: "lucia", text: "There is no problem, I tell you, no matter how difficult it is, that we cannot resolve by the prayer of the Holy Rosary.", attribution: "Sister Lucia of Fatima")
    ]

    /// Short enough to show fully on the completion screen without truncation.
    private static let maxCompletionCharacters = 90

    static var shortQuotes: [CompletionQuote] {
        all.filter { $0.text.count <= maxCompletionCharacters }
    }

    /// Prefer a short quote so the completion screen never truncates.
    static func quote(for date: Date = .now, calendar: Calendar = .current) -> CompletionQuote {
        let pool = shortQuotes.isEmpty ? all : shortQuotes
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        return pool[day % pool.count]
    }
}
