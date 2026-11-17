package app.rosaryguide.notifications


import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import app.rosaryguide.core.data.notify.NotificationPlan
import app.rosaryguide.core.data.notify.ScheduledReminder
import app.rosaryguide.core.data.prefs.UserSettings
import java.time.LocalDateTime
import java.time.ZoneId
import java.util.concurrent.TimeUnit

/**
 * Schedules the daily prayer reminder and feast-day alerts with AlarmManager,
 * falling back to an inexact window when exact alarms are not permitted, and
 * a daily WorkManager pass to rebuild the plan after boot or clock changes.
 */
class ReminderScheduler(private val context: Context) {
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "Prayer reminders",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Daily rosary reminder and feast day alerts"
            },
        )
    }

    fun reschedule(settings: UserSettings, zone: ZoneId = ZoneId.systemDefault(), now: LocalDateTime = LocalDateTime.now(zone)) {
        ensureChannel()
        cancelAll()
        val items = NotificationPlan.build(settings.notificationPlanSettings, now, zone)
        items.forEach { schedule(it) }
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            PeriodicWorkRequestBuilder<ReminderRescheduleWorker>(1, TimeUnit.DAYS).build(),
        )
    }

    fun show(reminder: ScheduledReminder) {
        ensureChannel()
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val contentIntent = launch?.let {
            PendingIntent.getActivity(
                context,
                reminder.id,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_rosary)
            .setContentTitle(context.getString(android.R.string.unknownName).takeIf { false } ?: "")
            .setContentText(reminder.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(reminder.body))
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        runCatching {
            NotificationManagerCompat.from(context).notify(reminder.id, notification)
        }
    }

    fun scheduleRemindMe(
        feast: app.rosaryguide.core.model.Feast,
        date: java.time.LocalDate,
        settings: UserSettings,
        zone: ZoneId = ZoneId.systemDefault(),
        now: LocalDateTime = LocalDateTime.now(zone),
    ): ScheduledReminder {
        val reminder = NotificationPlan.remindMeReminder(
            feast = feast,
            date = date,
            minutes = settings.feastAlertMinutes,
            now = now,
            zone = zone,
        )
        schedule(reminder)
        return reminder
    }

    fun canScheduleExactAlarms(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    private fun schedule(item: ScheduledReminder) {
        val pending = pendingFor(item)
        val start = item.triggerEpochMs
        if (canScheduleExactAlarms()) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, start, pending)
        } else {
            alarmManager.setWindow(AlarmManager.RTC_WAKEUP, start, WINDOW_MS, pending)
        }
    }

    private fun cancelAll() {
        for (id in DAILY_IDS + FEAST_IDS) {
            val intent = Intent(context, ReminderReceiver::class.java).setAction(ACTION)
            val pending = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
            )
            if (pending != null) {
                alarmManager.cancel(pending)
                pending.cancel()
            }
        }
    }

    private fun pendingFor(item: ScheduledReminder): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            action = ACTION
            putExtra(EXTRA_ID, item.id)
            putExtra(EXTRA_BODY, item.body)
            putExtra(EXTRA_KIND, item.kind.name)
            putExtra(EXTRA_DAY, item.dayKey)
        }
        return PendingIntent.getBroadcast(
            context,
            item.id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        const val CHANNEL_ID = "prayer_reminders"
        const val ACTION = "app.rosaryguide.android.REMINDER"
        const val EXTRA_ID = "reminder_id"
        const val EXTRA_BODY = "reminder_body"
        const val EXTRA_KIND = "reminder_kind"
        const val EXTRA_DAY = "reminder_day"
        const val WORK_NAME = "rosaryguide-reminder-reschedule"
        private const val WINDOW_MS = 15 * 60 * 1000L
        private val DAILY_IDS = NotificationPlan.DAILY_ID_BASE until (NotificationPlan.DAILY_ID_BASE + 7)
        private val FEAST_IDS = NotificationPlan.FEAST_ID_BASE until (NotificationPlan.FEAST_ID_BASE + NotificationPlan.MAX_FEAST_DAYS)
    }
}

object ReminderEnvironment {
    @Volatile
    var reschedule: (() -> Unit)? = null

    fun rescheduleNow() {
        reschedule?.invoke()
    }
}
