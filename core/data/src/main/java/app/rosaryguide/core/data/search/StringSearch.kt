package app.rosaryguide.core.data.search

import java.text.Normalizer

/**
 * Diacritic-insensitive, case-insensitive containment, matching Foundation's
 * `localizedStandardContains` closely enough for the feast-search tests
 * (e.g. "Assumptio" matches "Assúmptio").
 */
fun String.localizedStandardContains(query: String): Boolean {
    if (query.isEmpty()) return true
    return foldForSearch().contains(query.foldForSearch())
}

fun String.foldForSearch(): String {
    val normalized = Normalizer.normalize(this, Normalizer.Form.NFD)
    return buildString(normalized.length) {
        for (ch in normalized) {
            val type = Character.getType(ch)
            if (type != Character.NON_SPACING_MARK.toInt() &&
                type != Character.COMBINING_SPACING_MARK.toInt() &&
                type != Character.ENCLOSING_MARK.toInt()
            ) {
                append(ch.lowercaseChar())
            }
        }
    }
}
