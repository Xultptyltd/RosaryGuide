package app.rosaryguide.android.di

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStoreFile
import app.rosaryguide.core.data.prefs.AppPreferences
import app.rosaryguide.core.data.catalog.DataStoreQuotePreferences
import app.rosaryguide.core.data.catalog.QuotePreferences
import app.rosaryguide.android.icons.AppIconController
import app.rosaryguide.android.review.AppReviewPrompter
import app.rosaryguide.core.data.prefs.DataStoreAppPreferences
import app.rosaryguide.core.data.prefs.DataStoreSettingsPreferences
import app.rosaryguide.core.data.prefs.SettingsStore
import app.rosaryguide.core.data.session.DataStoreSessionPreferences
import app.rosaryguide.core.data.session.SessionStore
import app.rosaryguide.notifications.ReminderScheduler
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object PreferencesModule {
    @Provides
    @Singleton
    fun provideSettingsDataStore(@ApplicationContext context: Context): DataStore<Preferences> =
        PreferenceDataStoreFactory.create(
            produceFile = { context.preferencesDataStoreFile("settings") },
        )

    @Provides
    @Singleton
    fun provideAppPreferences(dataStore: DataStore<Preferences>): AppPreferences =
        DataStoreAppPreferences(dataStore)

    @Provides
    @Singleton
    fun provideSessionStore(dataStore: DataStore<Preferences>): SessionStore =
        SessionStore(DataStoreSessionPreferences(dataStore))

    @Provides
    @Singleton
    fun provideQuotePreferences(dataStore: DataStore<Preferences>): QuotePreferences =
        DataStoreQuotePreferences(dataStore)

    @Provides
    @Singleton
    fun provideSettingsStore(dataStore: DataStore<Preferences>): SettingsStore =
        SettingsStore(DataStoreSettingsPreferences(dataStore))

    @Provides
    @Singleton
    fun provideReminderScheduler(@ApplicationContext context: Context): ReminderScheduler =
        ReminderScheduler(context)

    @Provides
    @Singleton
    fun provideAppIconController(@ApplicationContext context: Context): AppIconController =
        AppIconController(context)

    @Provides
    @Singleton
    fun provideAppReviewPrompter(settingsStore: SettingsStore): AppReviewPrompter =
        AppReviewPrompter(settingsStore)
}
