package app.rosaryguide.core.data.session

/** Display helpers for one or more offered intentions, ported from iOS `OfferedIntentions`. */
object OfferedIntentions {
    fun titles(titles: List<String>?, legacy: String?): List<String> {
        val source = titles ?: listOfNotNull(legacy)
        return source.map { it.trim() }.filter { it.isNotEmpty() }
    }

    /** "A", "A and B", "A, B and C". */
    fun summary(titles: List<String>): String? = when (titles.size) {
        0 -> null
        1 -> titles[0]
        else -> titles.dropLast(1).joinToString(", ") + " and " + titles.last()
    }

    /** "1 intention" / "N intentions"; null when none were offered. */
    fun countText(titles: List<String>): String? = when (titles.size) {
        0 -> null
        1 -> "1 intention"
        else -> "${titles.size} intentions"
    }
}
