import Foundation

enum RosarySequenceBuilder {
    static func build(set: MysterySetKind, includeSaintMichael: Bool) -> [RosaryStep] {
        var steps: [RosaryStep] = []
        var id = 0

        func append(
            _ kind: RosaryStepKind,
            title: BilingualText? = nil,
            body: BilingualText? = nil,
            subtitle: BilingualText? = nil,
            mystery: Mystery? = nil,
            decade: Int? = nil,
            hailMary: Int? = nil,
            intention: BilingualText? = nil,
            haptic: HapticKind,
            opening: Bool = false,
            closing: Bool = false
        ) {
            let prayer = PrayerCatalog.prayer(for: kind)
            steps.append(
                RosaryStep(
                    id: id,
                    kind: kind,
                    title: title ?? prayer?.title ?? BilingualText(english: "", latin: ""),
                    body: body ?? prayer?.text ?? BilingualText(english: "", latin: ""),
                    subtitle: subtitle ?? intention,
                    mystery: mystery,
                    decadeNumber: decade,
                    hailMaryNumber: hailMary,
                    intention: intention,
                    haptic: haptic,
                    isOpening: opening,
                    isClosing: closing
                )
            )
            id += 1
        }

        append(.signOfTheCross, haptic: .medium, opening: true)
        append(.creed, haptic: .medium, opening: true)
        append(.ourFather, haptic: .medium, opening: true)

        for (index, intention) in PrayerCatalog.openingIntentions.enumerated() {
            append(
                .hailMary,
                subtitle: intention,
                hailMary: index + 1,
                intention: intention,
                haptic: .light,
                opening: true
            )
        }

        append(.gloryBe, haptic: .medium, opening: true)

        let mysteries = MysteryCatalog.mysteries(for: set)
        for mystery in mysteries {
            let decade = mystery.number
            let ordinal = BilingualText(
                english: "\(OrdinalWord.english(decade)) \(mystery.set.ordinalAdjective.english) Mystery",
                latin: "\(OrdinalWord.latin(decade)) Mystérium \(mystery.set.ordinalAdjective.latin)"
            )

            append(
                .mysteryAnnouncement,
                title: mystery.title,
                body: BilingualText(
                    english: """
                    \(ordinal.english)

                    Fruit: \(mystery.fruit.english)
                    \(mystery.scriptureReference)

                    \(mystery.scriptureExcerpt.english)

                    \(mystery.meditation.english)
                    """,
                    latin: """
                    \(ordinal.latin)

                    Fructus: \(mystery.fruit.latin)
                    \(mystery.scriptureReference)

                    \(mystery.scriptureExcerpt.latin)

                    \(mystery.meditation.latin)
                    """
                ),
                subtitle: mystery.fruit,
                mystery: mystery,
                decade: decade,
                haptic: .heavy
            )

            append(.ourFather, mystery: mystery, decade: decade, haptic: .medium)

            for bead in 1...10 {
                append(
                    .hailMary,
                    mystery: mystery,
                    decade: decade,
                    hailMary: bead,
                    haptic: .light
                )
            }

            append(.gloryBe, mystery: mystery, decade: decade, haptic: .medium)
            append(.fatima, mystery: mystery, decade: decade, haptic: .medium)
        }

        append(.hailHolyQueen, haptic: .medium, closing: true)
        append(.concludingPrayer, haptic: .medium, closing: true)

        if includeSaintMichael {
            append(.saintMichael, haptic: .medium, closing: true)
        }

        append(.signOfTheCross, haptic: .medium, closing: true)

        let quote = QuoteCatalog.quote()
        append(
            .completion,
            title: BilingualText(english: "Rosary complete", latin: "Rosárium complétum"),
            body: BilingualText(
                english: "“\(quote.text)”\n\n— \(quote.attribution)",
                latin: "“\(quote.text)”\n\n— \(quote.attribution)"
            ),
            haptic: .success,
            closing: true
        )

        return steps
    }
}
