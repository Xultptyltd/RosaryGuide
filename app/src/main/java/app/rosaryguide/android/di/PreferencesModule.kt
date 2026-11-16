package app.rosaryguide.android.di

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStoreFile
import app.rosaryguide.core.data.auth.StubAuthStore
import app.rosaryguide.core.data.prefs.AppPreferences
import app.rosaryguide.core.data.prefs.DataStoreAppPreferences
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
    fun provideAuthStore(): StubAuthStore = StubAuthStore()
}
