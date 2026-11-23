package app.rosaryguide.feature.profile

import androidx.compose.foundation.background
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import app.rosaryguide.core.designsystem.R
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.layout.ContentScale
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.session.IntentionPrivacy
import app.rosaryguide.core.data.session.OfferIntention
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun IntentionRow(
    intention: OfferIntention,
    hidden: Boolean,
    onOpen: () -> Unit,
    onPray: () -> Unit,
    onPin: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    var menu by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    val title = IntentionPrivacy.displayTitle(intention, hidden)
    val hiddenTitle = IntentionPrivacy.hides(intention, hidden)
    val month = intention.papalMonthLabel()
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onOpen)
            .padding(vertical = RosarySpace.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IntentionIcon(intention = intention, size = 40.dp)
        Spacer(Modifier.width(RosarySpace.md))
        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    title,
                    style = RosaryType.bodyPray,
                    color = if (hiddenTitle) palette.dim else palette.ink,
                    maxLines = 2,
                    modifier = Modifier.weight(1f, fill = false),
                )
                if (intention.isPinned) {
                    Spacer(Modifier.width(RosarySpace.sm))
                    Text(
                        "Pinned",
                        style = RosaryType.captionPray,
                        color = palette.accentText,
                    )
                }
            }
            if (month != null) {
                Text(month, style = RosaryType.captionPray, color = palette.dim, maxLines = 1)
            }
        }
        Box {
            IconButton(onClick = { menu = true }) {
                Icon(Icons.Filled.MoreVert, contentDescription = "More", tint = palette.textSecondary)
            }
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                DropdownMenuItem(text = { Text(if (intention.isPinned) "Unpin" else "Pin") }, onClick = { menu = false; onPin() })
                DropdownMenuItem(text = { Text("Edit") }, onClick = { menu = false; onEdit() })
                DropdownMenuItem(text = { Text("Delete") }, onClick = { menu = false; confirmDelete = true })
            }
        }
    }
    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("Delete intention?", style = RosaryType.headingSecondaryPray, color = palette.ink) },
            text = { Text("This will delete “$title” from your intentions.", style = RosaryType.bodyPray, color = palette.dim) },
            confirmButton = {
                TextButton(onClick = { confirmDelete = false; onDelete() }) {
                    Text("Delete", color = palette.destructive)
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmDelete = false }) {
                    Text("Cancel", color = palette.accentText)
                }
            },
            containerColor = palette.bg,
        )
    }
}

private val papalMonthFormatter: DateTimeFormatter =
    DateTimeFormatter.ofPattern("MMMM yyyy", Locale.UK)

fun OfferIntention.papalMonthLabel(): String? {
    if (!isPapal || createdAtEpochMs <= 0L) return null
    return Instant.ofEpochMilli(createdAtEpochMs)
        .atZone(ZoneId.systemDefault())
        .toLocalDate()
        .format(papalMonthFormatter)
}

@Composable
fun IntentionIcon(intention: OfferIntention, size: androidx.compose.ui.unit.Dp, modifier: Modifier = Modifier) {
    if (intention.isPapal) {
        Image(
            painter = painterResource(R.drawable.pope_leo),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = modifier.size(size).clip(CircleShape),
        )
    } else {
        Box(
            modifier = modifier
                .size(size)
                .clip(CircleShape)
                .background(intention.accent.fill()),
            contentAlignment = Alignment.Center,
        ) {
            Text(intention.displayEmoji, style = RosaryType.bodyPray)
        }
    }
}

@Composable
fun IntentionHero(
    intention: OfferIntention,
    hidden: Boolean,
    onOpen: () -> Unit,
    onPray: () -> Unit,
    onPin: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    var menu by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    val title = IntentionPrivacy.displayTitle(intention, hidden)
    val hiddenTitle = IntentionPrivacy.hides(intention, hidden)
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.surface)
            .clickable(onClick = onOpen)
            .padding(RosarySpace.lg),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IntentionIcon(intention = intention, size = 57.dp)
            Spacer(Modifier.width(RosarySpace.lg))
            Text(
                title,
                style = RosaryType.bodyPray,
                color = if (hiddenTitle) palette.dim else palette.ink,
                maxLines = 2,
                modifier = Modifier.weight(1f),
            )
            Box {
                IconButton(onClick = { menu = true }) {
                    Icon(Icons.Filled.MoreVert, contentDescription = "More", tint = palette.textSecondary)
                }
                DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                    DropdownMenuItem(text = { Text(if (intention.isPinned) "Unpin" else "Pin") }, onClick = { menu = false; onPin() })
                    DropdownMenuItem(text = { Text("Edit") }, onClick = { menu = false; onEdit() })
                    DropdownMenuItem(text = { Text("Delete") }, onClick = { menu = false; confirmDelete = true })
                }
            }
        }
        Spacer(Modifier.height(RosarySpace.md))
        GuideSecondaryButton(title = "Pray my next Rosary for this", onClick = onPray)
    }
    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("Delete intention?", style = RosaryType.headingSecondaryPray, color = palette.ink) },
            text = { Text("This will delete “$title” from your intentions.", style = RosaryType.bodyPray, color = palette.dim) },
            confirmButton = {
                TextButton(onClick = { confirmDelete = false; onDelete() }) {
                    Text("Delete", color = palette.destructive)
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmDelete = false }) {
                    Text("Cancel", color = palette.accentText)
                }
            },
            containerColor = palette.bg,
        )
    }
}
