package app.rosaryguide.android

import android.content.Intent
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class KeyFlowsInstrumentedTest {

    @get:Rule
    val compose = createEmptyComposeRule()

    private var scenario: ActivityScenario<MainActivity>? = null

    @Before
    fun setAnimationScale() {
        val automation = InstrumentationRegistry.getInstrumentation().uiAutomation
        listOf(
            "settings put global animator_duration_scale 0",
            "settings put global transition_animation_scale 0",
            "settings put global window_animation_scale 0",
            "pm grant app.rosaryguide.android android.permission.POST_NOTIFICATIONS",
        ).forEach { automation.executeShellCommand(it).close() }
    }

    @After
    fun closeActivity() {
        scenario?.close()
        scenario = null
    }

    @Test
    fun onboardingContinueAsGuestReachesToday() {
        launch(
            "skip_splash" to true,
            "force_onboarding" to true,
            "clock_date" to "2026-11-16",
        )
        compose.waitUntil(15_000) {
            compose.onAllNodesWithText("Continue").fetchSemanticsNodes().isNotEmpty()
        }
        compose.onNodeWithText("Continue").performClick()
        compose.waitForIdle()
        compose.onNodeWithText("Continue").performClick()
        compose.waitForIdle()
        compose.waitUntil(15_000) {
            compose.onAllNodesWithText("Begin").fetchSemanticsNodes().isNotEmpty()
        }
        compose.onNodeWithText("Begin").performClick()
        compose.waitUntil(15_000) {
            compose.onAllNodesWithText("Continue as guest").fetchSemanticsNodes().isNotEmpty()
        }
        compose.onNodeWithText("Continue as guest").performClick()
        compose.waitUntil(20_000) {
            compose.onAllNodesWithText("Pray today's mysteries").fetchSemanticsNodes().isNotEmpty()
        }
        compose.onNodeWithText("Pray today's mysteries").assertExists()
    }

    @Test
    fun prayingAFullRosaryReachesDone() {
        launch(
            "skip_splash" to true,
            "force_tabs" to true,
            "open_pray" to true,
            "force_fresh_pray" to true,
            "clock_date" to "2026-11-16",
        )
        compose.waitUntil(20_000) {
            compose.onAllNodesWithText("Continue").fetchSemanticsNodes().isNotEmpty() ||
                compose.onAllNodesWithText("Next").fetchSemanticsNodes().isNotEmpty()
        }
        var finished = false
        for (step in 0 until 200) {
            compose.waitForIdle()
            if (compose.onAllNodesWithText("Finish").fetchSemanticsNodes().isNotEmpty()) {
                Thread.sleep(350)
                compose.onNodeWithText("Finish").performClick()
                finished = true
                break
            }
            when {
                compose.onAllNodesWithText("Next").fetchSemanticsNodes().isNotEmpty() ->
                    compose.onNodeWithText("Next").performClick()
                compose.onAllNodesWithText("Continue").fetchSemanticsNodes().isNotEmpty() ->
                    compose.onNodeWithText("Continue").performClick()
                else -> error("Rosary walk lost Next/Continue at iteration $step")
            }
            // PrayScreen debounce uses wall-clock 300ms between advances.
            Thread.sleep(350)
        }
        check(finished) { "Did not reach Finish after 200 advances" }
        compose.waitUntil(20_000) {
            compose.onAllNodesWithText("Done").fetchSemanticsNodes().isNotEmpty()
        }
        compose.onNodeWithText("Done").performClick()
        compose.waitUntil(20_000) {
            compose.onAllNodesWithText("Pray today's mysteries").fetchSemanticsNodes().isNotEmpty()
        }
    }

    @Test
    fun addingAnIntentionFromProfile() {
        launch(
            "skip_splash" to true,
            "force_tabs" to true,
            "start_tab" to "profile",
            "open_intention_editor" to true,
            "clock_date" to "2026-11-16",
        )
        compose.waitUntil(15_000) {
            compose.onAllNodesWithText("Save intention").fetchSemanticsNodes().isNotEmpty()
        }
        compose.onNodeWithText("What’s on your heart?").performTextInput("For peace in our home")
        compose.onNodeWithText("Save intention").performClick()
        compose.waitUntil(15_000) {
            compose.onAllNodesWithText("For peace in our home").fetchSemanticsNodes().isNotEmpty()
        }
        compose.onNodeWithText("For peace in our home").assertExists()
    }

    @Test
    fun settingsCustomiseTogglesFatimaPrayer() {
        launch(
            "skip_splash" to true,
            "force_tabs" to true,
            "open_customise_rosary" to true,
            "clock_date" to "2026-11-16",
        )
        compose.waitUntil(15_000) {
            compose.onAllNodesWithText("Fatima prayer").fetchSemanticsNodes().isNotEmpty()
        }
        compose.onNodeWithText("Fatima prayer").assertExists()
        compose.onNodeWithText("Fatima prayer").performClick()
        compose.waitForIdle()
        compose.onNodeWithText("Fatima prayer").assertExists()
        compose.onNodeWithText("Customise rosary").assertExists()
    }

    private fun launch(vararg extras: Pair<String, Any>) {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            extras.forEach { (key, value) ->
                when (value) {
                    is Boolean -> putExtra(key, value)
                    is String -> putExtra(key, value)
                    is Int -> putExtra(key, value)
                    else -> putExtra(key, value.toString())
                }
            }
        }
        scenario = ActivityScenario.launch(intent)
    }
}
