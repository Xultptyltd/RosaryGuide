package app.rosaryguide.sync

import android.app.Activity
import java.lang.ref.WeakReference

/** The resumed activity, for Credential Manager's Google sheet. Set by `MainActivity`. */
object CurrentActivity {
    private var ref: WeakReference<Activity>? = null

    fun set(activity: Activity?) {
        ref = activity?.let { WeakReference(it) }
    }

    fun clear(activity: Activity) {
        if (ref?.get() === activity) ref = null
    }

    val value: Activity? get() = ref?.get()?.takeIf { !it.isFinishing && !it.isDestroyed }
}
