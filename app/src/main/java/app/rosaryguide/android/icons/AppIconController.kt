package app.rosaryguide.android.icons

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import app.rosaryguide.core.model.AppIconOption

/** Switches the launcher icon via activity aliases. Marian blue is the default alias. */
class AppIconController(private val context: Context) {
    /** An icon chosen on another device; swapped when the app leaves the screen. */
    @Volatile var pending: AppIconOption? = null

    fun applyPending() {
        val option = pending ?: return
        pending = null
        apply(option)
    }

    fun apply(option: AppIconOption) {
        val pm = context.packageManager
        val pkg = context.packageName
        val selected = aliasName(pkg, option)
        val all = AppIconOption.entries.map { aliasName(pkg, it) }
        // Enable the chosen alias first so the launcher is never left without an icon.
        pm.setComponentEnabledSetting(
            ComponentName(pkg, selected),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        all.filter { it != selected }.forEach { name ->
            pm.setComponentEnabledSetting(
                ComponentName(pkg, name),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    companion object {
        fun aliasName(packageName: String, option: AppIconOption): String = when (option) {
            AppIconOption.Blue -> "$packageName.MainActivityDefault"
            AppIconOption.Black -> "$packageName.MainActivityBlack"
            AppIconOption.White -> "$packageName.MainActivityWhite"
        }
    }
}
