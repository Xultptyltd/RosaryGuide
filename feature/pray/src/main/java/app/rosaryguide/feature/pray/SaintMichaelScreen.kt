package app.rosaryguide.feature.pray

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import app.rosaryguide.core.data.catalog.PrayerCatalog
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.PrayerLanguage
import app.rosaryguide.core.model.RosaryStepKind

@Composable
fun SaintMichaelScreen(
    onDone: () -> Unit,
    onClose: () -> Unit = onDone,
    modifier: Modifier = Modifier,
    initialLanguage: PrayerLanguage = PrayerLanguage.English,
) {
    val palette = LocalThemePalette.current
    val prayer = PrayerCatalog.prayer(RosaryStepKind.SaintMichael)
    var language by remember { mutableStateOf(initialLanguage) }
    val title = prayer?.title
    val body = prayer?.text

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.prayBg)
            .statusBarsPadding()
            .navigationBarsPadding(),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = RosarySpace.sm, vertical = RosarySpace.xs),
        ) {
            PrayChromeButton(
                icon = Icons.Filled.Close,
                contentDescription = "Close",
                onClick = onClose,
                modifier = Modifier.align(Alignment.CenterEnd),
            )
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter),
        ) {
            Text(
                text = title?.resolved(language) ?: "Saint Michael the Archangel",
                style = RosaryType.headingPrimaryPray,
                color = palette.ink,
            )
            if (language != PrayerLanguage.Latin) {
                title?.latin?.takeIf { it.isNotBlank() && it != title.english }?.let { latin ->
                    Spacer(Modifier.height(RosarySpace.sm))
                    Text(text = latin, style = RosaryType.themeSummary, color = palette.dim)
                }
            }
            Spacer(Modifier.height(RosarySpace.xl))
            PrayerLanguageToggle(
                language = language,
                onChange = { language = it },
                useFullTitles = true,
                modifier = Modifier.fillMaxWidth(),
            )
            // iOS PrayerReaderBlock: stack Space.xl plus prayerReader padding.vertical lg.
            Spacer(Modifier.height(RosarySpace.xl))
            body?.let { text ->
                PrayerBody(
                    text = text.primary(language),
                    style = RosaryType.prayerTextMichael,
                    color = palette.ink,
                    paragraphGap = RosarySpace.xl,
                    modifier = Modifier.padding(
                        horizontal = RosarySpace.sm,
                        vertical = RosarySpace.lg,
                    ),
                )
                text.secondary(language)?.let { latin ->
                    PrayerBody(
                        text = latin,
                        style = RosaryType.prayerTextMichael,
                        color = palette.dim,
                        paragraphGap = RosarySpace.xl,
                        modifier = Modifier.padding(horizontal = RosarySpace.sm),
                    )
                }
            }
            Spacer(Modifier.height(RosarySpace.xl))
        }
        GuidePrimaryButton(
            title = "Done",
            onClick = onDone,
            modifier = Modifier
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.lg),
        )
    }
}
