package app.rosaryguide.core.data.notify

import app.rosaryguide.core.data.calendar.MysteryCalendar
import app.rosaryguide.core.model.Feast
import java.time.LocalDate

/**
 * Daily and feast notification sentences, ported from iOS `NotificationService`.
 */
object ReminderCopy {
    fun dailyBody(weekday: Int, day: LocalDate): String {
        val set = MysteryCalendar.assignment(day).set
        return "Time to pray the ${set.shortName} Mysteries. Take a few quiet minutes for the Rosary."
    }

    /** "Today is the solemnity of All Saints"; several feasts on one day join with "and". */
    fun feastBody(feasts: List<Feast>): String =
        "Today is " + feasts.joinToString(" and ") { feastPhrase(it) }

    /**
     * "the memorial of Our Lady of the Rosary". Seasonal days have no rank word, so they
     * read as the day itself: "Ash Wednesday", "the First Sunday of Advent".
     */
    fun feastPhrase(feast: Feast): String {
        val named = articled(feast.name.english)
        val rank = feast.rank.notificationWord ?: return named
        return "the $rank of $named"
    }

    /**
     * Mystery and season names take "the" ("the Presentation of the Lord", "the First Sunday
     * of Advent"); people and titles don't ("All Saints", "Saint Joseph", "Our Lady of Lourdes").
     */
    internal fun articled(name: String): String {
        if (name.startsWith("The ")) return "the " + name.drop(4)
        val takesArticle = listOf(
            "Presentation", "Epiphany", "Annunciation", "Visitation", "Nativity", "Baptism",
            "Ascension", "Assumption", "Commemoration", "First", "Second", "Third", "Fourth", "Fifth",
        )
        return if (takesArticle.any { name.startsWith("$it ") }) "the $name" else name
    }
}
