package app.rosaryguide.feature.today

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import app.rosaryguide.core.designsystem.component.StubScreen

@Composable
fun TodayStubScreen(modifier: Modifier = Modifier) {
    StubScreen(
        title = "Today",
        subtitle = "Today's mystery, the pray CTA, and this week's feasts will live here (M2).",
        modifier = modifier,
    )
}
