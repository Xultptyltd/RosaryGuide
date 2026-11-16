package app.rosaryguide.feature.pray

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import app.rosaryguide.core.designsystem.component.StubScreen

@Composable
fun PrayStubScreen(modifier: Modifier = Modifier) {
    StubScreen(
        title = "Pray",
        subtitle = "The bead-by-bead rosary is a full-screen destination, not a tab (M3).",
        modifier = modifier,
    )
}
