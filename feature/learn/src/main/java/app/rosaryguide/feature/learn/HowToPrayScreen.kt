package app.rosaryguide.feature.learn

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.catalog.HowToPrayContent
import app.rosaryguide.core.data.catalog.HowToPrayStep
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.Hairline
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.designsystem.theme.isAccessibilitySize

private val pathOverview = listOf(
    "Opening" to "The Sign of the Cross through the Glory Be, in order.",
    "Each decade" to "The mystery, a verse, its fruit, then the beads.",
    "Closing" to "The traditional closing prayers after the fifth decade.",
)

@Composable
fun HowToPrayScreen(modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    var openStep by remember { mutableStateOf<Int?>(1) }
    val ax = isAccessibilitySize()
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.xl, bottom = RosarySpace.xxl),
    ) {
        GuideSectionLabel(text = "Guide")
        Text(
            text = HowToPrayContent.introduction.english,
            style = RosaryType.body,
            color = palette.dim,
            modifier = Modifier.padding(bottom = RosarySpace.xl),
        )

        GuideSectionLabel(text = "The path")
        HowToCard {
            pathOverview.forEachIndexed { index, (title, body) ->
                Column(Modifier.fillMaxWidth().padding(vertical = RosarySpace.lg)) {
                    Text(title, style = RosaryType.body, color = palette.ink)
                    Spacer(Modifier.height(RosarySpace.xs))
                    Text(body, style = RosaryType.supportingLabel, color = palette.dim)
                }
                if (index < pathOverview.lastIndex) HorizontalDivider(
                    thickness = Hairline.thickness, color = palette.hair)
            }
        }
        Spacer(Modifier.height(RosarySpace.xl))

        GuideSectionLabel(text = "Step by step")
        HowToCard {
            HowToPrayContent.steps.forEachIndexed { index, step ->
                HowToStepRow(step = step, expanded = openStep == step.id, onToggle = {
                    openStep = if (openStep == step.id) null else step.id
                })
                if (index < HowToPrayContent.steps.lastIndex) {
                    HorizontalDivider(
                        modifier = Modifier.padding(start = 52.dp),
                        color = palette.hair,
                        thickness = Hairline.thickness,
                    )
                }
            }
        }
        Spacer(Modifier.height(RosarySpace.xl))

        GuideSectionLabel(text = "When to pray which mysteries")
        HowToCard {
            HowToPrayContent.weekdayGuide.forEachIndexed { index, (day, set) ->
                if (ax) {
                    Column(Modifier.fillMaxWidth().padding(vertical = RosarySpace.md)) {
                        Text(day, style = RosaryType.body, color = palette.ink)
                        Text(set, style = RosaryType.supportingLabel, color = palette.dim)
                    }
                } else {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = RosarySpace.md),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(day, style = RosaryType.body, color = palette.ink, modifier = Modifier.width(96.dp))
                        Text(set, style = RosaryType.caption, color = palette.dim, modifier = Modifier.weight(1f), textAlign = androidx.compose.ui.text.style.TextAlign.End)
                    }
                }
                if (index < HowToPrayContent.weekdayGuide.lastIndex) HorizontalDivider(
                    thickness = Hairline.thickness, color = palette.hair)
            }
        }
        Spacer(Modifier.height(RosarySpace.xl))

        GuideSectionLabel(text = "The beads")
        Text(
            text = HowToPrayContent.beadsNote,
            style = RosaryType.body,
            color = palette.dim,
        )
    }
}

@Composable
private fun HowToCard(content: @Composable () -> Unit) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.surface)
            .border(1.dp, palette.strokeRegular, shape)
            .padding(horizontal = RosarySpace.lg),
    ) { content() }
}

@Composable
private fun HowToStepRow(step: HowToPrayStep, expanded: Boolean, onToggle: () -> Unit) {
    val palette = LocalThemePalette.current
    val reduceMotion = LocalReduceMotion.current
    Column(Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .sizeIn(minHeight = RosarySpace.minHitTarget)
                .clickable(role = Role.Button, onClick = onToggle)
                .semantics {
                    contentDescription = step.title.english
                    stateDescription = if (expanded) "Expanded" else "Collapsed"
                }
                .padding(vertical = 15.dp),
            verticalAlignment = Alignment.Top,
        ) {
            Text(
                text = step.id.toString(),
                style = RosaryType.caption,
                color = palette.dim,
                modifier = Modifier.width(24.dp),
            )
            Text(
                text = step.title.english,
                style = RosaryType.body,
                color = palette.ink,
                modifier = Modifier.weight(1f).padding(end = RosarySpace.sm),
            )
            Icon(
                imageVector = Icons.Filled.KeyboardArrowDown,
                contentDescription = null,
                tint = palette.dim,
                modifier = Modifier.rotate(if (expanded) 180f else 0f),
            )
        }
        AnimatedVisibility(
            visible = expanded,
            enter = if (reduceMotion) fadeIn() else expandVertically() + fadeIn(),
            exit = if (reduceMotion) fadeOut() else shrinkVertically() + fadeOut(),
        ) {
            Text(
                text = step.body,
                style = RosaryType.body,
                color = palette.dim,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 36.dp, end = RosarySpace.sm, bottom = RosarySpace.lg),
            )
        }
    }
}
