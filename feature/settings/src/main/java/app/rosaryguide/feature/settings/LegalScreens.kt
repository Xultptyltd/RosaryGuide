package app.rosaryguide.feature.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
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
        GuideDetailTopBar(title = title, onBack = onBack)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.xxl),
        ) {
            blocks.forEach { block ->
                val style = when (block.kind) {
                    "h1" -> RosaryType.headingPrimary
                    "h2" -> RosaryType.headingSecondary
                    "h3" -> RosaryType.body
                    else -> RosaryType.body
                }
                val color = if (block.kind == "h1" || block.kind == "h2" || block.kind == "h3") palette.ink else palette.ink
                val prefix = if (block.kind == "li") "• " else ""
                Text(
                    text = annotatedLegal(prefix + block.text, palette.accentText),
                    style = style,
                    color = color,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = RosarySpace.md),
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
        GuideDetailTopBar(title = "Acknowledgements", onBack = onBack)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.xxl),
        ) {
            items.forEach { item ->
                SettingsNavigationRow(
                    title = item.name,
                    value = item.version,
                    onClick = { onOpenLicense(item) },
                )
                SettingsDivider()
            }
        }
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
        GuideDetailTopBar(title = entry.name, onBack = onBack)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = RosarySpace.gutter)
                .padding(bottom = RosarySpace.xxl),
        ) {
            Text(entry.version, style = RosaryType.caption, color = palette.dim)
            Spacer(Modifier.height(RosarySpace.sm))
            Text(
                text = entry.url,
                style = RosaryType.caption,
                color = palette.accentText,
                modifier = Modifier.clickable { uriHandler.openUri(entry.url) },
            )
            Spacer(Modifier.height(RosarySpace.lg))
            Text(entry.license, style = RosaryType.caption, color = palette.ink)
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
