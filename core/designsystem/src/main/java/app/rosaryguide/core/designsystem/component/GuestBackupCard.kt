package app.rosaryguide.core.designsystem.component

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.Image
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.res.painterResource
import app.rosaryguide.core.designsystem.R
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.PageStyle
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit

/**
 * iOS `GuestBackupCard`: guests-only invite to create an account so
 * intentions and history can sync. Headline counts whole days since the
 * earliest local activity.
 */
@Composable
fun GuestBackupCard(
    onCreateAccount: () -> Unit,
    modifier: Modifier = Modifier,
    today: LocalDate = LocalDate.now(),
    zone: ZoneId = ZoneId.systemDefault(),
    earliestActivityEpochMs: Long? = null,
) {
    val palette = LocalThemePalette.current
    val headline = backupHeadline(today, zone, earliestActivityEpochMs)
    val shape = RoundedCornerShape(RosarySpace.featureRadius)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(palette.cardSurface(PageStyle.Grouped))
            .padding(horizontal = RosarySpace.lg, vertical = RosarySpace.xl),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Image(
            painter = painterResource(R.drawable.ic_icloud_arrow_up),
            contentDescription = null,
            colorFilter = ColorFilter.tint(palette.ink),
            modifier = Modifier.size(34.dp),
        )
        Spacer(Modifier.height(RosarySpace.md))
        Text(
            text = headline,
            style = RosaryType.bodyPray,
            color = palette.ink,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(RosarySpace.xs))
        Text(
            text = "Sign in or create an account to keep your intentions and history safe across devices",
            style = RosaryType.bodyPray,
            color = palette.dim,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(RosarySpace.sm + RosarySpace.md))
        GuidePrimaryButton(title = "Create account", onClick = onCreateAccount)
    }
}

fun backupHeadline(
    today: LocalDate,
    zone: ZoneId,
    earliestActivityEpochMs: Long?,
): String {
    if (earliestActivityEpochMs == null) return "Your prayers are not backed up yet"
    val earliest = java.time.Instant.ofEpochMilli(earliestActivityEpochMs)
        .atZone(zone)
        .toLocalDate()
    val days = ChronoUnit.DAYS.between(earliest, today).toInt().coerceAtLeast(0)
    return when (days) {
        0 -> "Your prayers are not backed up yet"
        1 -> "Your prayers have not been backed up for 1 day"
        else -> "Your prayers have not been backed up for $days days"
    }
}
