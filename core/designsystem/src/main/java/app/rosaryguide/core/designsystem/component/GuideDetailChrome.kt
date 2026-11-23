package app.rosaryguide.core.designsystem.component

import androidx.compose.foundation.layout.RowScope
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.Modifier

/**
 * Pushed-page chrome. Implementation is the native Material 3
 * [GuideTopAppBar] (system back affordance), not an iOS chevron imitation.
 */
@Composable
fun GuideDetailTopBar(
    title: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    containerColor: Color? = null,
    actions: @Composable RowScope.() -> Unit = {},
    milkyOnPlain: Boolean = false,
) {
    GuideTopAppBar(
        title = title,
        onBack = onBack,
        modifier = modifier,
        containerColor = containerColor,
        actions = actions,
        milkyOnPlain = milkyOnPlain,
    )
}
