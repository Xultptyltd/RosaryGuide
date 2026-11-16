package app.rosaryguide.feature.settings

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.Info
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import app.rosaryguide.core.data.legal.LicenseEntry
import app.rosaryguide.core.data.prefs.UserSettings
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.AppIconOption
import app.rosaryguide.core.model.AppearancePreference
import app.rosaryguide.core.model.RosaryConfig

enum class SettingsPage {
    Root,
    CustomiseRosary,
    Notifications,
    AppIcon,
    Terms,
    Privacy,
    Acknowledgements,
    License,
}

@Composable
fun SettingsScreen(
    settings: UserSettings,
    appVersion: String,
    isSignedIn: Boolean,
    signedInWith: String? = null,
    hasAppHistory: Boolean,
    playStorePackage: String? = null,
    initialPage: SettingsPage = SettingsPage.Root,
    onAppearance: (AppearancePreference) -> Unit,
    onRosaryConfig: (RosaryConfig) -> Unit,
    onDailyEnabled: (Boolean) -> Unit,
    onDailyMinutes: (Int) -> Unit,
    onFeastEnabled: (Boolean) -> Unit,
    onFeastMinutes: (Int) -> Unit,
    onAppIcon: (AppIconOption) -> Unit,
    onClearHistory: () -> Unit,
    onSignOut: () -> Unit,
    onReplayWelcome: () -> Unit,
    onSignIn: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var page by remember(initialPage) { mutableStateOf(initialPage) }
    var license by remember { mutableStateOf<LicenseEntry?>(null) }

    when (page) {
        SettingsPage.CustomiseRosary -> CustomiseRosaryScreen(
            config = settings.rosaryConfig,
            onConfigChange = onRosaryConfig,
            onBack = { page = SettingsPage.Root },
            modifier = modifier,
        )
        SettingsPage.Notifications -> NotificationsSettingsScreen(
            settings = settings,
            onDailyEnabled = onDailyEnabled,
            onDailyMinutes = onDailyMinutes,
            onFeastEnabled = onFeastEnabled,
            onFeastMinutes = onFeastMinutes,
            onBack = { page = SettingsPage.Root },
            modifier = modifier,
        )
        SettingsPage.AppIcon -> AppIconScreen(
            selected = settings.appIcon,
            onSelect = onAppIcon,
            onBack = { page = SettingsPage.Root },
            modifier = modifier,
        )
        SettingsPage.Terms -> LegalDocumentScreen(
            kind = LegalKind.Terms,
            onBack = { page = SettingsPage.Root },
            modifier = modifier,
        )
        SettingsPage.Privacy -> LegalDocumentScreen(
            kind = LegalKind.Privacy,
            onBack = { page = SettingsPage.Root },
            modifier = modifier,
        )
        SettingsPage.Acknowledgements -> AcknowledgementsScreen(
            onBack = { page = SettingsPage.Root },
            onOpenLicense = {
                license = it
                page = SettingsPage.License
            },
            modifier = modifier,
        )
        SettingsPage.License -> {
            val entry = license
            if (entry == null) page = SettingsPage.Acknowledgements
            else LicenseDetailScreen(
                entry = entry,
                onBack = { page = SettingsPage.Acknowledgements },
                modifier = modifier,
            )
        }
        SettingsPage.Root -> SettingsRoot(
            settings = settings,
            appVersion = appVersion,
            isSignedIn = isSignedIn,
            signedInWith = signedInWith,
            hasAppHistory = hasAppHistory,
            playStorePackage = playStorePackage,
            onOpen = { page = it },
            onAppearance = onAppearance,
            onClearHistory = onClearHistory,
            onSignOut = onSignOut,
            onReplayWelcome = onReplayWelcome,
            onSignIn = onSignIn,
            onBack = onBack,
            modifier = modifier,
        )
    }
}

@Composable
private fun SettingsRoot(
    settings: UserSettings,
    appVersion: String,
    isSignedIn: Boolean,
    signedInWith: String?,
    hasAppHistory: Boolean,
    playStorePackage: String?,
    onOpen: (SettingsPage) -> Unit,
    onAppearance: (AppearancePreference) -> Unit,
    onClearHistory: () -> Unit,
    onSignOut: () -> Unit,
    onReplayWelcome: () -> Unit,
    onSignIn: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    var themeMenu by remember { mutableStateOf(false) }
    var confirmClear by remember { mutableStateOf(false) }
    var didClear by remember { mutableStateOf(false) }
    var confirmSignOut by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    var deleteStub by remember { mutableStateOf(false) }

    fun openUrl(url: String) {
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        GuideDetailTopBar(title = "Settings", onBack = onBack)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.xxl),
        ) {
            SettingsSection(title = "General") {
                SettingsNavigationRow("Customise rosary", onClick = { onOpen(SettingsPage.CustomiseRosary) }, icon = Icons.Filled.Settings)
                SettingsDivider()
                androidx.compose.foundation.layout.Box {
                    SettingsNavigationRow(
                        title = "Color theme",
                        value = settings.appearance.title,
                        onClick = { themeMenu = true },
                    )
                    DropdownMenu(expanded = themeMenu, onDismissRequest = { themeMenu = false }) {
                        AppearancePreference.entries.forEach { option ->
                            DropdownMenuItem(
                                text = { Text(option.title) },
                                onClick = {
                                    onAppearance(option)
                                    themeMenu = false
                                },
                            )
                        }
                    }
                }
                SettingsDivider()
                SettingsNavigationRow("Notifications", onClick = { onOpen(SettingsPage.Notifications) }, icon = Icons.Filled.Notifications)
                SettingsDivider()
                SettingsNavigationRow("App icon", onClick = { onOpen(SettingsPage.AppIcon) })
            }

            Spacer(Modifier.height(RosarySpace.xl))
            if (isSignedIn) {
                SettingsSection(title = "Account") {
                    SettingsNavigationRow(
                        title = "Signed in with",
                        value = signedInWith ?: "Google",
                        onClick = {},
                        enabled = false,
                    )
                }
            } else {
                SettingsSection(title = "Account") {
                    Text(
                        "Your prayer stays on this device. Create an account when sign-in sync arrives to keep a backup.",
                        style = RosaryType.caption,
                        color = palette.dim,
                    )
                    Spacer(Modifier.height(RosarySpace.md))
                    GuidePrimaryButton(title = "Create account", onClick = onSignIn)
                }
            }

            Spacer(Modifier.height(RosarySpace.xl))
            SettingsSection(title = "Help & support") {
                SettingsNavigationRow("Report a problem", external = true, onClick = { openUrl("https://xult.ltd/contact/") })
                SettingsDivider()
                SettingsNavigationRow("Suggest a feature", external = true, onClick = { openUrl("https://xult.ltd/contact/") })
                if (playStorePackage != null) {
                    SettingsDivider()
                    SettingsNavigationRow(
                        title = "Leave a review",
                        icon = Icons.Filled.Star,
                        external = true,
                        onClick = {
                            openUrl("https://play.google.com/store/apps/details?id=$playStorePackage")
                        },
                    )
                }
            }

            Spacer(Modifier.height(RosarySpace.xl))
            SettingsSection(title = "About") {
                SettingsNavigationRow("Replay welcome", onClick = onReplayWelcome)
                SettingsDivider()
                SettingsNavigationRow("Terms of service", onClick = { onOpen(SettingsPage.Terms) })
                SettingsDivider()
                SettingsNavigationRow("Privacy", onClick = { onOpen(SettingsPage.Privacy) })
                SettingsDivider()
                SettingsNavigationRow("Acknowledgements", onClick = { onOpen(SettingsPage.Acknowledgements) }, icon = Icons.Outlined.Info)
            }

            Spacer(Modifier.height(RosarySpace.xl))
            if (isSignedIn) {
                SettingsNavigationRow("Sign out", destructive = true, onClick = { confirmSignOut = true })
                SettingsDivider()
            }
            SettingsNavigationRow(
                title = "Clear app history",
                destructive = true,
                enabled = hasAppHistory,
                onClick = { confirmClear = true },
            )
            if (isSignedIn) {
                SettingsDivider()
                SettingsNavigationRow(
                    title = "Delete account",
                    destructive = true,
                    onClick = { confirmDelete = true },
                )
            }

            Spacer(Modifier.height(RosarySpace.xl))
            Text(
                text = "Version $appVersion",
                style = RosaryType.caption,
                color = palette.dim,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }

    if (confirmClear) {
        AlertDialog(
            onDismissRequest = { confirmClear = false },
            title = { Text("Clear app history?") },
            text = {
                Text(
                    if (isSignedIn) {
                        "This clears your prayer progress, prayer history, intentions and settings on this device. The wipe also reaches your account. Your sign-in stays."
                    } else {
                        "This clears your prayer progress, prayer history, intentions and settings on this device."
                    },
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        onClearHistory()
                        confirmClear = false
                        didClear = true
                    },
                ) { Text("Clear") }
            },
            dismissButton = { TextButton(onClick = { confirmClear = false }) { Text("Cancel") } },
        )
    }
    if (didClear) {
        AlertDialog(
            onDismissRequest = { didClear = false },
            title = { Text("App history cleared") },
            text = { Text("Your prayer progress, intentions and settings have been cleared from this device.") },
            confirmButton = { TextButton(onClick = { didClear = false }) { Text("OK") } },
        )
    }
    if (confirmSignOut) {
        AlertDialog(
            onDismissRequest = { confirmSignOut = false },
            title = { Text("Sign out?") },
            text = { Text("You’ll stay a guest on this device. Your prayer data stays here.") },
            confirmButton = {
                TextButton(onClick = {
                    onSignOut()
                    confirmSignOut = false
                }) { Text("Sign out") }
            },
            dismissButton = { TextButton(onClick = { confirmSignOut = false }) { Text("Cancel") } },
        )
    }
    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("Delete account?") },
            text = {
                Text("Account deletion will be available when sign-in sync arrives. Nothing has been deleted.")
            },
            confirmButton = {
                TextButton(onClick = {
                    confirmDelete = false
                    deleteStub = true
                }) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text("Cancel") } },
        )
    }
    if (deleteStub) {
        AlertDialog(
            onDismissRequest = { deleteStub = false },
            title = { Text("Account not deleted") },
            text = { Text("Account deletion will be available when sign-in sync arrives (M5).") },
            confirmButton = { TextButton(onClick = { deleteStub = false }) { Text("OK") } },
        )
    }
}
