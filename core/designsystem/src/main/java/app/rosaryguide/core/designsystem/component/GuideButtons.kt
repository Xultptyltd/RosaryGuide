package app.rosaryguide.core.designsystem.component

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

@Composable
fun GuidePrimaryButton(
    title: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    val palette = LocalThemePalette.current
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .height(RosarySpace.pillHeight),
        shape = RoundedCornerShape(RosarySpace.containerRadius),
        colors = ButtonDefaults.buttonColors(
            containerColor = palette.buttonPrimaryFill,
            contentColor = palette.buttonPrimaryText,
        ),
        contentPadding = PaddingValues(horizontal = RosarySpace.lg),
    ) {
        Text(text = title, style = RosaryType.body)
    }
}

@Composable
fun GuideSecondaryButton(
    title: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    val palette = LocalThemePalette.current
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .height(RosarySpace.pillHeight),
        shape = RoundedCornerShape(RosarySpace.containerRadius),
        colors = ButtonDefaults.buttonColors(
            containerColor = palette.buttonSecondaryFill,
            contentColor = palette.buttonSecondaryText,
        ),
    ) {
        Text(text = title, style = RosaryType.body)
    }
}

@Composable
fun GuideTertiaryButton(
    title: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    val palette = LocalThemePalette.current
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .height(RosarySpace.pillHeight),
        shape = RoundedCornerShape(RosarySpace.containerRadius),
        colors = ButtonDefaults.buttonColors(
            containerColor = palette.buttonTertiaryFill,
            contentColor = palette.buttonTertiaryText,
        ),
    ) {
        Text(text = title, style = RosaryType.body)
    }
}

@Composable
fun GuideGoogleButton(
    title: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    val palette = LocalThemePalette.current
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .height(RosarySpace.pillHeight),
        shape = RoundedCornerShape(RosarySpace.containerRadius),
        border = BorderStroke(1.dp, palette.googleButtonStroke),
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = palette.googleButtonFill,
            contentColor = palette.googleButtonText,
        ),
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
        ) {
            Icon(
                painter = painterResource(R.drawable.google_g),
                contentDescription = null,
                tint = androidx.compose.ui.graphics.Color.Unspecified,
                modifier = Modifier.size(20.dp),
            )
            Spacer(Modifier.width(10.dp))
            Text(text = title, style = RosaryType.body)
        }
    }
}

@Composable
fun GuideOutlineButton(
    title: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    val palette = LocalThemePalette.current
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .height(RosarySpace.pillHeight),
        shape = RoundedCornerShape(RosarySpace.containerRadius),
        border = BorderStroke(1.dp, palette.strokeRegular),
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = androidx.compose.ui.graphics.Color.Transparent,
            contentColor = palette.ink,
        ),
    ) {
        Text(text = title, style = RosaryType.body)
    }
}

@Composable
fun GuideSectionDivider(modifier: Modifier = Modifier) {
    val palette = LocalThemePalette.current
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        androidx.compose.foundation.Image(
            painter = painterResource(R.drawable.section_divider_left),
            contentDescription = null,
            modifier = Modifier.height(20.dp),
        )
        Box(
            modifier = Modifier
                .weight(1f)
                .height(1.dp)
                .clip(RoundedCornerShape(1.dp))
                .background(palette.sectionDivider),
        )
        androidx.compose.foundation.Image(
            painter = painterResource(R.drawable.section_divider_right),
            contentDescription = null,
            modifier = Modifier.height(20.dp),
        )
    }
}
