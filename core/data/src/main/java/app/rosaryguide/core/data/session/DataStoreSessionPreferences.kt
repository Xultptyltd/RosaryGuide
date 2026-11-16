package app.rosaryguide.core.data.session

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import app.rosaryguide.core.data.SettingsKeys
import app.rosaryguide.core.data.config.RosaryJson
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.builtins.ListSerializer

class DataStoreSessionPreferences(
    private val dataStore: DataStore<Preferences>,
) : SessionPreferences {
    override fun loadSession(): PrayerSession? = runBlocking {
        dataStore.data.first()[SettingsKeys.SessionPrayer]?.let { decodePrayerSession(it) }
    }

    override fun saveSession(session: PrayerSession?) {
        runBlocking {
            dataStore.edit { prefs ->
                if (session == null) prefs.remove(SettingsKeys.SessionPrayer)
                else prefs[SettingsKeys.SessionPrayer] = session.toJson()
            }
        }
    }

    override fun loadCompletedSessions(): List<CompletedPrayerSession> = runBlocking {
        val raw = dataStore.data.first()[SettingsKeys.SessionCompleted] ?: return@runBlocking emptyList()
        runCatching { decodeCompletedSessions(raw) }.getOrDefault(emptyList())
    }

    override fun saveCompletedSessions(sessions: List<CompletedPrayerSession>) {
        runBlocking {
            dataStore.edit { prefs ->
                prefs[SettingsKeys.SessionCompleted] = RosaryJson.encodeToString(
                    ListSerializer(CompletedPrayerSession.serializer()),
                    sessions,
                )
            }
        }
    }

    override fun loadCompletedDayKeys(): Set<String> = runBlocking {
        dataStore.data.first()[SettingsKeys.SessionCompletedDayKeys] ?: emptySet()
    }

    override fun saveCompletedDayKeys(keys: Set<String>) {
        runBlocking {
            dataStore.edit { prefs -> prefs[SettingsKeys.SessionCompletedDayKeys] = keys }
        }
    }

    override fun loadIntentions(): List<OfferIntention> = runBlocking {
        val raw = dataStore.data.first()[SettingsKeys.SessionIntentions] ?: return@runBlocking emptyList()
        runCatching {
            RosaryJson.decodeFromString(ListSerializer(OfferIntention.serializer()), raw)
        }.getOrDefault(emptyList())
    }

    override fun saveIntentions(intentions: List<OfferIntention>) {
        runBlocking {
            dataStore.edit { prefs ->
                prefs[SettingsKeys.SessionIntentions] = RosaryJson.encodeToString(
                    ListSerializer(OfferIntention.serializer()),
                    intentions,
                )
            }
        }
    }
}
