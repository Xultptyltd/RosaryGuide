package app.rosaryguide.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import app.rosaryguide.core.data.notify.ReminderKind
import app.rosaryguide.core.data.notify.ScheduledReminder

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(ReminderScheduler.EXTRA_ID, 0)
        val body = intent.getStringExtra(ReminderScheduler.EXTRA_BODY) ?: return
        val kind = runCatching {
            ReminderKind.valueOf(intent.getStringExtra(ReminderScheduler.EXTRA_KIND) ?: return)
        }.getOrNull() ?: return
        val day = intent.getStringExtra(ReminderScheduler.EXTRA_DAY) ?: ""
        ReminderScheduler(context).show(
            ScheduledReminder(
                id = id,
                kind = kind,
                triggerEpochMs = System.currentTimeMillis(),
                body = body,
                dayKey = day,
            ),
        )
        ReminderEnvironment.rescheduleNow()
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            intent.action == Intent.ACTION_LOCKED_BOOT_COMPLETED
        ) {
            ReminderEnvironment.rescheduleNow()
        }
    }
}

class TimeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            -> ReminderEnvironment.rescheduleNow()
        }
    }
}
