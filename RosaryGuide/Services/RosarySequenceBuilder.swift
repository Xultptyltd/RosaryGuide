import Foundation

enum RosarySequenceBuilder {
    static func build(set: MysterySetKind) -> [RosaryStep] {
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
            stage: PrayTrackStage,
            bead: BeadLocus? = nil,
            scriptureReference: String? = nil
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
                    stage: stage,
                    bead: bead,
                    scriptureReference: scriptureReference
                )
            )
            id += 1
        }

        append(
            .signOfTheCross,
            intention: BilingualText(
                english: "Offer this Rosary for your intention",
                latin: "Offer this Rosary for your intention"
            ),
            haptic: .medium,
            stage: .opening,
            bead: .crucifix
        )
        append(.creed, haptic: .medium, stage: .opening, bead: .crucifix)
        append(.ourFather, haptic: .medium, stage: .opening, bead: .openingOurFather)
        for (index, intention) in PrayerCatalog.openingIntentions.enumerated() {
            append(
                .hailMary,
                subtitle: intention,
                hailMary: index + 1,
                intention: intention,
                haptic: .light,
                stage: .opening,
                bead: .openingHail(index + 1)
            )
        }
        append(.gloryBe, haptic: .medium, stage: .opening, bead: .openingGlory)

        for mystery in MysteryCatalog.mysteries(for: set) {
            let decade = mystery.number
            let stage = PrayTrackStage.decade(decade)
            append(
                .mysteryAnnouncement,
                title: mystery.title,
                body: mystery.scriptureExcerpt,
                subtitle: mystery.fruit,
                mystery: mystery,
                decade: decade,
                haptic: .heavy,
                stage: stage,
                bead: .decadeOurFather(decade),
                scriptureReference: mystery.scriptureReference
            )
            append(.ourFather, mystery: mystery, decade: decade, haptic: .medium, stage: stage, bead: .decadeOurFather(decade))
            for bead in 1...10 {
                append(
                    .hailMary,
                    mystery: mystery,
                    decade: decade,
                    hailMary: bead,
                    haptic: .light,
                    stage: stage,
                    bead: .decadeHail(decade, bead)
                )
            }
            append(.gloryBe, mystery: mystery, decade: decade, haptic: .medium, stage: stage, bead: .decadeGlory(decade))
            append(.fatima, mystery: mystery, decade: decade, haptic: .medium, stage: stage, bead: .decadeFatima(decade))
        }

        append(.hailHolyQueen, haptic: .medium, stage: .closing, bead: .closing)
        append(.versicle, haptic: .medium, stage: .closing, bead: .closing)
        append(.concludingPrayer, haptic: .medium, stage: .closing, bead: .closing)

        let quote = QuoteCatalog.freshCompletionQuote()
        append(
            .completion,
            title: BilingualText(english: "Rosary complete", latin: "Rosarium completum est."),
            body: BilingualText(english: quote.text, latin: quote.text),
            subtitle: BilingualText(english: quote.attribution, latin: quote.attribution),
            haptic: .success,
            stage: .closing
        )

        return steps
    }
}
