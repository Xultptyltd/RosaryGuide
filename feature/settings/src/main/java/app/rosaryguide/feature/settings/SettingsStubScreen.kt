package app.rosaryguide.feature.settings

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import app.rosaryguide.core.designsystem.component.StubScreen

@Composable
fun SettingsStubScreen(modifier: Modifier = Modifier) {
    StubScreen(
        title = "Settings",
        subtitle = "Appearance, reminders, and legal screens will live here (M6).",
        modifier = modifier,
    )
}
