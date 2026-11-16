package app.rosaryguide.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import app.rosaryguide.android.ui.DebugLaunch
import app.rosaryguide.android.ui.RosaryGuideApp
import app.rosaryguide.core.data.prefs.SettingsStore
import app.rosaryguide.core.designsystem.theme.RosaryGuideTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    @Inject lateinit var settingsStore: SettingsStore

    override fun onCreate(savedInstanceState: Bundle?) {
        val splash = installSplashScreen()
        super.onCreate(savedInstanceState)
        val debug = DebugLaunch.from(intent)
        // Keep the system splash (Marian blue + app mark) up until the first Compose frame
        // so the handoff onto the same blue Lottie canvas has no white flash.
        var keepSplash = !debug.skipSplash
        splash.setKeepOnScreenCondition { keepSplash }
        enableEdgeToEdge()
        setContent {
            val settings by settingsStore.value.collectAsState()
            val systemDark = isSystemInDarkTheme()
            RosaryGuideTheme(darkTheme = settings.appearance.isDark(systemDark)) {
                RosaryGuideApp(
                    debugLaunch = debug,
                    onFirstFrame = { keepSplash = false },
                )
            }
        }
    }
}
