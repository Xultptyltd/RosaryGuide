package app.rosaryguide.feature.profile

import androidx.compose.foundation.background
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
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
import app.rosaryguide.core.data.session.IntentionPrivacy
import app.rosaryguide.core.data.session.OfferIntention
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

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
    val title = IntentionPrivacy.displayTitle(intention, hidden)
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onOpen)
            .padding(vertical = RosarySpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(intention.accent.fill()),
            contentAlignment = Alignment.Center,
        ) {
            Text(intention.displayEmoji, style = RosaryType.body)
        }
        Spacer(Modifier.width(RosarySpace.md))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = RosaryType.body, color = palette.ink, maxLines = 2)
            Text(
                text = buildString {
                    append(intention.category.title)
                    if (intention.isPinned) append(" · Pinned")
                },
                style = RosaryType.caption,
                color = palette.textSecondary,
            )
        }
        Text(
            text = "Offer",
            style = RosaryType.caption,
            color = palette.accent,
            modifier = Modifier
                .clickable(onClick = onPray)
                .padding(horizontal = RosarySpace.sm, vertical = RosarySpace.xs),
        )
        Box {
            IconButton(onClick = { menu = true }) {
                Icon(Icons.Filled.MoreVert, contentDescription = "More", tint = palette.textSecondary)
            }
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                DropdownMenuItem(text = { Text(if (intention.isPinned) "Unpin" else "Pin") }, onClick = { menu = false; onPin() })
                DropdownMenuItem(text = { Text("Edit") }, onClick = { menu = false; onEdit() })
                DropdownMenuItem(text = { Text("Delete") }, onClick = { menu = false; onDelete() })
            }
        }
    }
}
