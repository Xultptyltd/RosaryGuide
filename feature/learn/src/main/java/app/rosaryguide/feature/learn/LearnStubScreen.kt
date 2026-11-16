package app.rosaryguide.feature.learn

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import app.rosaryguide.core.designsystem.component.StubScreen

@Composable
fun LearnStubScreen(modifier: Modifier = Modifier) {
    StubScreen(
        title = "Learn",
        subtitle = "Walkthrough, FAQs, prayers, and mystery pages will live here (M2).",
        modifier = modifier,
    )
}
