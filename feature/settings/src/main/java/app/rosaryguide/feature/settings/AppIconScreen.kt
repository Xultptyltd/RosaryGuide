package app.rosaryguide.feature.settings

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.AppIconOption
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon

@Composable
fun AppIconScreen(
    selected: AppIconOption,
    onSelect: (AppIconOption) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val shape = RoundedCornerShape(RosarySpace.containerRadius)
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        GuideDetailTopBar(title = "App icon", onBack = onBack, milkyOnPlain = true)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.xxl),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            AppIconHomePreview(selected = selected)
            Spacer(Modifier.height(RosarySpace.xl))
            Text(
                text = "Available",
                style = RosaryType.bodyPray,
                color = palette.ink,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = RosarySpace.sm),
            )
            AppIconOption.entries.forEach { option ->
                val isOn = option == selected
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(shape)
                        .background(palette.cardSurface(app.rosaryguide.core.designsystem.theme.PageStyle.Plain))
                        .clickable { onSelect(option) }
                        .padding(RosarySpace.md),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Image(
                        painter = painterResource(previewOf(option)),
                        contentDescription = null,
                        modifier = Modifier
                            .size(56.dp)
                            .clip(RoundedCornerShape((56 * 0.225).dp)),
                    )
                    Text(
                        text = option.title,
                        style = RosaryType.bodyPray,
                        color = palette.ink,
                        modifier = Modifier
                            .weight(1f)
                            .padding(start = RosarySpace.md),
                    )
                    if (isOn) {
                        Icon(
                            imageVector = Icons.Filled.Check,
                            contentDescription = "Selected",
                            tint = palette.ink,
                            modifier = Modifier.size(22.dp),
                        )
                    }
                }
                Spacer(Modifier.height(RosarySpace.sm))
            }
        }
    }
}

private fun previewOf(option: AppIconOption): Int = when (option) {
    AppIconOption.Blue -> R.drawable.icon_preview_blue
    AppIconOption.Black -> R.drawable.icon_preview_black
    AppIconOption.White -> R.drawable.icon_preview_white
}


@Composable
private fun AppIconHomePreview(selected: AppIconOption) {
    val palette = LocalThemePalette.current
    val phone = RoundedCornerShape(36.dp)
    val placeholders = listOf("Calendar", "Photos", "Camera", "Mail", "Notes", "Reminders", "Clock")
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(phone)
            .background(palette.cardSurface(app.rosaryguide.core.designsystem.theme.PageStyle.Plain))
            .padding(horizontal = 28.dp, vertical = 28.dp),
    ) {
        val cell = 56.dp
        val gap = 16.dp
        // Two rows of four: selected icon first, then seven placeholders.
        val labels = listOf("Rosary Guide") + placeholders
        labels.chunked(4).forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = androidx.compose.foundation.layout.Arrangement.SpaceBetween,
            ) {
                row.forEachIndexed { index, label ->
                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.width(cell + 8.dp)) {
                        if (label == "Rosary Guide") {
                            Image(
                                painter = painterResource(previewOf(selected)),
                                contentDescription = null,
                                modifier = Modifier
                                    .size(cell)
                                    .clip(RoundedCornerShape((56 * 0.225).dp)),
                            )
                        } else {
                            Box(
                                modifier = Modifier
                                    .size(cell)
                                    .clip(RoundedCornerShape((56 * 0.225).dp))
                                    .background(if (palette.isDark) Color(0xFF3A3A3C) else Color(0xFFE8E8ED)),
                                contentAlignment = Alignment.Center,
                            ) {
                                PlaceholderGlyph(label, tint = palette.dim)
                            }
                        }
                        Spacer(Modifier.height(6.dp))
                        Text(
                            text = label,
                            style = RosaryType.captionPray,
                            color = palette.ink,
                            maxLines = 2,
                            textAlign = TextAlign.Center,
                            overflow = TextOverflow.Clip,
                        )
                    }
                }
            }
            Spacer(Modifier.height(gap))
        }
    }
}


@Composable
private fun PlaceholderGlyph(label: String, tint: Color) {
    Canvas(Modifier.size(26.dp)) {
        val s = this.size.minDimension
        val stroke = Stroke(width = s * 0.08f, cap = StrokeCap.Round)
        when (label) {
            "Calendar" -> {
                drawRoundRect(tint, topLeft = androidx.compose.ui.geometry.Offset(s*0.12f, s*0.18f), size = androidx.compose.ui.geometry.Size(s*0.76f, s*0.7f), cornerRadius = androidx.compose.ui.geometry.CornerRadius(s*0.1f,s*0.1f), style = stroke)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.12f, s*0.38f), androidx.compose.ui.geometry.Offset(s*0.88f, s*0.38f), strokeWidth = s*0.08f)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.32f, s*0.08f), androidx.compose.ui.geometry.Offset(s*0.32f, s*0.28f), strokeWidth = s*0.08f, cap = StrokeCap.Round)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.68f, s*0.08f), androidx.compose.ui.geometry.Offset(s*0.68f, s*0.28f), strokeWidth = s*0.08f, cap = StrokeCap.Round)
            }
            "Photos" -> {
                drawRoundRect(tint, topLeft = androidx.compose.ui.geometry.Offset(s*0.08f, s*0.22f), size = androidx.compose.ui.geometry.Size(s*0.84f, s*0.64f), cornerRadius = androidx.compose.ui.geometry.CornerRadius(s*0.08f,s*0.08f), style = stroke)
                drawCircle(tint, radius = s*0.08f, center = androidx.compose.ui.geometry.Offset(s*0.32f, s*0.42f), style = stroke)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.16f, s*0.76f), androidx.compose.ui.geometry.Offset(s*0.42f, s*0.52f), strokeWidth = s*0.08f, cap = StrokeCap.Round)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.42f, s*0.52f), androidx.compose.ui.geometry.Offset(s*0.86f, s*0.76f), strokeWidth = s*0.08f, cap = StrokeCap.Round)
            }
            "Camera" -> {
                drawRoundRect(tint, topLeft = androidx.compose.ui.geometry.Offset(s*0.08f, s*0.3f), size = androidx.compose.ui.geometry.Size(s*0.84f, s*0.56f), cornerRadius = androidx.compose.ui.geometry.CornerRadius(s*0.1f,s*0.1f), style = stroke)
                drawCircle(tint, radius = s*0.16f, center = androidx.compose.ui.geometry.Offset(s*0.5f, s*0.56f), style = stroke)
                drawRoundRect(tint, topLeft = androidx.compose.ui.geometry.Offset(s*0.38f, s*0.16f), size = androidx.compose.ui.geometry.Size(s*0.24f, s*0.16f), cornerRadius = androidx.compose.ui.geometry.CornerRadius(s*0.04f,s*0.04f), style = stroke)
            }
            "Mail" -> {
                drawRoundRect(tint, topLeft = androidx.compose.ui.geometry.Offset(s*0.08f, s*0.22f), size = androidx.compose.ui.geometry.Size(s*0.84f, s*0.6f), cornerRadius = androidx.compose.ui.geometry.CornerRadius(s*0.08f,s*0.08f), style = stroke)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.08f, s*0.28f), androidx.compose.ui.geometry.Offset(s*0.5f, s*0.52f), strokeWidth = s*0.08f, cap = StrokeCap.Round)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.5f, s*0.52f), androidx.compose.ui.geometry.Offset(s*0.92f, s*0.28f), strokeWidth = s*0.08f, cap = StrokeCap.Round)
            }
            "Notes" -> {
                drawRoundRect(tint, topLeft = androidx.compose.ui.geometry.Offset(s*0.2f, s*0.1f), size = androidx.compose.ui.geometry.Size(s*0.62f, s*0.8f), cornerRadius = androidx.compose.ui.geometry.CornerRadius(s*0.08f,s*0.08f), style = stroke)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.34f, s*0.38f), androidx.compose.ui.geometry.Offset(s*0.68f, s*0.38f), strokeWidth = s*0.07f, cap = StrokeCap.Round)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.34f, s*0.54f), androidx.compose.ui.geometry.Offset(s*0.68f, s*0.54f), strokeWidth = s*0.07f, cap = StrokeCap.Round)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.34f, s*0.7f), androidx.compose.ui.geometry.Offset(s*0.56f, s*0.7f), strokeWidth = s*0.07f, cap = StrokeCap.Round)
            }
            "Reminders" -> {
                drawRoundRect(tint, topLeft = androidx.compose.ui.geometry.Offset(s*0.2f, s*0.12f), size = androidx.compose.ui.geometry.Size(s*0.6f, s*0.76f), cornerRadius = androidx.compose.ui.geometry.CornerRadius(s*0.08f,s*0.08f), style = stroke)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.36f, s*0.4f), androidx.compose.ui.geometry.Offset(s*0.46f, s*0.52f), strokeWidth = s*0.08f, cap = StrokeCap.Round)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.46f, s*0.52f), androidx.compose.ui.geometry.Offset(s*0.68f, s*0.3f), strokeWidth = s*0.08f, cap = StrokeCap.Round)
            }
            else -> { // Clock
                drawCircle(tint, radius = s*0.4f, center = androidx.compose.ui.geometry.Offset(s*0.5f, s*0.5f), style = stroke)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.5f, s*0.5f), androidx.compose.ui.geometry.Offset(s*0.5f, s*0.28f), strokeWidth = s*0.08f, cap = StrokeCap.Round)
                drawLine(tint, androidx.compose.ui.geometry.Offset(s*0.5f, s*0.5f), androidx.compose.ui.geometry.Offset(s*0.72f, s*0.5f), strokeWidth = s*0.08f, cap = StrokeCap.Round)
            }
        }
    }
}
