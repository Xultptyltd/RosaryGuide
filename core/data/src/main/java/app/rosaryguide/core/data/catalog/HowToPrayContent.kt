package app.rosaryguide.core.data.catalog

import app.rosaryguide.core.model.BilingualText

/** Ported from iOS `HowToPrayContent`. */
data class HowToPrayStep(
    val id: Int,
    val title: BilingualText,
    val body: String,
)

object HowToPrayContent {
    val introduction = BilingualText(
        english = "The Rosary is a Scripture-soaked prayer. Vocal prayers keep the hands and lips occupied so the heart can rest on the mysteries of Christ’s life, death, and glory, seen with Mary.",
        latin = "Rosárium orátio est Scriptúris imbúta. Preces vocáles manus et labia óccupant, ut cor in mystériis vitæ, mortis et glóriæ Christi cum María quiéscere possit.",
    )

    val steps: List<HowToPrayStep> = listOf(
        HowToPrayStep(
            id = 1,
            title = BilingualText(english = "Begin with the Sign of the Cross", latin = "Incipe Signo Crucis"),
            body = "Hold the crucifix. Bless yourself and place the whole rosary under the Holy Trinity.",
        ),
        HowToPrayStep(
            id = 2,
            title = BilingualText(english = "Pray the Apostles’ Creed", latin = "Recita Symbolum Apostolórum"),
            body = "Still holding the crucifix, profess the faith of the Church. The Creed gathers the mysteries you are about to contemplate.",
        ),
        HowToPrayStep(
            id = 3,
            title = BilingualText(english = "Our Father on the first bead", latin = "Pater Noster in primo grano"),
            body = "On the large bead above the crucifix, pray the Our Father.",
        ),
        HowToPrayStep(
            id = 4,
            title = BilingualText(english = "Three Hail Marys", latin = "Tres Ave María"),
            body = "On the next three small beads, pray Hail Marys for an increase of Faith, Hope, and Charity.",
        ),
        HowToPrayStep(
            id = 5,
            title = BilingualText(english = "Glory be", latin = "Glória Patri"),
            body = "On the chain or large bead before the centerpiece, pray the Glory Be.",
        ),
        HowToPrayStep(
            id = 6,
            title = BilingualText(english = "Announce the mystery and pray a decade", latin = "Mystérium nuntia et decádem recita"),
            body = "For each of the five decades: announce the mystery, read a short Scripture, ask for its fruit, pray an Our Father, ten Hail Marys, a Glory Be, and the Fatima prayer.",
        ),
        HowToPrayStep(
            id = 7,
            title = BilingualText(english = "Hail, Holy Queen and concluding prayer", latin = "Salve Regína et orátio finalis"),
            body = "After the fifth decade, pray the Hail, Holy Queen, the versicle, and the collect: that we may imitate what the mysteries contain and obtain what they promise.",
        ),
        HowToPrayStep(
            id = 8,
            title = BilingualText(english = "Optional Saint Michael after Finis", latin = "Sanctus Michael post finem"),
            body = "When the rosary is finished, you may pray the Prayer to Saint Michael from the Finis screen.",
        )
    )

    val weekdayGuide: List<Pair<String, String>> = listOf(
        "Sunday" to "Glorious Mysteries",
        "Monday" to "Joyful Mysteries",
        "Tuesday" to "Sorrowful Mysteries",
        "Wednesday" to "Glorious Mysteries",
        "Thursday" to "Luminous Mysteries",
        "Friday" to "Sorrowful Mysteries",
        "Saturday" to "Joyful Mysteries",
    )

    const val beadsNote = "A five-decade rosary has a crucifix, a short tail of beads, a centerpiece, and a loop of five groups of ten beads separated by larger beads. You do not need beads to pray: the app counts for you. Beads help the body keep time so the mind can stay with Christ."
}
