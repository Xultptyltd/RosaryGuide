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
import app.rosaryguide.core.designsystem.theme.PageStyle
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

@Composable
fun PrayerRhythmCard(
    rhythm: PrayerRhythm,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    val weeklySummary = if (rhythm.prayedDaysThisWeek > 0) {
        val days = rhythm.prayedDaysThisWeek
        if (days == 1) "1 day this week" else "$days days this week"
    } else {
        "Find room for prayer"
    }
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.cardSurface(PageStyle.Grouped))
            .padding(RosarySpace.lg + RosarySpace.xs)
            .semantics { contentDescription = rhythm.accessibilityLabel },
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(
                text = "Your prayer",
                style = RosaryType.supportingLabelPray,
                color = palette.textSecondary,
                modifier = Modifier.weight(1f),
            )
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = palette.dim.copy(alpha = 0.55f),
                modifier = Modifier.size(12.dp),
            )
        }
        Text(
            text = weeklySummary,
            style = RosaryType.headingSecondaryPray,
            color = palette.ink,
            modifier = Modifier.padding(top = RosarySpace.sm),
        )
        Spacer(Modifier.height(RosarySpace.md))
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            rhythm.currentWeek.forEachIndexed { index, day ->
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.weight(1f),
                ) {
                    Text(
                        text = rhythm.weekdayLabels.getOrElse(index) { "" },
                        style = RosaryType.captionPray,
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
            day.prayed -> Text("✓", style = RosaryType.captionPray, color = palette.accent)
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
