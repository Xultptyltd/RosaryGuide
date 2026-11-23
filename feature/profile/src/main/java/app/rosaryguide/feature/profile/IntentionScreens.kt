package app.rosaryguide.feature.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.TextButton
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.Hairline
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.designsystem.component.AppPageBackground

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
    var moreOpen by remember { mutableStateOf(false) }
    Box(modifier = modifier.fillMaxSize()) {
        AppPageBackground()
        Column(modifier = Modifier.fillMaxSize()) {
            GuideDetailTopBar(
                title = "All intentions",
                onBack = onBack,
                containerColor = androidx.compose.ui.graphics.Color.Transparent,
                actions = {
                    Box {
                        val chip = if (palette.isDark) androidx.compose.ui.graphics.Color.White.copy(alpha = 0.16f)
                        else androidx.compose.ui.graphics.Color.White.copy(alpha = 0.92f)
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(CircleShape)
                                .background(chip)
                                .clickable { moreOpen = true },
                            contentAlignment = Alignment.Center,
                        ) {
                            Text("•••", style = RosaryType.captionPray, color = palette.ink)
                        }
                        DropdownMenu(expanded = moreOpen, onDismissRequest = { moreOpen = false }) {
                            DropdownMenuItem(
                                text = { Text(if (hidden) "Show intentions" else "Hide intentions") },
                                onClick = { moreOpen = false; onToggleHide() },
                            )
                            DropdownMenuItem(
                                text = { Text("View archived") },
                                onClick = { moreOpen = false; onOpenArchived() },
                            )
                        }
                    }
                },
            )
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = RosarySpace.gutter)
                    .padding(bottom = RosarySpace.tabBarContentClearance),
            ) {
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
                            HorizontalDivider(
                                thickness = Hairline.thickness,
                                modifier = Modifier.padding(start = 56.dp),
                                color = palette.hair,
                            )
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class, ExperimentalMaterial3Api::class)
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
            .fillMaxWidth()
            .background(palette.bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter)
            .padding(top = RosarySpace.md, bottom = RosarySpace.xl),
    ) {
        GuideDetailTopBar(title = if (existing == null) "Add intention" else "Edit intention", onBack = onBack)
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
                    style = RosaryType.captionPray,
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
                    if (selected) Text("✓", color = androidx.compose.ui.graphics.Color.White, style = RosaryType.captionPray)
                }
            }
        }
        Spacer(Modifier.height(RosarySpace.lg))
        Text(
            text = if (pinned) "Pinned for your next Rosary" else "Pin for your next Rosary",
            style = RosaryType.bodyPray,
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
    val hides = IntentionPrivacy.hides(intention, hidden)
    val chromeTitle = if (intention.isPapal) "Holy Father’s intention" else intention.category.title
    val note = intention.note?.trim().orEmpty()
    val created = if (intention.createdAtEpochMs > 0L) {
        java.time.Instant.ofEpochMilli(intention.createdAtEpochMs)
            .atZone(java.time.ZoneId.of("Australia/Perth"))
            .toLocalDate()
            .format(java.time.format.DateTimeFormatter.ofPattern("d MMM yyyy", java.util.Locale.forLanguageTag("en-AU")))
    } else {
        "—"
    }
    var confirmDelete by remember { mutableStateOf(false) }
    var menu by remember { mutableStateOf(false) }
    val prayedLabel = if (intention.timesCarried == 1) "Rosary prayed" else "Rosaries prayed"
    // Android v1 has timesCarried but no lastCarriedAt timestamp yet.
    val lastPrayed = if (intention.timesCarried == 0) "Not yet prayed" else "—"
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        app.rosaryguide.core.designsystem.component.GuideTopAppBar(
            title = chromeTitle,
            onBack = onBack,
            actions = {
                if (intention.isPapal) {
                    androidx.compose.material3.TextButton(onClick = onPin) {
                        Text(if (intention.isPinned) "Unpin" else "Pin", color = palette.accentText)
                    }
                } else {
                    androidx.compose.material3.TextButton(onClick = onEdit) {
                        Text("Edit", color = palette.accentText)
                    }
                }
                Box {
                    androidx.compose.material3.IconButton(onClick = { menu = true }) {
                        Icon(Icons.Filled.MoreVert, contentDescription = "More", tint = palette.ink)
                    }
                    DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                        if (!intention.isPapal) {
                            DropdownMenuItem(text = { Text(if (intention.isPinned) "Unpin" else "Pin") }, onClick = { menu = false; onPin() })
                        }
                        DropdownMenuItem(text = { Text("Archive") }, onClick = { menu = false; onArchive() })
                        DropdownMenuItem(text = { Text("Delete") }, onClick = { menu = false; confirmDelete = true })
                    }
                }
            },
        )
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(top = 18.dp, bottom = RosarySpace.xl),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            IntentionIcon(intention = intention, size = 52.dp)
            Spacer(Modifier.height(RosarySpace.md))
            Text(
                text = title,
                style = RosaryType.headingSecondaryPray,
                color = if (hides) palette.dim else palette.ink,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            )
            Spacer(Modifier.height(RosarySpace.md))
            val shape = RoundedCornerShape(RosarySpace.containerRadius)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(shape)
                    .background(palette.surface)
                    .heightIn(min = 80.dp)
                    .padding(vertical = RosarySpace.md),
            ) {
                Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("${intention.timesCarried}", style = RosaryType.bodyPray, color = palette.ink)
                    Text(prayedLabel, style = RosaryType.captionPray, color = palette.dim)
                }
                Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(lastPrayed, style = RosaryType.bodyPray, color = palette.ink)
                    Text("Last prayed", style = RosaryType.captionPray, color = palette.dim)
                }
            }
            if (!intention.isPapal || note.isNotBlank()) {
                Spacer(Modifier.height(RosarySpace.md))
                if (note.isNotBlank()) {
                    Text(
                        text = if (hides) IntentionPrivacy.MASKED_TEXT else note,
                        style = RosaryType.supportingLabelPray,
                        color = if (hides) palette.dim else palette.ink,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(shape)
                            .background(palette.surface)
                            .padding(20.dp),
                    )
                } else {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(shape)
                            .background(palette.surface)
                            .clickable(onClick = onEdit)
                            .padding(20.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text("Add Notes", style = RosaryType.supportingLabelPray, color = palette.dim, modifier = Modifier.weight(1f))
                    }
                }
            }
            Spacer(Modifier.height(RosarySpace.lg))
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(shape)
                    .background(palette.surface)
                    .padding(horizontal = 18.dp),
            ) {
                DetailFactRow("Category", intention.category.title)
                HorizontalDivider(
                    thickness = Hairline.thickness, color = palette.hair)
                DetailFactRow("Last prayed", lastPrayed)
                HorizontalDivider(
                    thickness = Hairline.thickness, color = palette.hair)
                DetailFactRow("Created", created)
            }
            Spacer(Modifier.height(RosarySpace.xl))
            GuideSecondaryButton(title = "Offer a Rosary", onClick = onPray)
        }
    }
    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("Delete intention?") },
            text = { Text("This will delete “$title” from your intentions.") },
            confirmButton = {
                TextButton(onClick = { confirmDelete = false; onDelete() }) { Text("Delete") }
            },
            dismissButton = {
                TextButton(onClick = { confirmDelete = false }) { Text("Cancel") }
            },
        )
    }
}

@Composable
private fun DetailFactRow(label: String, value: String) {
    val palette = LocalThemePalette.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = RosarySpace.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, style = RosaryType.captionPray, color = palette.dim, modifier = Modifier.width(120.dp))
        Text(value, style = RosaryType.bodyPray, color = palette.ink, modifier = Modifier.weight(1f))
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
    var pendingDelete by remember { mutableStateOf<OfferIntention?>(null) }
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        GuideDetailTopBar(title = "Archived intentions", onBack = onBack)
        if (intentions.isEmpty()) {
            Column(
                modifier = Modifier.fillMaxSize().padding(horizontal = RosarySpace.gutter),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text("No archived intentions", style = RosaryType.bodyPray, color = palette.ink)
                Spacer(Modifier.height(RosarySpace.sm))
                Text("Intentions you archive will rest here", style = RosaryType.captionPray, color = palette.textSecondary)
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = RosarySpace.gutter)
                    .padding(top = RosarySpace.md, bottom = RosarySpace.xl),
            ) {
                intentions.forEachIndexed { index, item ->
                    val title = IntentionPrivacy.displayTitle(item, hidden)
                    var menu by remember { mutableStateOf(false) }
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = RosarySpace.md),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        IntentionIcon(intention = item, size = 40.dp)
                        Spacer(Modifier.width(RosarySpace.md))
                        Text(title, style = RosaryType.bodyPray, color = palette.ink, modifier = Modifier.weight(1f))
                        Box {
                            androidx.compose.material3.IconButton(onClick = { menu = true }) {
                                Icon(Icons.Filled.MoreVert, contentDescription = "More options", tint = palette.textSecondary)
                            }
                            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                                DropdownMenuItem(text = { Text("Unarchive") }, onClick = { menu = false; onRestore(item) })
                                DropdownMenuItem(text = { Text("Delete") }, onClick = { menu = false; pendingDelete = item })
                            }
                        }
                    }
                    if (index < intentions.lastIndex) {
                        HorizontalDivider(
                    thickness = Hairline.thickness, color = palette.hair, modifier = Modifier.padding(start = 62.dp))
                    }
                }
            }
        }
    }
    pendingDelete?.let { item ->
        val title = IntentionPrivacy.displayTitle(item, hidden)
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            title = { Text("Delete intention?") },
            text = { Text("This will delete “$title” from your intentions.") },
            confirmButton = {
                TextButton(onClick = { onDelete(item); pendingDelete = null }) { Text("Delete") }
            },
            dismissButton = {
                TextButton(onClick = { pendingDelete = null }) { Text("Cancel") }
            },
        )
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
            style = RosaryType.bodyPray,
            color = palette.accent,
            modifier = Modifier.clickable(onClick = onBack).padding(end = RosarySpace.md, top = RosarySpace.xs, bottom = RosarySpace.xs),
        )
        Text(text = title, style = RosaryType.navigationTitlePray, color = palette.ink)
    }
}
