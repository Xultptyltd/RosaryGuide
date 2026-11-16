package app.rosaryguide.feature.feasts

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import app.rosaryguide.core.designsystem.component.StubScreen

@Composable
fun FeastsStubScreen(modifier: Modifier = Modifier) {
    StubScreen(
        title = "Feasts",
        subtitle = "The liturgical calendar, search, and feast detail will live here (M2).",
        modifier = modifier,
    )
}
