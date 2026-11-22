package app.rosaryguide.feature.pray

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import app.rosaryguide.core.designsystem.theme.RosarySpace

/**
 * iOS `BilingualStack` / `PrayerReaderBlock` paragraph layout.
 *
 * Source `\n\n` starts a new paragraph. Soft `\n` inside a paragraph become
 * spaces, except a versicle or response line (`V.`, `R.`, ℣, ℟) which keeps
 * its line break. Paragraphs are stacked with [paragraphGap]
 * (`Space.xxl` in BilingualStack, `Space.xl` in PrayerReaderBlock).
 */
@Composable
fun PrayerBody(
    text: String,
    style: TextStyle,
    color: Color,
    modifier: Modifier = Modifier,
    paragraphGap: Dp = RosarySpace.xxl,
) {
    val paragraphs = remember(text) { prayerParagraphs(text) }
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(paragraphGap),
    ) {
        paragraphs.forEach { paragraph ->
            Text(
                text = paragraph,
                style = style,
                color = color,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

internal fun prayerParagraphs(raw: String): List<String> {
    return raw.split("\n\n")
        .map { joinSoftLines(it) }
        .map { it.trim() }
        .filter { it.isNotEmpty() }
}

private val versiclePrefixes = listOf("V.", "R.", "℣", "℟")

private fun joinSoftLines(para: String): String {
    val lines = para.split("\n")
    val out = StringBuilder()
    lines.forEachIndexed { i, line ->
        if (i > 0) {
            val trimmed = line.trimStart()
            val keepBreak = versiclePrefixes.any { trimmed.startsWith(it) }
            out.append(if (keepBreak) "\n" else " ")
        }
        out.append(line)
    }
    return out.toString()
}
