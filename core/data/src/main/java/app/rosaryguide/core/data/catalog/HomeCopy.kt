package app.rosaryguide.core.data.catalog

import app.rosaryguide.core.model.MysterySetKind

/** Home / Today copy, ported from iOS `HomeView`. */
object HomeCopy {
    const val TODAY_PILL = "TODAY"
    const val UPCOMING_FEAST_DAYS = "Upcoming feast days"
    const val THIS_WEEK = "This week"
    const val VIEW_ALL_FEASTS = "View all feasts"
    const val PRAY_TODAYS_MYSTERIES = "Pray today's mysteries"
    const val PRAY_AGAIN = "Pray again"

    fun prayTheMysteries(set: MysterySetKind): String =
        "Pray the ${set.shortName} Mysteries"
}
