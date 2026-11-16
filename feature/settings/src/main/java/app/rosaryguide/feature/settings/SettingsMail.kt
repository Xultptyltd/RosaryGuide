package app.rosaryguide.feature.settings

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build

enum class SupportMailKind {
    Bug,
    Translation,
}

object SettingsMail {
    const val RECIPIENT = "support@xult.ltd"
    const val CONTACT_FORM = "https://xult.ltd/contact/"

    fun subject(kind: SupportMailKind): String = when (kind) {
        SupportMailKind.Bug -> "Rosary Guide bug report"
        SupportMailKind.Translation -> "Translation bug in Rosary Guide"
    }

    fun body(kind: SupportMailKind, appVersion: String, userId: String?): String {
        val prompt = when (kind) {
            SupportMailKind.Bug -> """
                Hi,

                I wanted to tell you that...

                Where in Rosary Guide is the issue:
                What happened:
                What did you expect:
                Steps to reproduce:

                Please attach a screenshot if helpful.
            """.trimIndent()
            SupportMailKind.Translation -> """
                Hi,

                I’ve noticed a translation error. Here’s more info.

                Where in Rosary Guide is the issue:
                Which text is wrong:
                What should it be:
                Language:

                Please attach a screenshot if helpful.
            """.trimIndent()
        }
        val diagnostics = """
            --
            Rosary Guide diagnostics
            Version: $appVersion
            Android: ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})
            Device: ${Build.MANUFACTURER} ${Build.MODEL}
            App user id: ${userId ?: "not signed in"}
        """.trimIndent()
        return "$prompt\n\n$diagnostics"
    }

    fun send(context: Context, kind: SupportMailKind, appVersion: String, userId: String? = null) {
        val subject = subject(kind)
        val body = body(kind, appVersion, userId)
        val mailto = Uri.parse(
            "mailto:$RECIPIENT?subject=${Uri.encode(subject)}&body=${Uri.encode(body)}",
        )
        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = mailto
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val canMail = intent.resolveActivity(context.packageManager) != null
        if (canMail) {
            context.startActivity(intent)
        } else {
            context.startActivity(
                Intent(Intent.ACTION_VIEW, Uri.parse(CONTACT_FORM))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }
}
