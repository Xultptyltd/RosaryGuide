package app.rosaryguide.core.designsystem.gallery

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuideMarqueeText
import app.rosaryguide.core.designsystem.component.GuidePill
import app.rosaryguide.core.designsystem.component.GuideRow
import app.rosaryguide.core.designsystem.component.GuideScreenHeader
import app.rosaryguide.core.designsystem.component.GuideSectionLabel
import app.rosaryguide.core.designsystem.component.ProvideReduceMotion
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.designsystem.theme.ThemePalette

@Composable
fun ThemeGalleryScreen(modifier: Modifier = Modifier) {
    ProvideReduceMotion {
        val palette = LocalThemePalette.current
        Column(
            modifier = modifier
                .fillMaxSize()
                .background(palette.groupedBackground)
                .statusBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(RosarySpace.lg),
            verticalArrangement = Arrangement.spacedBy(RosarySpace.md),
        ) {
            GuideScreenHeader(
                title = "Theme gallery",
                subtitle = if (palette.isDark) "Dark appearance" else "Light appearance",
            )
            GuideSectionLabel("Colour tokens")
            TokenRow("Accent / Marian blue", palette.accent, palette.onAccent)
            TokenRow("Accent text", palette.accentText, palette.background)
            TokenRow("Background", palette.background, palette.ink)
            TokenRow("Grouped background", palette.groupedBackground, palette.ink)
            TokenRow("Surface", palette.surface, palette.ink)
            TokenRow("Secondary text", palette.textSecondary, palette.background)
            TokenRow("Feast gold", palette.feastIndicator, palette.background)
            TokenRow("Destructive", palette.destructive, palette.background)
            TokenRow("Success", palette.success, palette.background)
            TokenRow("Primary button", palette.primaryButtonFill, palette.primaryButtonText)
            TokenRow("Secondary button", palette.secondaryButtonFill, palette.secondaryButtonText)
            TokenRow("Tertiary button", palette.tertiaryButtonFill, palette.tertiaryButtonText)
            TokenRow("Google button", palette.googleButtonFill, palette.googleButtonText)
            TokenRow("Apple button (parity token)", palette.appleButtonFill, palette.appleButtonText)

            GuideSectionLabel("Type scale")
            Text("Heading primary — Instrument Sans 32", style = RosaryType.headingPrimary, color = palette.ink)
            Text("Heading secondary — Instrument Sans 22", style = RosaryType.headingSecondary, color = palette.ink)
            Text("Body — Instrument Sans 16", style = RosaryType.body, color = palette.ink)
            Text("Supporting — Instrument Sans 15", style = RosaryType.supportingLabel, color = palette.textSecondary)
            Text("Caption — Instrument Sans 12", style = RosaryType.caption, color = palette.textSecondary)
            Text("Newsreader body. The Word was made flesh.", style = RosaryType.serifBody, color = palette.ink)
            Text("Newsreader italic prayer line.", style = RosaryType.serifItalicBody, color = palette.ink)
            Text("Newsreader display", style = RosaryType.serifDisplay, color = palette.ink)

            GuideSectionLabel("Components")
            Row(horizontalArrangement = Arrangement.spacedBy(RosarySpace.sm)) {
                GuidePill("Pray now", emphasized = true)
                GuidePill("Today")
            }
            GuideRow(title = "Joyful Mysteries", subtitle = "Monday · Saturday")
            GuideRow(title = "Our Lady of the Rosary", subtitle = "Memorial")
            GuideMarqueeText("Many pray the Joyful Mysteries at Christmas. Take a few quiet minutes for the Rosary.")

            GuideSectionLabel("Art")
            Row(horizontalArrangement = Arrangement.spacedBy(RosarySpace.sm)) {
                ArtPlate(R.drawable.hero_joyful, "Joyful hero")
                ArtPlate(R.drawable.feast_assumption, "Assumption")
                ArtPlate(R.drawable.mystery_01_annunciation, "Annunciation")
            }
            Spacer(Modifier.height(RosarySpace.xl))
        }
    }
}

@Composable
private fun TokenRow(name: String, fill: Color, onFill: Color) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(RosarySpace.nestedRadius))
            .background(fill)
            .padding(RosarySpace.md),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(text = name, style = RosaryType.supportingLabel, color = onFill)
    }
}

@Composable
private fun ArtPlate(resId: Int, label: String) {
    val palette = LocalThemePalette.current
    Column {
        Image(
            painter = painterResource(resId),
            contentDescription = label,
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .size(width = 100.dp, height = 120.dp)
                .clip(RoundedCornerShape(RosarySpace.nestedRadius))
                .border(1.dp, palette.cardSurfaceStroke, RoundedCornerShape(RosarySpace.nestedRadius)),
        )
        Text(text = label, style = RosaryType.caption, color = palette.textSecondary)
    }
}
