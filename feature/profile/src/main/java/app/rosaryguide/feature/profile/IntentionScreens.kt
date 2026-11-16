package app.rosaryguide.feature.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.session.IntentionAccent
import app.rosaryguide.core.data.session.IntentionCategory
import app.rosaryguide.core.data.session.IntentionPrivacy
import app.rosaryguide.core.data.session.OfferIntention
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

@Composable
fun AllIntentionsScreen(
    intentions: List<OfferIntention>,
    archivedCount: Int,
    hidden: Boolean,
    onBack: () -> Unit,
    onAdd: () -> Unit,
    onOpenArchived: () -> Unit,
    onOpenDetail: (OfferIntention) -> Unit,
    onEdit: (OfferIntention) -> Unit,
    onPin: (OfferIntention) -> Unit,
    onDelete: (OfferIntention) -> Unit,
    onPray: (OfferIntention) -> Unit,
    onToggleHide: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.md, bottom = RosarySpace.xl),
    ) {
        ProfileBackRow(title = "Intentions", onBack = onBack)
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Spacer(Modifier.weight(1f))
            if (intentions.isNotEmpty()) {
                Text(
                    text = if (hidden) "Show titles" else "Hide titles",
                    style = RosaryType.caption,
                    color = palette.accent,
                    modifier = Modifier.clickable(onClick = onToggleHide),
                )
            }
        }
        Column(modifier = Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            if (intentions.isEmpty()) {
                IntentionsEmptyCard(onAdd = onAdd)
            } else {
                intentions.forEachIndexed { index, item ->
                    IntentionRow(
                        intention = item,
                        hidden = hidden,
                        onOpen = { onOpenDetail(item) },
                        onPray = { onPray(item) },
                        onPin = { onPin(item) },
                        onEdit = { onEdit(item) },
                        onDelete = { onDelete(item) },
                    )
                    if (index != intentions.lastIndex) {
                        HorizontalDivider(modifier = Modifier.padding(start = 52.dp), color = palette.strokeSubtle)
                    }
                }
            }
            if (archivedCount > 0) {
                Spacer(Modifier.height(RosarySpace.lg))
                Text(
                    text = "Archived ($archivedCount)",
                    style = RosaryType.body,
                    color = palette.accent,
                    modifier = Modifier.clickable(onClick = onOpenArchived),
                )
            }
            Spacer(Modifier.height(RosarySpace.lg))
            GuidePrimaryButton(title = "Add intention", onClick = onAdd)
        }
    }
}

@Composable
fun IntentionEditorScreen(
    existing: OfferIntention?,
    onBack: () -> Unit,
    onSave: (OfferIntention) -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    var title by remember { mutableStateOf(existing?.title.orEmpty()) }
    var note by remember { mutableStateOf(existing?.note.orEmpty()) }
    var category by remember { mutableStateOf(existing?.category ?: IntentionCategory.Personal) }
    var accent by remember { mutableStateOf(existing?.accent ?: IntentionCategory.Personal.defaultAccent) }
    var emoji by remember { mutableStateOf(existing?.displayEmoji ?: "🙏") }
    var pinned by remember { mutableStateOf(existing?.isPinned ?: false) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.md, bottom = RosarySpace.xl),
    ) {
        ProfileBackRow(title = if (existing == null) "Add intention" else "Edit intention", onBack = onBack)
        Spacer(Modifier.height(RosarySpace.md))
        GuideSectionLabel(text = "Intention")
        OutlinedTextField(
            value = title,
            onValueChange = { title = it },
            placeholder = { Text("What’s on your heart?") },
            modifier = Modifier.fillMaxWidth(),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = palette.accent,
                unfocusedBorderColor = palette.strokeRegular,
                focusedTextColor = palette.ink,
                unfocusedTextColor = palette.ink,
            ),
        )
        Spacer(Modifier.height(RosarySpace.md))
        GuideSectionLabel(text = "Note")
        OutlinedTextField(
            value = note,
            onValueChange = { note = it },
            placeholder = { Text("A few words to remember") },
            modifier = Modifier.fillMaxWidth(),
            minLines = 3,
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = palette.accent,
                unfocusedBorderColor = palette.strokeRegular,
                focusedTextColor = palette.ink,
                unfocusedTextColor = palette.ink,
            ),
        )
        Spacer(Modifier.height(RosarySpace.lg))
        GuideSectionLabel(text = "For")
        Row(horizontalArrangement = Arrangement.spacedBy(RosarySpace.sm), modifier = Modifier.fillMaxWidth()) {
            IntentionCategory.entries.forEach { item ->
                val selected = category == item
                Text(
                    text = item.title,
                    style = RosaryType.caption,
                    color = if (selected) palette.onAccent else palette.ink,
                    modifier = Modifier
                        .clip(RoundedCornerShape(RosarySpace.containerRadius))
                        .background(if (selected) palette.accent else palette.surface)
                        .clickable {
                            category = item
                            if (existing == null) accent = item.defaultAccent
                        }
                        .padding(horizontal = RosarySpace.md, vertical = RosarySpace.sm),
                )
            }
        }
        Spacer(Modifier.height(RosarySpace.lg))
        GuideSectionLabel(text = "Colour")
        Row(horizontalArrangement = Arrangement.spacedBy(RosarySpace.md)) {
            IntentionAccent.entries.forEach { item ->
                val selected = accent == item
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(item.fill())
                        .then(if (selected) Modifier.border(2.dp, palette.ink, CircleShape) else Modifier)
                        .clickable { accent = item },
                    contentAlignment = Alignment.Center,
                ) {
                    if (selected) Text("✓", color = androidx.compose.ui.graphics.Color.White, style = RosaryType.caption)
                }
            }
        }
        Spacer(Modifier.height(RosarySpace.lg))
        GuideSectionLabel(text = "Icon")
        Row(horizontalArrangement = Arrangement.spacedBy(RosarySpace.sm), modifier = Modifier.fillMaxWidth()) {
            INTENTION_EMOJIS.forEach { item ->
                val selected = emoji == item
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(if (selected) palette.accentTint else palette.surface)
                        .clickable { emoji = item },
                    contentAlignment = Alignment.Center,
                ) {
                    Text(item, style = RosaryType.body)
                }
            }
        }
        Spacer(Modifier.height(RosarySpace.lg))
        Text(
            text = if (pinned) "Pinned for your next Rosary" else "Pin for your next Rosary",
            style = RosaryType.body,
            color = palette.accent,
            modifier = Modifier.clickable { pinned = !pinned },
        )
        Spacer(Modifier.height(RosarySpace.xl))
        GuidePrimaryButton(
            title = if (existing == null) "Save intention" else "Save changes",
            onClick = {
                val base = existing ?: OfferIntention(id = "", title = title, createdAtEpochMs = 0L)
                onSave(
                    base.copy(
                        title = title,
                        note = note.takeIf { it.isNotBlank() },
                        category = category,
                        accent = accent,
                        emoji = emoji,
                        isPinned = pinned,
                    ),
                )
            },
        )
    }
}

@Composable
fun IntentionDetailScreen(
    intention: OfferIntention,
    hidden: Boolean,
    onBack: () -> Unit,
    onEdit: () -> Unit,
    onPray: () -> Unit,
    onPin: () -> Unit,
    onArchive: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val title = IntentionPrivacy.displayTitle(intention, hidden)
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.md, bottom = RosarySpace.xl),
    ) {
        ProfileBackRow(title = "Intention", onBack = onBack)
        Spacer(Modifier.height(RosarySpace.lg))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(intention.accent.fill()),
                contentAlignment = Alignment.Center,
            ) {
                Text(intention.displayEmoji, style = RosaryType.headingSecondary)
            }
            Spacer(Modifier.width(RosarySpace.md))
            Column {
                Text(title, style = RosaryType.headingSecondary, color = palette.ink)
                Text(intention.category.title, style = RosaryType.caption, color = palette.textSecondary)
            }
        }
        intention.note?.takeIf { !hidden }?.let {
            Spacer(Modifier.height(RosarySpace.lg))
            Text(it, style = RosaryType.supportingLabel, color = palette.textSecondary)
        }
        Spacer(Modifier.height(RosarySpace.xl))
        GuidePrimaryButton(title = "Offer a Rosary", onClick = onPray)
        Spacer(Modifier.height(RosarySpace.sm))
        GuideSecondaryButton(title = "Edit", onClick = onEdit)
        Spacer(Modifier.height(RosarySpace.lg))
        Text(
            text = if (intention.isPinned) "Unpin" else "Pin",
            style = RosaryType.body,
            color = palette.accent,
            modifier = Modifier.clickable(onClick = onPin).padding(vertical = RosarySpace.sm),
        )
        Text(
            text = "Archive",
            style = RosaryType.body,
            color = palette.accent,
            modifier = Modifier.clickable(onClick = onArchive).padding(vertical = RosarySpace.sm),
        )
        Text(
            text = "Delete",
            style = RosaryType.body,
            color = palette.textSecondary,
            modifier = Modifier.clickable(onClick = onDelete).padding(vertical = RosarySpace.sm),
        )
    }
}

@Composable
fun ArchivedIntentionsScreen(
    intentions: List<OfferIntention>,
    hidden: Boolean,
    onBack: () -> Unit,
    onRestore: (OfferIntention) -> Unit,
    onDelete: (OfferIntention) -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.md, bottom = RosarySpace.xl),
    ) {
        ProfileBackRow(title = "Archived", onBack = onBack)
        if (intentions.isEmpty()) {
            Spacer(Modifier.height(RosarySpace.lg))
            Text("No archived intentions.", style = RosaryType.supportingLabel, color = palette.textSecondary)
        } else {
            intentions.forEach { item ->
                val title = IntentionPrivacy.displayTitle(item, hidden)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = RosarySpace.sm),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(item.displayEmoji, style = RosaryType.body)
                    Spacer(Modifier.width(RosarySpace.md))
                    Text(title, style = RosaryType.body, color = palette.ink, modifier = Modifier.weight(1f))
                    Text("Restore", style = RosaryType.caption, color = palette.accent, modifier = Modifier.clickable { onRestore(item) }.padding(RosarySpace.sm))
                    Text("Delete", style = RosaryType.caption, color = palette.textSecondary, modifier = Modifier.clickable { onDelete(item) }.padding(RosarySpace.sm))
                }
            }
        }
    }
}

@Composable
fun ProfileBackRow(title: String, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(bottom = RosarySpace.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = "Back",
            style = RosaryType.body,
            color = palette.accent,
            modifier = Modifier.clickable(onClick = onBack).padding(end = RosarySpace.md, top = RosarySpace.xs, bottom = RosarySpace.xs),
        )
        Text(text = title, style = RosaryType.navigationTitle, color = palette.ink)
    }
}
