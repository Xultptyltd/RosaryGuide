package app.rosaryguide.feature.pray

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.session.OfferIntention
import app.rosaryguide.core.data.session.OfferedIntentions
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon

@Composable
fun PrayIntentionSheet(
    intentions: List<OfferIntention>,
    selectedIds: List<String>,
    onToggle: (OfferIntention) -> Unit,
    onClear: () -> Unit,
    onAdd: (String) -> Unit,
    onContinue: () -> Unit = {},
    modifier: Modifier = Modifier,
    showComposer: Boolean = false,
    showFooter: Boolean = false,
) {
    val palette = LocalThemePalette.current
    var draft by remember { mutableStateOf("") }
    val selectedTitles = intentions.filter { it.id in selectedIds }.map { it.title }
    Column(
        modifier = modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter),
    ) {
        Text(text = "Offer this Rosary for", style = RosaryType.headingSecondary, color = palette.ink)
        Spacer(Modifier.height(RosarySpace.sm))
        OfferedIntentions.summary(selectedTitles)?.let {
            Text(text = it, style = RosaryType.body, color = palette.dim)
            Spacer(Modifier.height(RosarySpace.sm))
        }
        IntentionRow(
            title = "No specific intention",
            selected = selectedIds.isEmpty(),
            onClick = onClear,
        )
        intentions.forEach { intention ->
            IntentionRow(
                title = intention.title,
                selected = intention.id in selectedIds,
                onClick = { onToggle(intention) },
            )
        }
        if (showComposer) {
        Spacer(Modifier.height(RosarySpace.md))
        Text(text = "Add an intention", style = RosaryType.supportingLabel, color = palette.dim)
        Spacer(Modifier.height(RosarySpace.xs))
        BasicTextField(
            value = draft,
            onValueChange = { draft = it },
            textStyle = RosaryType.body.copy(color = palette.ink),
            modifier = Modifier
                .fillMaxWidth()
                .background(palette.surface, RoundedCornerShape(RosarySpace.containerRadius))
                .padding(horizontal = RosarySpace.md, vertical = RosarySpace.sm),
            decorationBox = { inner ->
                if (draft.isEmpty()) {
                    Text("A person, a cause, a hope…", style = RosaryType.body, color = palette.dim)
                }
                inner()
            },
        )
        if (draft.isNotBlank()) {
            Spacer(Modifier.height(RosarySpace.sm))
            GuideSecondaryButton(title = "Add") {
                onAdd(draft.trim())
                draft = ""
            }
        }
        }
        if (showFooter) {
        Spacer(Modifier.height(RosarySpace.lg))
        GuidePrimaryButton(title = "Next", onClick = onContinue)
        Spacer(Modifier.height(RosarySpace.lg))
        }
    }
}

@Composable
private fun IntentionRow(
    title: String,
    selected: Boolean,
    onClick: () -> Unit,
) {
    val palette = LocalThemePalette.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = RosarySpace.xs)
            .background(palette.surface, RoundedCornerShape(RosarySpace.containerRadius))
            .then(
                if (selected) Modifier.border(1.5.dp, palette.accent, RoundedCornerShape(RosarySpace.containerRadius))
                else Modifier
            )
            .clickable(onClick = onClick)
            .padding(horizontal = RosarySpace.md, vertical = RosarySpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (selected) {
            Icon(
                imageVector = Icons.Filled.Check,
                contentDescription = "Selected",
                tint = palette.accent,
                modifier = Modifier.padding(end = RosarySpace.sm).size(18.dp),
            )
        }
        Text(text = title, style = RosaryType.body, color = palette.ink, modifier = Modifier.weight(1f))
    }
}
