package app.rosaryguide.core.data.catalog

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import app.rosaryguide.core.data.SettingsKeys
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

class DataStoreQuotePreferences(
    private val dataStore: DataStore<Preferences>,
) : QuotePreferences {
    override fun contains(key: String): Boolean = runBlocking {
        val prefs = dataStore.data.first()
        when (key) {
            QuoteCatalog.NEXT_COMPLETION_QUOTE_KEY -> prefs.contains(SettingsKeys.NextCompletionQuoteIndex)
            QuoteCatalog.LAST_COMPLETION_QUOTE_KEY -> prefs.contains(SettingsKeys.LastCompletionQuoteId)
            else -> false
        }
    }

    override fun getInt(key: String, default: Int): Int = runBlocking {
        if (key == QuoteCatalog.NEXT_COMPLETION_QUOTE_KEY) {
            dataStore.data.first()[SettingsKeys.NextCompletionQuoteIndex] ?: default
        } else default
    }

    override fun getString(key: String): String? = runBlocking {
        if (key == QuoteCatalog.LAST_COMPLETION_QUOTE_KEY) {
            dataStore.data.first()[SettingsKeys.LastCompletionQuoteId]
        } else null
    }

    override fun setInt(key: String, value: Int) {
        if (key != QuoteCatalog.NEXT_COMPLETION_QUOTE_KEY) return
        runBlocking { dataStore.edit { it[SettingsKeys.NextCompletionQuoteIndex] = value } }
    }

    override fun remove(key: String) {
        runBlocking {
            dataStore.edit { prefs ->
                when (key) {
                    QuoteCatalog.NEXT_COMPLETION_QUOTE_KEY -> prefs.remove(SettingsKeys.NextCompletionQuoteIndex)
                    QuoteCatalog.LAST_COMPLETION_QUOTE_KEY -> prefs.remove(SettingsKeys.LastCompletionQuoteId)
                }
            }
        }
    }
}
