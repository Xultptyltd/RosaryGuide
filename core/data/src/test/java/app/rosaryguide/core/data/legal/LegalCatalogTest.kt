package app.rosaryguide.core.data.legal

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class LegalCatalogTest {
    @Test
    fun licensesCoverTheAndroidDependencySet() {
        val licenses = LegalCatalog.licenses()
        val ids = licenses.map { it.id }.toSet()
        val expected = setOf(
            "androidx-core",
            "androidx-activity",
            "androidx-lifecycle",
            "androidx-navigation",
            "androidx-datastore",
            "androidx-work",
            "androidx-splashscreen",
            "androidx-compose",
            "androidx-compose-material3",
            "hilt",
            "kotlinx-coroutines",
            "kotlinx-serialization",
            "lottie",
            "play-review",
            "firebase-android",
            "instrument-sans",
            "newsreader",
        )
        assertEquals(expected, ids)
        val fonts = licenses.filter { it.id == "instrument-sans" || it.id == "newsreader" }
        assertTrue(fonts.all { "SIL OPEN FONT LICENSE" in it.license.uppercase() || "OFL" in it.license })
        val firebase = licenses.first { it.id == "firebase-android" }
        assertTrue(firebase.version.contains("M5"))
    }
}
