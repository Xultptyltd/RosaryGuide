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
import app.rosaryguide.core.designsystem.component.GuideDialogButton
import app.rosaryguide.core.designsystem.component.SectionBand
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
import androidx.compose.foundation.text.BasicTextField
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
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.R
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
                milkyOnPlain = false,
                chevronBack = true,
                actions = {
                    Box {
                        // Match the back chip: 40 dp circle in a 48 dp hit target,
                        // with a bold horizontal ellipsis (not caption "•••").
                        Box(
                            modifier = Modifier.size(RosarySpace.minHitTarget),
                            contentAlignment = Alignment.Center,
                        ) {
                            val moreFill = if (palette.isDark) {
                                androidx.compose.ui.graphics.Color(0xFF3A3A3C)
                            } else {
                                androidx.compose.ui.graphics.Color.White
                            }
                            Box(
                                modifier = Modifier
                                    .size(RosarySpace.controlSize)
                                    .clip(CircleShape)
                                    .background(moreFill)
                                    .clickable { moreOpen = true },
                                contentAlignment = Alignment.Center,
                            ) {
                                Icon(
                                    painter = painterResource(R.drawable.ic_ellipsis_horizontal),
                                    contentDescription = "More",
                                    tint = palette.ink,
                                    modifier = Modifier.size(22.dp),
                                )
                            }
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
                    // iOS first icon top is 144 pt; without this the Android list sat at 128.
                    .padding(top = 16.dp, bottom = RosarySpace.tabBarContentClearance),
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
    var emoji by remember { mutableStateOf(existing?.displayEmoji ?: "❤️") }
    var pinned by remember { mutableStateOf(existing?.isPinned ?: true) }
    val canSave = title.trim().isNotEmpty()
    val draft = (existing ?: OfferIntention(id = "", title = title, createdAtEpochMs = 0L)).copy(
        title = title,
        note = note.takeIf { it.isNotBlank() },
        category = category,
        accent = accent,
        emoji = emoji,
        isPinned = pinned,
    )
    fun persist() {
        if (!canSave) return
        onSave(draft)
    }
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                modifier = Modifier
                    .padding(top = 8.dp, bottom = 6.dp)
                    .size(width = 36.dp, height = 5.dp)
                    .clip(RoundedCornerShape(50))
                    .background(palette.dim.copy(alpha = 0.35f)),
            )
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 52.dp)
                    .padding(horizontal = RosarySpace.gutter),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                EditorChromeChip(text = "Cancel", enabled = true, onClick = onBack)
                Text(
                    text = if (existing == null) "Add intention" else "Edit intention",
                    style = RosaryType.navigationTitlePray,
                    color = palette.ink,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                    modifier = Modifier.weight(1f),
                    maxLines = 1,
                )
                EditorChromeChip(
                    text = "Save",
                    enabled = canSave,
                    onClick = { persist() },
                    dimmed = !canSave,
                )
            }
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(top = RosarySpace.xl, bottom = RosarySpace.xxl),
            verticalArrangement = Arrangement.spacedBy(RosarySpace.xl),
        ) {
            Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                IntentionIcon(intention = draft, size = 96.dp)
            }
            EditorFieldCard(
                label = "Intention",
                value = title,
                onValueChange = { title = it },
                placeholder = "For my family",
                minHeight = 100.dp,
                textStyle = RosaryType.bodyPray,
            )
            Column(verticalArrangement = Arrangement.spacedBy(RosarySpace.sm)) {
                GuideSectionLabel(text = "Category", style = RosaryType.captionPray)
                ProfileCapsuleControl(
                    options = IntentionCategory.entries.map { it.title },
                    selectedIndex = IntentionCategory.entries.indexOf(category).coerceAtLeast(0),
                    onSelect = { index ->
                        val item = IntentionCategory.entries[index]
                        category = item
                        accent = item.defaultAccent
                        emoji = when (item) {
                            IntentionCategory.Personal -> "❤️"
                            IntentionCategory.Someone -> "👥"
                            IntentionCategory.World -> "🌍"
                        }
                    },
                )
            }
            EditorFieldCard(
                label = "Notes",
                value = note,
                onValueChange = { note = it },
                placeholder = "Optional",
                minHeight = 92.dp,
                textStyle = RosaryType.themeSummary,
            )
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(RosarySpace.containerRadius))
                    .background(palette.surface)
                    .border(
                        Hairline.thickness,
                        palette.cardSurfaceStroke,
                        RoundedCornerShape(RosarySpace.containerRadius),
                    )
                    .padding(horizontal = RosarySpace.lg, vertical = RosarySpace.md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "Set as primary intention",
                    style = RosaryType.bodyPray.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Medium),
                    color = palette.ink,
                    modifier = Modifier.weight(1f),
                )
                androidx.compose.material3.Switch(
                    checked = pinned,
                    onCheckedChange = { pinned = it },
                    colors = androidx.compose.material3.SwitchDefaults.colors(
                        checkedTrackColor = palette.success,
                        checkedThumbColor = androidx.compose.ui.graphics.Color.White,
                    ),
                )
            }
            if (existing != null) {
                Text(
                    text = "Delete intention",
                    style = RosaryType.bodyPray,
                    color = palette.destructive,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(RosarySpace.containerRadius))
                        .background(palette.surface)
                        .clickable { /* delete is confirmed from the detail screen */ }
                        .padding(horizontal = RosarySpace.lg, vertical = RosarySpace.lg),
                )
            }
        }
        GuidePrimaryButton(
            title = "Done",
            enabled = canSave,
            onClick = { persist() },
            modifier = Modifier
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.lg)
                .navigationBarsPadding(),
        )
    }
}


@Composable
private fun EditorChromeChip(
    text: String,
    enabled: Boolean,
    onClick: () -> Unit,
    dimmed: Boolean = false,
) {
    val palette = LocalThemePalette.current
    val fill = if (palette.isDark) androidx.compose.ui.graphics.Color.White.copy(alpha = 0.16f) else androidx.compose.ui.graphics.Color(0xFFF4F4F5)
    Text(
        text = text,
        style = RosaryType.bodyPray,
        color = when {
            dimmed -> palette.dim
            else -> palette.ink
        },
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(fill)
            .then(
                if (!palette.isDark) {
                    Modifier.border(
                        Hairline.thickness,
                        palette.cardSurfaceStroke,
                        RoundedCornerShape(50),
                    )
                } else Modifier
            )
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 8.dp),
    )
}

@Composable
private fun EditorFieldCard(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    minHeight: androidx.compose.ui.unit.Dp,
    textStyle: androidx.compose.ui.text.TextStyle,
) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(verticalArrangement = Arrangement.spacedBy(RosarySpace.sm)) {
        GuideSectionLabel(text = label, style = RosaryType.captionPray)
        androidx.compose.foundation.text.BasicTextField(
            value = value,
            onValueChange = onValueChange,
            textStyle = textStyle.copy(color = palette.ink),
            cursorBrush = androidx.compose.ui.graphics.SolidColor(palette.accent),
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = minHeight)
                .border(Hairline.thickness, palette.cardSurfaceStroke, shape)
                .clip(shape)
                .background(palette.surface, shape)
                .padding(RosarySpace.lg),
            decorationBox = { inner ->
                Box {
                    if (value.isEmpty()) {
                        Text(placeholder, style = textStyle, color = palette.dim)
                    }
                    inner()
                }
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
    startConfirmDelete: Boolean = false,
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
    var confirmDelete by remember { mutableStateOf(startConfirmDelete) }
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
            milkyOnPlain = true,
            chevronBack = true,
            actions = {
                if (intention.isPapal) {
                    androidx.compose.material3.TextButton(onClick = onPin) {
                        Text(if (intention.isPinned) "Unpin" else "Pin", color = palette.accentText)
                    }
                } else {
                    EditorChromeChip(text = "Edit", enabled = true, onClick = onEdit)
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
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("${intention.timesCarried}", style = RosaryType.bodyPray, color = palette.ink)
                    Text(prayedLabel, style = RosaryType.captionPray, color = palette.dim)
                }
                Box(
                    Modifier
                        .width(Hairline.thickness)
                        .height(40.dp)
                        .background(palette.hair),
                )
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
                        Text("+", style = RosaryType.headingSecondaryPray, color = palette.accent)
                    }
                }
            }
            if (!intention.isPapal || note.isNotBlank()) {
                SectionBand(verticalSpacing = 0.dp)
                Spacer(Modifier.height(RosarySpace.lg))
            } else {
                Spacer(Modifier.height(RosarySpace.lg))
            }
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
                GuideDialogButton(
                    text = "Delete",
                    onClick = { confirmDelete = false; onDelete() },
                    destructive = true,
                )
            },
            dismissButton = {
                GuideDialogButton(text = "Cancel", onClick = { confirmDelete = false })
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
        Text(label, style = RosaryType.bodyPray, color = palette.ink)
        Spacer(Modifier.weight(1f))
        Text(value, style = RosaryType.bodyPray, color = palette.dim, textAlign = androidx.compose.ui.text.style.TextAlign.End)
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
        GuideDetailTopBar(title = "Archived intentions", onBack = onBack, milkyOnPlain = true, chevronBack = true)
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
                    .padding(top = 16.dp, bottom = RosarySpace.xl),
            ) {
                intentions.forEachIndexed { index, item ->
                    val title = IntentionPrivacy.displayTitle(item, hidden)
                    var menu by remember { mutableStateOf(false) }
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        IntentionIcon(intention = item, size = 40.dp)
                        Spacer(Modifier.width(RosarySpace.lg))
                        Text(title, style = RosaryType.bodyPray, color = palette.ink, modifier = Modifier.weight(1f))
                        Box {
                            Box(
                                modifier = Modifier
                                    .size(44.dp)
                                    .clickable { menu = true },
                                contentAlignment = Alignment.Center,
                            ) {
                                Icon(
                                    painter = painterResource(R.drawable.ic_ellipsis_horizontal),
                                    contentDescription = "More options",
                                    tint = palette.textSecondary,
                                    modifier = Modifier.size(20.dp),
                                )
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
                GuideDialogButton(
                    text = "Delete",
                    onClick = { onDelete(item); pendingDelete = null },
                    destructive = true,
                )
            },
            dismissButton = {
                GuideDialogButton(text = "Cancel", onClick = { pendingDelete = null })
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
