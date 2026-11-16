package app.rosaryguide.core.data

import org.junit.Assert.assertEquals
import org.junit.Test

class SettingsKeysTest {
    @Test
    fun onboardingKeyMatchesIosName() {
        assertEquals("onboarding.completed", SettingsKeys.OnboardingCompleted.name)
    }
}
