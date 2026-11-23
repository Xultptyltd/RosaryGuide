package app.rosaryguide.feature.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withLink
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.platform.LocalUriHandler
import app.rosaryguide.core.data.legal.LegalBlock
import app.rosaryguide.core.data.legal.LegalCatalog
import app.rosaryguide.core.data.legal.LicenseEntry
import app.rosaryguide.core.designsystem.component.GuideDetailTopBar
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType

enum class LegalKind { Terms, Privacy }

@Composable
fun LegalDocumentScreen(
    kind: LegalKind,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val title = if (kind == LegalKind.Terms) "Terms of service" else "Privacy"
    val blocks = remember(kind) {
        if (kind == LegalKind.Terms) LegalCatalog.terms() else LegalCatalog.privacy()
    }
    LegalDocumentBody(title = title, blocks = blocks, onBack = onBack, modifier = modifier)
}

@Composable
fun LegalDocumentBody(
    title: String,
    blocks: List<LegalBlock>,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val uriHandler = LocalUriHandler.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        GuideDetailTopBar(title = title, onBack = onBack, milkyOnPlain = true)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(top = RosarySpace.lg, bottom = RosarySpace.xxl),
            verticalArrangement = Arrangement.spacedBy(RosarySpace.lg),
        ) {
            blocks.forEach { block ->
                val style = when (block.kind) {
                    "h1" -> RosaryType.sansRole(32f, extraLineSpacingSp = 4f)
                    "h2", "h3" -> RosaryType.sansRole(22f, extraLineSpacingSp = 4f)
                    else -> RosaryType.sansRole(16f, extraLineSpacingSp = 4f)
                }
                val prefix = if (block.kind == "li") "• " else ""
                Text(
                    text = annotatedLegal(prefix + block.text, palette.accentText),
                    style = style,
                    color = palette.ink,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = if (block.kind == "h2") RosarySpace.lg else 0.dp),
                )
            }
        }
    }
}

@Composable
fun AcknowledgementsScreen(
    onBack: () -> Unit,
    onOpenLicense: (LicenseEntry) -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val items = remember { LegalCatalog.licenses() }
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        GuideDetailTopBar(title = "Acknowledgements", onBack = onBack, milkyOnPlain = true)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(top = RosarySpace.lg, bottom = RosarySpace.xxl),
        ) {
            items.forEach { item ->
                SettingsNavigationRow(
                    title = item.name,
                    onClick = { onOpenLicense(item) },
                )
                SettingsDivider()
            }
            SettingsSection(title = "Scripture") {
                ScriptureRow("World English Bible, Catholic Edition")
                ScriptureRow("Douay-Rheims (Challoner, 1899)")
                ScriptureRow("Clementine Vulgate")
            }
            SettingsSection(title = "Photos") {
                Text(
                    text = POPE_PHOTO_CREDIT,
                    style = RosaryType.captionReading,
                    color = palette.dim,
                    modifier = Modifier.padding(vertical = RosarySpace.md),
                )
            }
        }
    }
}

private const val POPE_PHOTO_CREDIT =
    "Photo of Pope Leo XIV: Edgar Beltrán, The Pillar, via Wikimedia Commons, CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/). Cropped; the cropped image is shared under the same licence."

@Composable
private fun ScriptureRow(title: String) {
    val palette = LocalThemePalette.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = RosarySpace.md),
        horizontalArrangement = androidx.compose.foundation.layout.Arrangement.SpaceBetween,
    ) {
        Text(text = title, style = RosaryType.bodyPray, color = palette.ink, modifier = Modifier.weight(1f))
        Text(text = "Public domain", style = RosaryType.captionPray, color = palette.dim)
    }
}

@Composable
fun LicenseDetailScreen(
    entry: LicenseEntry,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val palette = LocalThemePalette.current
    val uriHandler = LocalUriHandler.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        GuideDetailTopBar(title = entry.name, onBack = onBack, milkyOnPlain = true)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(top = RosarySpace.lg, bottom = RosarySpace.xxl),
        ) {
            Text(
                text = reflowLicense(entry.license),
                style = RosaryType.captionReading,
                color = palette.dim,
            )
        }
    }
}


private fun annotatedLegal(raw: String, linkColor: Color): AnnotatedString {
    val mdLink = Regex("""\[([^\]]+)]\(([^)]+)\)""")
    val bold = Regex("""\*\*(.+?)\*\*""")
    val tokens = mutableListOf<Pair<IntRange, Pair<String, String?>>>()
    mdLink.findAll(raw).forEach { match ->
        tokens += match.range to (match.groupValues[1] to match.groupValues[2])
    }
    bold.findAll(raw).forEach { match ->
        val overlaps = tokens.any { it.first.first <= match.range.last && match.range.first <= it.first.last }
        if (!overlaps) tokens += match.range to (match.groupValues[1] to null)
    }
    tokens.sortBy { it.first.first }
    return buildAnnotatedString {
        var cursor = 0
        for ((range, payload) in tokens) {
            if (cursor < range.first) append(raw.substring(cursor, range.first))
            val (label, url) = payload
            if (url != null) {
                withLink(
                    LinkAnnotation.Url(
                        url,
                        TextLinkStyles(SpanStyle(color = linkColor, textDecoration = TextDecoration.Underline)),
                    ),
                ) { append(label) }
            } else {
                withStyle(SpanStyle(fontWeight = FontWeight.SemiBold)) { append(label) }
            }
            cursor = range.last + 1
        }
        if (cursor < raw.length) append(raw.substring(cursor))
    }
}


private fun reflowLicense(raw: String): String {
    val lines = raw.replace("\r\n", "\n").replace("\r", "\n").split("\n").map { it.trim() }
    val lengths = lines.filter { it.isNotEmpty() }.map { it.length }.sorted()
    if (lengths.isEmpty()) return ""
    val wrapWidth = lengths[maxOf(0, (lengths.size * 0.9).toInt() - 1)]
    val joinThreshold = wrapWidth * 0.65
    val paragraphs = mutableListOf<List<String>>()
    var current = mutableListOf<String>()
    for (line in lines) {
        if (line.isEmpty()) {
            if (current.isNotEmpty()) {
                paragraphs += current
                current = mutableListOf()
            }
        } else {
            current += line
        }
    }
    if (current.isNotEmpty()) paragraphs += current
    val listMarker = Regex("""^(\(?\d+[.)]|\([A-Za-z0-9]{1,4}\)|[A-Za-z][.)](?=\s)|[-*•])\s""")
    val separator = Regex("""^[=*_#~-]{3,}$""")
    fun standalone(line: String) = line.startsWith("#") || separator.matches(line)
    return paragraphs.joinToString("\n\n") { paragraph ->
        val result = mutableListOf<String>()
        var previous = ""
        for (line in paragraph) {
            val joins = result.isNotEmpty()
                && previous.length >= joinThreshold
                && !previous.startsWith("Copyright")
                && !standalone(line)
                && !standalone(result.last())
                && listMarker.find(line) == null
            if (joins) {
                result[result.lastIndex] = result.last() + " " + line
            } else {
                result += line
            }
            previous = line
        }
        result.joinToString("\n")
    }
}
