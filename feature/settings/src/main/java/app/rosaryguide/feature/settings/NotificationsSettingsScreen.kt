package app.rosaryguide.feature.settings

import android.Manifest
import android.app.TimePickerDialog
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import app.rosaryguide.core.data.notify.TimeOfDay
import app.rosaryguide.core.data.prefs.UserSettings
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace

enum class NotificationPermissionState { Granted, Denied, NotDetermined }

@Composable
fun NotificationsSettingsScreen(
    settings: UserSettings,
    onDailyEnabled: (Boolean) -> Unit,
    onDailyMinutes: (Int) -> Unit,
    onFeastEnabled: (Boolean) -> Unit,
    onFeastMinutes: (Int) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    var permission by remember { mutableStateOf(currentPermission(context)) }
    var permissionWasDenied by remember { mutableStateOf(permission == NotificationPermissionState.Denied) }

    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        permission = if (granted) NotificationPermissionState.Granted else NotificationPermissionState.Denied
        if (!granted) permissionWasDenied = true
    }

    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                permission = currentPermission(context)
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    fun requestOrApply(enable: Boolean, apply: (Boolean) -> Unit) {
        if (!enable) {
            apply(false)
            return
        }
        when (permission) {
            NotificationPermissionState.Granted -> apply(true)
            NotificationPermissionState.NotDetermined -> {
                if (Build.VERSION.SDK_INT >= 33) {
                    launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
                } else {
                    apply(true)
                }
            }
            NotificationPermissionState.Denied -> {
                permissionWasDenied = true
                apply(false)
            }
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        GuideDetailTopBar(title = "Notifications", onBack = onBack)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.xxl),
        ) {
            SettingsToggleRow(
                title = "Daily rosary reminder",
                checked = settings.dailyReminderEnabled,
                onCheckedChange = { requestOrApply(it, onDailyEnabled) },
            )
            if (settings.dailyReminderEnabled) {
                SettingsDivider()
                SettingsNavigationRow(
                    title = "Reminder time",
                    value = TimeOfDay.format(settings.dailyReminderMinutes),
                    onClick = {
                        showTimePicker(context, settings.dailyReminderMinutes, onDailyMinutes)
                    },
                )
            }
            SettingsDivider()
            SettingsToggleRow(
                title = "Feast day alerts",
                checked = settings.feastAlertsEnabled,
                onCheckedChange = { requestOrApply(it, onFeastEnabled) },
            )
            if (settings.feastAlertsEnabled) {
                SettingsDivider()
                SettingsNavigationRow(
                    title = "Alert time",
                    value = TimeOfDay.format(settings.feastAlertMinutes),
                    onClick = {
                        showTimePicker(context, settings.feastAlertMinutes, onFeastMinutes)
                    },
                )
            }

            val planEmpty = !settings.dailyReminderEnabled && !settings.feastAlertsEnabled
            when {
                permission == NotificationPermissionState.NotDetermined && !planEmpty -> {
                    SettingsDivider()
                    SettingsNavigationRow(
                        title = "Allow notifications",
                        onClick = {
                            if (Build.VERSION.SDK_INT >= 33) {
                                launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
                            }
                        },
                    )
                    SettingsFootnote("Your reminders came from your account. Allow notifications on this phone so they can be shown.")
                }
                permission == NotificationPermissionState.Denied && (permissionWasDenied || !planEmpty) -> {
                    SettingsDivider()
                    SettingsNavigationRow(
                        title = "Turn on in Android Settings",
                        external = true,
                        onClick = {
                            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            context.startActivity(intent)
                        },
                    )
                    SettingsFootnote("Notifications are turned off for Rosary Guide in Android Settings, so reminders can't be shown.")
                }
                else -> {
                    SettingsFootnote("The daily reminder names that day's mysteries. Feast day alerts arrive at your chosen time on feast days in the Rosary Guide calendar.")
                }
            }
        }
    }
}

private fun currentPermission(context: android.content.Context): NotificationPermissionState {
    if (Build.VERSION.SDK_INT < 33) {
        return if (NotificationManagerCompat.from(context).areNotificationsEnabled()) {
            NotificationPermissionState.Granted
        } else {
            NotificationPermissionState.Denied
        }
    }
    val granted = ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
        android.content.pm.PackageManager.PERMISSION_GRANTED
    if (granted) return NotificationPermissionState.Granted
    // After a denial areNotificationsEnabled is typically false; treat first-ask as not determined
    // only when the system still considers notifications enabled at the app level.
    return if (NotificationManagerCompat.from(context).areNotificationsEnabled()) {
        NotificationPermissionState.NotDetermined
    } else {
        NotificationPermissionState.Denied
    }
}

private fun showTimePicker(context: android.content.Context, minutes: Int, onPicked: (Int) -> Unit) {
    TimePickerDialog(
        context,
        { _, hour, minute -> onPicked(TimeOfDay.minutes(hour, minute)) },
        TimeOfDay.hour(minutes),
        TimeOfDay.minute(minutes),
        false,
    ).show()
}
