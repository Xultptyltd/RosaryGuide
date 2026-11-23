package app.rosaryguide.core.designsystem.component

import androidx.compose.foundation.layout.RowScope
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.Modifier

/**
 * Pushed-page chrome. Uses [GuideTopAppBar]. The default back glyph is
 * the Material arrow in the milky chip so approved Learn frames stay put.
 * Pass [chevronBack] for the iOS-style chevron used in the Profile/Settings group.
 */
@Composable
fun GuideDetailTopBar(
    title: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    containerColor: Color? = null,
    actions: @Composable RowScope.() -> Unit = {},
    milkyOnPlain: Boolean = false,
    chevronBack: Boolean = false,
) {
    GuideTopAppBar(
        title = title,
        onBack = onBack,
        modifier = modifier,
        containerColor = containerColor,
        actions = actions,
        milkyOnPlain = milkyOnPlain,
        chevronBack = chevronBack,
    )
}
