package app.rosaryguide.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import app.rosaryguide.core.designsystem.gallery.ThemeGalleryScreen
import app.rosaryguide.core.designsystem.theme.RosaryGuideTheme

/**
 * Debug / screenshot gallery of design tokens and first-cut components.
 * Launch with `--ez dark true` or `--ez light true` to force appearance.
 */
class ThemeGalleryActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val forceDark = intent.getBooleanExtra("dark", false)
        val forceLight = intent.getBooleanExtra("light", false)
        setContent {
            val dark = when {
                forceDark -> true
                forceLight -> false
                else -> isSystemInDarkTheme()
            }
            RosaryGuideTheme(darkTheme = dark) {
                ThemeGalleryScreen()
            }
        }
    }
}
