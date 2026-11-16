package app.rosaryguide.core.data.catalog

import app.rosaryguide.core.model.CompletionQuote
import java.time.LocalDate

/** Mutable store used by the completion-quote cycle, matching iOS `UserDefaults` keys. */
interface QuotePreferences {
    fun contains(key: String): Boolean
    fun getInt(key: String, default: Int = 0): Int
    fun getString(key: String): String?
    fun setInt(key: String, value: Int)
    fun remove(key: String)
}

class MapQuotePreferences : QuotePreferences {
    private val values = mutableMapOf<String, Any>()
    override fun contains(key: String): Boolean = key in values
    override fun getInt(key: String, default: Int): Int = (values[key] as? Int) ?: default
    override fun getString(key: String): String? = values[key] as? String
    override fun setInt(key: String, value: Int) { values[key] = value }
    override fun remove(key: String) { values.remove(key) }
    fun setString(key: String, value: String) { values[key] = value }
}

/**
 * Verified Rosary quotes, ported as-is from iOS `QuoteCatalog`.
 */
object QuoteCatalog {
    const val LAST_COMPLETION_QUOTE_KEY = "rosary.completion.lastQuoteId"
    const val NEXT_COMPLETION_QUOTE_KEY = "rosary.completion.nextQuoteIndex"

    val all: List<CompletionQuote> = listOf(
        CompletionQuote(id = "montfort-treasure", text = "The Rosary is a priceless treasure which is inspired by God.", attribution = "St Louis de Montfort"),
        CompletionQuote(id = "fatima-peace", text = "Pray the Rosary every day, in order to obtain peace for the world, and the end of the war.", attribution = "Our Lady of Fatima"),
        CompletionQuote(id = "escriva-weapon", text = "The holy Rosary is a powerful weapon. Use it with confidence and you will be amazed at the results.", attribution = "St Josemaría Escrivá"),
        CompletionQuote(id = "montfort-devils", text = "The devils have an overwhelming fear of the Rosary.", attribution = "St Louis de Montfort"),
        CompletionQuote(id = "jp2-burdens", text = "To pray the Rosary is to hand over our burdens to the merciful hearts of Christ and his Mother.", attribution = "St John Paul II"),
        CompletionQuote(id = "jp2-accompanied", text = "The Rosary has accompanied me in moments of joy and in moments of difficulty.", attribution = "St John Paul II"),
        CompletionQuote(id = "escriva-monotony", text = "Blessed be that monotony of Hail Marys which purifies the monotony of your sins!", attribution = "St Josemaría Escrivá"),
        CompletionQuote(id = "jp2-peacemakers", text = "In a word, by focusing our eyes on Christ, the Rosary also makes us peacemakers in the world.", attribution = "St John Paul II"),
        CompletionQuote(id = "francis-school", text = "The Rosary is a school of prayer, the Rosary is a school of faith!", attribution = "Pope Francis"),
        CompletionQuote(id = "longo-chain", text = "O Blessed Rosary of Mary, sweet chain which unites us to God… we will never abandon you.", attribution = "Bl. Bartolo Longo"),
        CompletionQuote(id = "longo-spreads", text = "Whoever spreads the Rosary is saved!", attribution = "Bl. Bartolo Longo"),
        CompletionQuote(id = "jp2-favourite", text = "The Rosary is my favourite prayer. A marvellous prayer! Marvellous in its simplicity and its depth.", attribution = "St John Paul II"),
        CompletionQuote(id = "jp2-rhythm", text = "The simple prayer of the Rosary marks the rhythm of human life.", attribution = "St John Paul II"),
        CompletionQuote(id = "jp2-contemplate", text = "To recite the Rosary is nothing other than to contemplate with Mary the face of Christ.", attribution = "St John Paul II")
    )

    const val maxCompletionCharacters = 99

    val shortQuotes: List<CompletionQuote>
        get() = all.filter { it.text.length <= maxCompletionCharacters }

    private fun pool(): List<CompletionQuote> = if (shortQuotes.isEmpty()) all else shortQuotes

    /** Prefer a short quote so the completion screen never truncates. Cycles by day of year. */
    fun quote(date: LocalDate): CompletionQuote {
        val pool = pool()
        val day = date.dayOfYear
        return pool[day % pool.size]
    }

    fun nextCompletionIndex(defaults: QuotePreferences): Int {
        val pool = pool()
        if (defaults.contains(NEXT_COMPLETION_QUOTE_KEY)) {
            return maxOf(0, defaults.getInt(NEXT_COMPLETION_QUOTE_KEY)) % pool.size
        }
        val lastId = defaults.getString(LAST_COMPLETION_QUOTE_KEY)
        if (lastId != null) {
            val last = pool.indexOfFirst { it.id == lastId }
            if (last >= 0) return (last + 1) % pool.size
        }
        return 0
    }

    fun selectCompletionQuote(defaults: QuotePreferences): CompletionQuote {
        val pool = pool()
        return pool[nextCompletionIndex(defaults)]
    }

    fun rememberCompletionQuote(quote: CompletionQuote, defaults: QuotePreferences) {
        val pool = pool()
        val shown = pool.indexOfFirst { it.id == quote.id }.let { if (it >= 0) it else nextCompletionIndex(defaults) }
        defaults.setInt(NEXT_COMPLETION_QUOTE_KEY, (shown + 1) % pool.size)
        defaults.remove(LAST_COMPLETION_QUOTE_KEY)
    }

    fun freshCompletionQuote(defaults: QuotePreferences): CompletionQuote {
        val selected = selectCompletionQuote(defaults)
        rememberCompletionQuote(selected, defaults)
        return selected
    }
}
