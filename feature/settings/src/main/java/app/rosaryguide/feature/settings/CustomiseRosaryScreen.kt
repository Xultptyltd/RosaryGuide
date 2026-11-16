package app.rosaryguide.feature.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.designsystem.component.GuideTertiaryButton
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.model.BibleTranslation
import app.rosaryguide.core.model.RosaryConfig

@Composable
fun CustomiseRosaryScreen(
    config: RosaryConfig,
    onConfigChange: (RosaryConfig) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    title: String = "Customise rosary",
    showChrome: Boolean = true,
) {
    val palette = LocalThemePalette.current
    var confirmReset by remember { mutableStateOf(false) }
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        if (showChrome) {
            GuideDetailTopBar(title = title, onBack = onBack)
        }
        Box(Modifier.weight(1f)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = RosarySpace.gutter)
                    .padding(bottom = RosarySpace.xxl),
            ) {
                RosarySettingsRows(config = config, onConfigChange = onConfigChange)
            }
            GuideTertiaryButton(
                title = "Reset to default",
                onClick = { confirmReset = true },
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.md),
            )
        }
    }
    if (confirmReset) {
        AlertDialog(
            onDismissRequest = { confirmReset = false },
            title = { Text("Reset to default?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        onConfigChange(RosaryConfig.default)
                        confirmReset = false
                    },
                ) { Text("Reset") }
            },
            dismissButton = {
                TextButton(onClick = { confirmReset = false }) { Text("Cancel") }
            },
        )
    }
}

@Composable
fun RosarySettingsRows(
    config: RosaryConfig,
    onConfigChange: (RosaryConfig) -> Unit,
    modifier: Modifier = Modifier,
) {
    var translationMenu by remember { mutableStateOf(false) }
    Column(modifier = modifier.fillMaxWidth()) {
        SettingsToggleRow("Choose intentions", config.intentionsStep) {
            onConfigChange(config.copy(intentionsStep = it))
        }
        SettingsDivider()
        SettingsToggleRow("Show rosary beads", config.showBeads) {
            onConfigChange(config.copy(showBeads = it))
        }

        Spacer(Modifier.height(RosarySpace.xl))
        SettingsSection(title = "Each decade") {
            Box {
                SettingsNavigationRow(
                    title = "Bible translation",
                    value = config.translation.title,
                    onClick = { translationMenu = true },
                )
                DropdownMenu(expanded = translationMenu, onDismissRequest = { translationMenu = false }) {
                    BibleTranslation.entries.forEach { option ->
                        DropdownMenuItem(
                            text = { Text(option.title) },
                            onClick = {
                                onConfigChange(config.copy(translation = option))
                                translationMenu = false
                            },
                        )
                    }
                }
            }
            SettingsDivider()
            SettingsToggleRow("Fatima prayer", config.fatimaPrayer) {
                onConfigChange(config.copy(fatimaPrayer = it))
            }
            SettingsDivider()
            SettingsToggleRow("O Sacrament most holy", config.oSacrament) {
                onConfigChange(config.copy(oSacrament = it))
            }
        }

        Spacer(Modifier.height(RosarySpace.xl))
        SettingsSection(title = "Closing prayers") {
            SettingsToggleRow("Hail, holy Queen", config.closingPrayers) {
                onConfigChange(config.copy(closingPrayers = it))
            }
            SettingsDivider()
            SettingsToggleRow("Memorare", config.memorare) {
                onConfigChange(config.copy(memorare = it))
            }
            SettingsDivider()
            SettingsToggleRow("Saint Michael", config.saintMichael) {
                onConfigChange(config.copy(saintMichael = it))
            }
        }
    }
}
