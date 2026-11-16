package app.rosaryguide.feature.pray

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import app.rosaryguide.core.data.catalog.PrayerCatalog
import app.rosaryguide.core.data.session.OfferedIntentions
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.CompletionQuote
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.RosaryStepKind

@Composable
fun CompletionScreen(
    mysterySet: MysterySetKind,
    quote: CompletionQuote,
    intentionTitles: List<String>,
    includeSaintMichael: Boolean,
    onDone: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = RosarySpace.gutter),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(RosarySpace.xxl))
        Text(
            text = "finis",
            style = RosaryType.serifItalicBody,
            color = palette.dim,
        )
        Spacer(Modifier.height(RosarySpace.sm))
        Text(
            text = "ROSARY COMPLETE",
            style = RosaryType.headingPrimary,
            color = palette.ink,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(RosarySpace.xs))
        Text(
            text = mysterySet.titleText.english,
            style = RosaryType.body,
            color = palette.dim,
        )
        Spacer(Modifier.height(RosarySpace.xl))
        Text(
            text = "“${quote.text}”",
            style = RosaryType.serifBody,
            color = palette.ink,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(Modifier.height(RosarySpace.sm))
        Text(
            text = quote.attribution,
            style = RosaryType.supportingLabel,
            color = palette.dim,
            textAlign = TextAlign.Center,
        )
        OfferedIntentions.summary(intentionTitles)?.let { summary ->
            Spacer(Modifier.height(RosarySpace.xl))
            Text(text = "Offered for", style = RosaryType.supportingLabel, color = palette.dim)
            Spacer(Modifier.height(RosarySpace.xs))
            Text(text = summary, style = RosaryType.body, color = palette.ink, textAlign = TextAlign.Center)
        }
        if (includeSaintMichael) {
            val prayer = PrayerCatalog.prayer(RosaryStepKind.SaintMichael)
            Spacer(Modifier.height(RosarySpace.xl))
            Text(text = "Saint Michael Prayer", style = RosaryType.headingSecondary, color = palette.ink)
            Spacer(Modifier.height(RosarySpace.sm))
            Text(
                text = prayer?.text?.english.orEmpty(),
                style = RosaryType.serifBody,
                color = palette.ink,
            )
        }
        Spacer(Modifier.height(RosarySpace.xxl))
        GuidePrimaryButton(title = "Done", onClick = onDone)
        Spacer(Modifier.height(RosarySpace.xl))
    }
}
