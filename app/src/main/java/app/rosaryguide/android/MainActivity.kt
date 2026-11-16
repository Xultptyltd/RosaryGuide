package app.rosaryguide.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import app.rosaryguide.android.ui.RosaryGuideApp
import app.rosaryguide.core.designsystem.theme.RosaryGuideTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            RosaryGuideTheme {
                RosaryGuideApp()
            }
        }
    }
}
