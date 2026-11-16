package app.rosaryguide.feature.settings

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SettingsMailTest {
    @Test
    fun bugAndTranslationSubjectsMatchIOS() {
        assertEquals("Rosary Guide bug report", SettingsMail.subject(SupportMailKind.Bug))
        assertEquals("Translation bug in Rosary Guide", SettingsMail.subject(SupportMailKind.Translation))
        assertEquals("support@xult.ltd", SettingsMail.RECIPIENT)
        assertEquals("https://xult.ltd/contact/", SettingsMail.CONTACT_FORM)
    }

    @Test
    fun bodiesIncludeDiagnostics() {
        val bug = SettingsMail.body(SupportMailKind.Bug, "0.7.0-m7", null)
        assertTrue(bug.contains("Steps to reproduce:"))
        assertTrue(bug.contains("Version: 0.7.0-m7"))
        assertTrue(bug.contains("not signed in"))
        val translation = SettingsMail.body(SupportMailKind.Translation, "0.7.0-m7", "user-1")
        assertTrue(translation.contains("Which text is wrong:"))
        assertTrue(translation.contains("App user id: user-1"))
    }
}
