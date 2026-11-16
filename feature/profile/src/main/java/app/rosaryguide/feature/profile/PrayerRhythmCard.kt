package app.rosaryguide.feature.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.journey.PrayerRhythm
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

@Composable
fun PrayerRhythmCard(
    rhythm: PrayerRhythm,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.surface)
            .padding(RosarySpace.lg)
            .semantics { contentDescription = rhythm.accessibilityLabel },
    ) {
        Row(verticalAlignment = Alignment.Top, modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Your prayer",
                    style = RosaryType.supportingLabel,
                    color = palette.textSecondary,
                )
                Spacer(Modifier.height(RosarySpace.xs))
                Text(
                    text = rhythm.card.big,
                    style = RosaryType.rhythmSummary,
                    color = palette.ink,
                )
                Text(
                    text = rhythm.card.caption,
                    style = RosaryType.supportingLabel,
                    color = palette.textSecondary,
                )
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = if (rhythm.isMilestone) "🔥" else "📅",
                    style = RosaryType.headingSecondary,
                )
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = palette.textSecondary.copy(alpha = 0.55f),
                    modifier = Modifier.size(18.dp),
                )
            }
        }
        Spacer(Modifier.height(RosarySpace.md))
        Text(
            text = rhythm.weeklySummary,
            style = RosaryType.caption,
            color = palette.textSecondary,
        )
        Spacer(Modifier.height(RosarySpace.sm))
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            rhythm.currentWeek.forEachIndexed { index, day ->
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.weight(1f),
                ) {
                    Text(
                        text = rhythm.weekdayLabels.getOrElse(index) { "" },
                        style = RosaryType.caption,
                        color = palette.textSecondary,
                        maxLines = 1,
                    )
                    Spacer(Modifier.height(6.dp))
                    RhythmDayMarker(day)
                }
            }
        }
    }
}

@Composable
private fun RhythmDayMarker(day: PrayerRhythm.Day) {
    val palette = LocalThemePalette.current
    Box(
        modifier = Modifier.size(22.dp),
        contentAlignment = Alignment.Center,
    ) {
        when {
            day.prayed -> Text("✓", style = RosaryType.caption, color = palette.accent)
            day.isToday -> Box(
                modifier = Modifier
                    .size(16.dp)
                    .border(1.5.dp, palette.strokeSelected, CircleShape),
            )
            else -> Box(
                modifier = Modifier
                    .size(6.dp)
                    .clip(CircleShape)
                    .background(if (day.isFuture) palette.strokeRegular else palette.strokeStrong),
            )
        }
    }
}
