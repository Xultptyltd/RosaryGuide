import Foundation

/// Stable identity of a step across configs: the same prayer at the same place
/// in the Rosary keeps its identity when other prayers are added or removed.
struct RosaryStepIdentity: Hashable {
    let kind: RosaryStepKind
    let stage: PrayTrackStage
    let decade: Int?
    let hailMary: Int?
}

extension RosaryStep {
    var identity: RosaryStepIdentity {
        RosaryStepIdentity(kind: kind, stage: stage, decade: decadeNumber, hailMary: hailMaryNumber)
    }
}

enum RosarySequenceBuilder {
    /// Maps a position in `old` to the equivalent position in `new` (same set, different config).
    /// A surviving step keeps its identity. If the current step was removed, the user lands on
    /// the first step after the last surviving step before it, so already-prayed steps are not
    /// replayed and a prayer newly added right there comes next.
    static func remap(index: Int, from old: [RosaryStep], to new: [RosaryStep]) -> Int {
        guard !new.isEmpty else { return 0 }
        guard old.indices.contains(index) else { return min(max(index, 0), new.count - 1) }
        var lookup: [RosaryStepIdentity: Int] = [:]
        for (offset, step) in new.enumerated() where lookup[step.identity] == nil {
            lookup[step.identity] = offset
        }
        if let same = lookup[old[index].identity] { return same }
        for previous in stride(from: index - 1, through: 0, by: -1) {
            if let mapped = lookup[old[previous].identity] {
                return min(mapped + 1, new.count - 1)
            }
        }
        return 0
    }

    static func build(set: MysterySetKind, config: RosaryConfig = .default) -> [RosaryStep] {
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
                    haptic: RosaryHaptics.kind(for: kind),
                    stage: stage,
                    bead: bead,
                    scriptureReference: scriptureReference
                )
            )
            id += 1
        }

        append(
            .signOfTheCross,
            // No Latin version: Latin and Both show the English once.
            intention: BilingualText(english: "Offer this Rosary for your intention", latin: ""),
            stage: .opening,
            bead: .crucifix
        )
        append(.creed, stage: .opening, bead: .crucifix)
        append(.ourFather, stage: .opening, bead: .openingOurFather)
        for (index, intention) in PrayerCatalog.openingIntentions.enumerated() {
            append(
                .hailMary,
                subtitle: intention,
                hailMary: index + 1,
                intention: intention,
                stage: .opening,
                bead: .openingHail(index + 1)
            )
        }
        append(.gloryBe, stage: .opening, bead: .openingGlory)

        for mystery in MysteryCatalog.mysteries(for: set) {
            let decade = mystery.number
            let stage = PrayTrackStage.decade(decade)
            append(
                .mysteryAnnouncement,
                title: mystery.title,
                body: BilingualText(
                    english: MysteryScripture.excerpt(for: mystery, translation: config.translation),
                    latin: MysteryScripture.excerpt(for: mystery, translation: .vulgate)
                ),
                subtitle: mystery.fruit,
                mystery: mystery,
                decade: decade,
                stage: stage,
                bead: .decadeOurFather(decade),
                scriptureReference: mystery.scriptureReference
            )
            append(.ourFather, mystery: mystery, decade: decade, stage: stage, bead: .decadeOurFather(decade))
            for bead in 1...10 {
                append(
                    .hailMary,
                    mystery: mystery,
                    decade: decade,
                    hailMary: bead,
                    stage: stage,
                    bead: .decadeHail(decade, bead)
                )
            }
            append(.gloryBe, mystery: mystery, decade: decade, stage: stage, bead: .decadeGlory(decade))
            if config.fatimaPrayer {
                append(.fatima, mystery: mystery, decade: decade, stage: stage, bead: .decadeFatima(decade))
            }
            if config.oSacrament {
                append(.oSacrament, mystery: mystery, decade: decade, stage: stage, bead: .decadeFatima(decade))
            }
            steps[steps.count - 1].closesDecade = true
        }

        // Extra closing prayers share the closing medal on the bead map.
        if config.closingPrayers {
            append(.hailHolyQueen, stage: .closing, bead: .closing)
            append(.versicle, stage: .closing, bead: .closing)
            append(.concludingPrayer, stage: .closing, bead: .closing)
        }
        if config.memorare {
            append(.memorare, stage: .closing, bead: .closing)
        }
        if config.saintMichael {
            append(.saintMichael, stage: .closing, bead: .closing)
        }
        // The Rosary ends as it began, with the Sign of the Cross.
        append(.signOfTheCross, stage: .closing, bead: .closing)
        steps[steps.count - 1].isLastPrayer = true

        // The finis screen picks its own quote. Do not call freshCompletionQuote
        // here: it writes UserDefaults, and this builder runs from view bodies
        // (resume titles). That write invalidates @AppStorage and rebuilds forever.
        append(
            .completion,
            title: BilingualText(english: "Rosary complete", latin: "Rosarium completum est."),
            body: BilingualText(english: "", latin: ""),
            subtitle: nil,
            stage: .closing
        )

        return steps
    }
}
