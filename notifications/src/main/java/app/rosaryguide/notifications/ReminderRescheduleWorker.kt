package app.rosaryguide.notifications

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

class ReminderRescheduleWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {
    override fun doWork(): Result {
        ReminderEnvironment.rescheduleNow()
        return Result.success()
    }
}
