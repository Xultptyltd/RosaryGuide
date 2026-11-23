package app.rosaryguide.android

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import app.rosaryguide.android.ui.DebugLaunch
import app.rosaryguide.android.ui.RosaryGuideApp
import app.rosaryguide.android.icons.AppIconController
import app.rosaryguide.core.data.prefs.SettingsStore
import app.rosaryguide.core.data.sync.AccountSync
import app.rosaryguide.sync.CurrentActivity
import app.rosaryguide.core.designsystem.theme.ColorSchemeContrast
import app.rosaryguide.core.designsystem.theme.RosaryGuideTheme
import app.rosaryguide.core.designsystem.theme.isIncreasedContrast
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    @Inject lateinit var settingsStore: SettingsStore
    @Inject lateinit var accountSync: AccountSync
    @Inject lateinit var appIconController: AppIconController

    private var debugLaunch by mutableStateOf(DebugLaunch())

    override fun onCreate(savedInstanceState: Bundle?) {
        val splash = installSplashScreen()
        super.onCreate(savedInstanceState)
        debugLaunch = DebugLaunch.from(intent)
        // Keep the system splash (Marian blue + app mark) up until the first Compose frame
        // so the handoff onto the same blue Lottie canvas has no white flash.
        var keepSplash = !debugLaunch.skipSplash
        splash.setKeepOnScreenCondition { keepSplash }
        enableEdgeToEdge()
        setContent {
            val settings by settingsStore.value.collectAsState()
            val systemDark = isSystemInDarkTheme()
            val contrast = if (isIncreasedContrast(this@MainActivity)) {
                ColorSchemeContrast.Increased
            } else {
                ColorSchemeContrast.Standard
            }
            RosaryGuideTheme(
                darkTheme = settings.appearance.isDark(systemDark),
                contrast = contrast,
            ) {
                RosaryGuideApp(
                    debugLaunch = debugLaunch,
                    onFirstFrame = { keepSplash = false },
                )
            }
        }
    }

    override fun onStart() {
        super.onStart()
        CurrentActivity.set(this)
        accountSync.onForeground()
    }

    override fun onStop() {
        // Hand waiting preference/progress changes to Firestore's offline queue.
        accountSync.onBackground()
        appIconController.applyPending()
        CurrentActivity.clear(this)
        super.onStop()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        debugLaunch = DebugLaunch.from(intent)
    }
}
