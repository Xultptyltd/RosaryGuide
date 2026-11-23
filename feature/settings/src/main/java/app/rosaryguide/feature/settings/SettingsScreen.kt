package app.rosaryguide.feature.settings

import androidx.activity.compose.BackHandler
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
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Text
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
import app.rosaryguide.core.designsystem.component.GuideLargeTopAppBar
import java.time.ZoneId
import java.time.LocalDate
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.layout.Box
import app.rosaryguide.core.designsystem.component.AppPageBackground
import app.rosaryguide.core.designsystem.component.GuestBackupCard
import app.rosaryguide.core.designsystem.component.GuideDialogButton
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

/** Outcome of Delete account (iOS `SettingsView.deleteAccount`). */
sealed interface DeleteAccountResult {
    data object Deleted : DeleteAccountResult
    /** The Google sheet was closed; nothing is shown. */
    data object Cancelled : DeleteAccountResult
    data class Failed(val message: String) : DeleteAccountResult
}

enum class SettingsConfirmDialog { None, ClearHistory, DeleteAccount, SignOut, ReportProblem, MailUnavailable }

@Composable
fun SettingsScreen(
    settings: UserSettings,
    appVersion: String,
    isSignedIn: Boolean,
    signedInWith: String? = null,
    hasAppHistory: Boolean,
    playStorePackage: String? = null,
    initialPage: SettingsPage = SettingsPage.Root,
    initialConfirm: SettingsConfirmDialog = SettingsConfirmDialog.None,
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
    onDeleteAccount: (onFinished: (DeleteAccountResult) -> Unit) -> Unit = { it(DeleteAccountResult.Cancelled) },
    onAccountDeleted: () -> Unit = {},
    today: LocalDate = LocalDate.now(),
    zone: ZoneId = ZoneId.systemDefault(),
    earliestActivityEpochMs: Long? = null,
    initialLicense: LicenseEntry? = null,
    modifier: Modifier = Modifier,
) {
    var page by remember(initialPage) { mutableStateOf(initialPage) }
    var license by remember { mutableStateOf(initialLicense) }
    BackHandler {
        when (page) {
            SettingsPage.Root -> onBack()
            SettingsPage.License -> {
                page = SettingsPage.Acknowledgements
                license = null
            }
            else -> page = SettingsPage.Root
        }
    }

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
            onDeleteAccount = onDeleteAccount,
            onAccountDeleted = onAccountDeleted,
            initialConfirm = initialConfirm,
            onBack = onBack,
            today = today,
            zone = zone,
            earliestActivityEpochMs = earliestActivityEpochMs,
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
    onDeleteAccount: (onFinished: (DeleteAccountResult) -> Unit) -> Unit,
    onAccountDeleted: () -> Unit,
    initialConfirm: SettingsConfirmDialog = SettingsConfirmDialog.None,
    today: LocalDate,
    zone: ZoneId,
    earliestActivityEpochMs: Long? = null,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    var themeMenu by remember { mutableStateOf(false) }
    var confirmClear by remember { mutableStateOf(initialConfirm == SettingsConfirmDialog.ClearHistory) }
    var didClear by remember { mutableStateOf(false) }
    var confirmSignOut by remember { mutableStateOf(initialConfirm == SettingsConfirmDialog.SignOut) }
    var confirmDelete by remember { mutableStateOf(initialConfirm == SettingsConfirmDialog.DeleteAccount) }
    var isDeletingAccount by remember { mutableStateOf(false) }
    var didDeleteAccount by remember { mutableStateOf(false) }
    var accountDeletionError by remember { mutableStateOf<String?>(null) }
    var reportProblem by remember { mutableStateOf(initialConfirm == SettingsConfirmDialog.ReportProblem) }
    var mailUnavailable by remember { mutableStateOf(initialConfirm == SettingsConfirmDialog.MailUnavailable) }

    fun openUrl(url: String) {
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    Box(modifier = modifier.fillMaxSize().background(palette.bg)) {
    Column(
        modifier = Modifier.fillMaxSize(),
    ) {
        GuideDetailTopBar(
            title = "Settings",
            onBack = onBack,
            containerColor = palette.bg,
            milkyOnPlain = true,
            chevronBack = true,
        )
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                // iOS guideDetailChrome contentTop (16) + (sectionGap − xl) = 36.
                .padding(
                    top = RosarySpace.lg + (RosarySpace.section - RosarySpace.xl),
                    bottom = RosarySpace.xxl,
                ),
        ) {
            SettingsSection(title = "General", carded = false) {
                SettingsNavigationRow("Customise rosary", onClick = { onOpen(SettingsPage.CustomiseRosary) }, icon = SettingsSymbols.sliderHorizontal3)
                SettingsDivider()
                androidx.compose.foundation.layout.Box {
                    SettingsNavigationRow(
                        title = "Color theme",
                        value = settings.appearance.title,
                        icon = SettingsSymbols.circleLeftHalfFilled,
                        showChevron = false,
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
                SettingsNavigationRow("Notifications", onClick = { onOpen(SettingsPage.Notifications) }, icon = SettingsSymbols.bell)
                SettingsDivider()
                SettingsNavigationRow("App icon", onClick = { onOpen(SettingsPage.AppIcon) }, icon = SettingsSymbols.app)
            }

            SettingsSectionBoundary()
            if (isSignedIn) {
                SettingsSection(title = "Account", carded = false) {
                    SettingsNavigationRow(
                        title = "Signed in with",
                        value = signedInWith ?: "Google",
                        onClick = {},
                        enabled = false,
                    )
                }
            } else {
                GuestBackupCard(
                    onCreateAccount = onSignIn,
                    today = today,
                    zone = zone,
                    earliestActivityEpochMs = earliestActivityEpochMs,
                    pageStyle = app.rosaryguide.core.designsystem.theme.PageStyle.Plain,
                )
            }

            SettingsSectionBoundary()
            SettingsSection(title = "Help & support", carded = false) {
                SettingsNavigationRow("Report a problem", external = true, onClick = { reportProblem = true }, icon = SettingsSymbols.exclamationBubble)
                SettingsDivider()
                SettingsNavigationRow("Suggest a feature", external = true, onClick = { openUrl("https://xult.ltd/contact/") }, icon = SettingsSymbols.lightbulb)
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

            SettingsSectionBoundary()
            SettingsSection(title = "About", carded = false) {
                SettingsNavigationRow("Replay welcome", onClick = onReplayWelcome, icon = SettingsSymbols.sparkles)
                SettingsDivider()
                SettingsNavigationRow("Terms of service", onClick = { onOpen(SettingsPage.Terms) }, icon = SettingsSymbols.docText)
                SettingsDivider()
                SettingsNavigationRow("Privacy", onClick = { onOpen(SettingsPage.Privacy) }, icon = SettingsSymbols.handRaised)
                SettingsDivider()
                SettingsNavigationRow("Acknowledgements", onClick = { onOpen(SettingsPage.Acknowledgements) }, icon = Icons.Outlined.FavoriteBorder)
            }

            SettingsSectionBoundary()
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
                    title = if (isDeletingAccount) "Deleting..." else "Delete account",
                    destructive = true,
                    enabled = !isDeletingAccount,
                    onClick = { confirmDelete = true },
                )
            }

            Spacer(Modifier.height(RosarySpace.xl))
            Text(
                text = "Version $appVersion",
                style = RosaryType.captionPray,
                color = palette.dim,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
    }

    if (reportProblem) {
        AlertDialog(
            onDismissRequest = { reportProblem = false },
            title = { Text("What would you like to report?") },
            text = {
                androidx.compose.foundation.layout.Column {
                    GuideDialogButton(
                        text = "Bug",
                        onClick = {
                            reportProblem = false
                            SettingsMail.send(context, SupportMailKind.Bug, appVersion)
                        },
                    )
                    GuideDialogButton(
                        text = "Translation",
                        onClick = {
                            reportProblem = false
                            SettingsMail.send(context, SupportMailKind.Translation, appVersion)
                        },
                    )
                }
            },
            confirmButton = {},
            dismissButton = {
                GuideDialogButton(text = "Cancel", onClick = { reportProblem = false })
            },
        )
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
                GuideDialogButton(
                    text = "Clear",
                    onClick = {
                        onClearHistory()
                        confirmClear = false
                        didClear = true
                    },
                    destructive = true,
                )
            },
            dismissButton = {
                GuideDialogButton(text = "Cancel", onClick = { confirmClear = false })
            },
        )
    }
    if (didClear) {
        AlertDialog(
            onDismissRequest = { didClear = false },
            title = { Text("App history cleared") },
            text = { Text("Your prayer progress, intentions and settings have been cleared from this device.") },
            confirmButton = { GuideDialogButton(text = "OK", onClick = { didClear = false }) },
        )
    }
    if (confirmSignOut) {
        AlertDialog(
            onDismissRequest = { confirmSignOut = false },
            title = { Text("Sign out?") },
            text = { Text("You’ll stay a guest on this device. Your prayer data stays here.") },
            confirmButton = {
                GuideDialogButton(
                    text = "Sign out",
                    onClick = {
                        onSignOut()
                        confirmSignOut = false
                    },
                    destructive = true,
                )
            },
            dismissButton = {
                GuideDialogButton(text = "Cancel", onClick = { confirmSignOut = false })
            },
        )
    }
    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("Delete account?") },
            text = {
                Text(
                    "This permanently deletes your Rosary Guide account and everything synced to it (intentions, prayer history and settings), then clears your prayer data from this device. You'll confirm with Google first. This can't be undone.",
                )
            },
            confirmButton = {
                GuideDialogButton(
                    text = "Delete account",
                    onClick = {
                        confirmDelete = false
                        isDeletingAccount = true
                        onDeleteAccount { result ->
                            isDeletingAccount = false
                            when (result) {
                                DeleteAccountResult.Deleted -> didDeleteAccount = true
                                DeleteAccountResult.Cancelled -> Unit
                                is DeleteAccountResult.Failed -> accountDeletionError = result.message
                            }
                        }
                    },
                    destructive = true,
                )
            },
            dismissButton = {
                GuideDialogButton(text = "Cancel", onClick = { confirmDelete = false })
            },
        )
    }
    if (didDeleteAccount) {
        val close = {
            didDeleteAccount = false
            onAccountDeleted()
        }
        AlertDialog(
            onDismissRequest = close,
            title = { Text("Account deleted") },
            text = {
                Text(
                    "Your account and everything synced to it (intentions, prayer history and settings) were deleted, and your prayer data was cleared from this device.",
                )
            },
            confirmButton = { GuideDialogButton(text = "OK", onClick = close) },
        )
    }
    accountDeletionError?.let { message ->
        AlertDialog(
            onDismissRequest = { accountDeletionError = null },
            title = { Text("Account not deleted") },
            text = { Text(message) },
            confirmButton = { GuideDialogButton(text = "OK", onClick = { accountDeletionError = null }) },
        )
    }
    if (mailUnavailable) {
        AlertDialog(
            onDismissRequest = { mailUnavailable = false },
            title = { Text("Mail not available") },
            text = { Text("Set up Mail on this device, or use the contact form at xult.ltd/contact/.") },
            confirmButton = { GuideDialogButton(text = "OK", onClick = { mailUnavailable = false }) },
        )
    }
}
