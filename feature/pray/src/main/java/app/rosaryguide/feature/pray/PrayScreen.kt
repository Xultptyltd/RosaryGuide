package app.rosaryguide.feature.pray

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.catalog.QuoteCatalog
import app.rosaryguide.core.data.sequence.RosaryHaptics
import app.rosaryguide.core.data.sequence.RosarySequenceBuilder
import app.rosaryguide.core.data.session.OfferIntention
import app.rosaryguide.core.data.session.SessionStore
import app.rosaryguide.core.designsystem.component.GuideMarqueeText
import app.rosaryguide.core.designsystem.component.GuidePrimaryButton
import app.rosaryguide.core.designsystem.component.GuideSecondaryButton
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.model.CompletionQuote
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.PrayTrackStage
import app.rosaryguide.core.model.PrayerLanguage
import app.rosaryguide.core.model.RosaryConfig
import app.rosaryguide.core.model.RosaryStep
import app.rosaryguide.core.model.RosaryStepKind

data class PrayLaunch(
    val mysterySet: MysterySetKind,
    val startStep: Int? = null,
    val showIntentions: Boolean = false,
    val showCompletion: Boolean = false,
    val forceFresh: Boolean = false,
    val config: RosaryConfig = RosaryConfig.default,
    val seedIntentions: List<Pair<String, String>> = emptyList(),
)

@Composable
fun PrayScreen(
    launch: PrayLaunch,
    sessionStore: SessionStore,
    quotePreferences: app.rosaryguide.core.data.catalog.QuotePreferences,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    hapticEnabled: Boolean = true,
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val haptics = remember { HapticPlayer(context) }
    val saved by sessionStore.session.collectAsState()
    val savedIntentions by sessionStore.intentions.collectAsState()

    var config by remember { mutableStateOf(launch.config) }
    var steps by remember { mutableStateOf(RosarySequenceBuilder.build(launch.mysterySet, launch.config)) }
    var index by remember { mutableIntStateOf(0) }
    var showingIntentionStep by remember { mutableStateOf(false) }
    var showingCompletion by remember { mutableStateOf(false) }
    var celebrated by remember { mutableStateOf(setOf<Int>()) }
    var language by remember { mutableStateOf(PrayerLanguage.English) }
    var selectedIds by remember { mutableStateOf(listOf<String>()) }
    var selectedTitles by remember { mutableStateOf(listOf<String>()) }
    var completionQuote by remember { mutableStateOf<CompletionQuote?>(null) }
    var lastAdvanceAt by remember { mutableStateOf(0L) }

    LaunchedEffect(launch) {
        haptics.prepare(hapticEnabled)
        launch.seedIntentions.forEach { (id, title) ->
            if (savedIntentions.none { it.id == id || it.title == title }) {
                sessionStore.addIntention(title)
            }
        }
        val existing = saved?.takeIf { it.mysterySet == launch.mysterySet && it.isResumable(System.currentTimeMillis()) }
        if (!launch.forceFresh && !launch.showCompletion && existing != null) {
            config = existing.rosaryConfig
            steps = RosarySequenceBuilder.build(existing.mysterySet, existing.rosaryConfig)
            index = existing.stepIndex.coerceIn(0, steps.lastIndex)
            selectedIds = existing.intentionIds
            selectedTitles = existing.intentionTitles
            language = existing.language
            celebrated = existing.completedDecades
        } else {
            config = launch.config
            steps = RosarySequenceBuilder.build(launch.mysterySet, launch.config)
            val started = sessionStore.start(launch.mysterySet, language, config = launch.config)
            selectedIds = started.intentionIds
            selectedTitles = started.intentionTitles
            index = 0
            celebrated = emptySet()
        }
        if (launch.startStep != null) {
            index = launch.startStep.coerceIn(0, steps.lastIndex)
            sessionStore.updateStep(index)
        }
        showingIntentionStep = launch.showIntentions
        if (launch.showCompletion) {
            completionQuote = QuoteCatalog.freshCompletionQuote(quotePreferences)
            showingCompletion = true
        }
    }

    DisposableEffect(Unit) {
        onDispose { }
    }

    fun playArrival(at: RosaryStep, from: RosaryStep?, viaCompleteDecade: Boolean = false) {
        val arrival = RosaryHaptics.arrival(at, from, viaCompleteDecade, celebrated)
        arrival.celebratedDecade?.let { decade ->
            celebrated = celebrated + decade
            sessionStore.recordCompletedDecade(decade)
        }
        haptics.play(arrival.kind, hapticEnabled)
    }

    fun goTo(target: Int, from: RosaryStep?, viaCompleteDecade: Boolean = false) {
        val clamped = target.coerceIn(0, steps.lastIndex)
        val dest = steps[clamped]
        index = clamped
        showingIntentionStep = false
        sessionStore.updateStep(clamped)
        playArrival(dest, from, viaCompleteDecade)
        if (dest.kind == RosaryStepKind.Completion) {
            if (completionQuote == null) completionQuote = QuoteCatalog.freshCompletionQuote(quotePreferences)
            showingCompletion = true
            sessionStore.complete()
        }
    }

    fun advance() {
        val now = System.currentTimeMillis()
        if (now - lastAdvanceAt <= 300) return
        lastAdvanceAt = now
        val current = steps.getOrNull(index)
        if (showingIntentionStep) {
            goTo(index + 1, current)
            return
        }
        if (current?.kind == RosaryStepKind.SignOfTheCross &&
            current.stage == PrayTrackStage.Opening &&
            config.intentionsStep &&
            index < steps.lastIndex
        ) {
            showingIntentionStep = true
            haptics.play(current.haptic, hapticEnabled)
            return
        }
        if (current?.kind == RosaryStepKind.Completion) {
            if (completionQuote == null) completionQuote = QuoteCatalog.freshCompletionQuote(quotePreferences)
            showingCompletion = true
            sessionStore.complete()
            return
        }
        if (current?.isLastPrayer == true) {
            if (completionQuote == null) completionQuote = QuoteCatalog.freshCompletionQuote(quotePreferences)
            showingCompletion = true
            sessionStore.complete()
            haptics.play(app.rosaryguide.core.model.HapticKind.Success, hapticEnabled)
            return
        }
        goTo(index + 1, current)
    }

    fun goBack() {
        if (showingIntentionStep) {
            showingIntentionStep = false
            return
        }
        if (index > 0) {
            val from = steps.getOrNull(index)
            goTo(index - 1, from)
        }
    }

    fun completeDecade() {
        val current = steps.getOrNull(index) ?: return
        val decade = current.decadeNumber ?: return
        val closing = steps.indexOfFirst { it.closesDecade && it.decadeNumber == decade }
        if (closing < 0) return
        goTo(closing + 1, current, viaCompleteDecade = true)
    }

    fun toggleIntention(intention: OfferIntention) {
        val ids = selectedIds.toMutableList()
        val titles = selectedTitles.toMutableList()
        val pos = ids.indexOf(intention.id)
        if (pos >= 0) {
            ids.removeAt(pos)
            if (pos < titles.size) titles.removeAt(pos)
        } else if (ids.size < 5) {
            ids += intention.id
            titles += intention.title
        }
        selectedIds = ids
        selectedTitles = titles
        sessionStore.updateIntentions(ids, titles, intention.category, intention.sourceId)
        haptics.selection(hapticEnabled)
    }

    val current = steps.getOrNull(index)
    val isPlate = current?.isPlate == true
    val header = when {
        isPlate && current?.mystery != null ->
            "${current.stage.label}  ·  ${current.mystery!!.title.english}"
        else -> current?.mystery?.title?.english ?: launch.mysterySet.titleText.english
    }
    val showCompleteDecade = current?.kind == RosaryStepKind.HailMary &&
        (current.hailMaryNumber ?: 0) in 1..9 &&
        current.decadeNumber != null &&
        !showingIntentionStep &&
        !showingCompletion

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .statusBarsPadding()
            .navigationBarsPadding(),
    ) {
        if (showingCompletion) {
            CompletionScreen(
                mysterySet = launch.mysterySet,
                quote = completionQuote ?: QuoteCatalog.all.first(),
                intentionTitles = selectedTitles,
                includeSaintMichael = config.saintMichael,
                onDone = {
                    sessionStore.discard()
                    onClose()
                },
            )
            return@Box
        }

        Column(Modifier.fillMaxSize()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = RosarySpace.xs),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "Close",
                    style = RosaryType.body,
                    color = palette.accentText,
                    modifier = Modifier
                        .clickable(onClick = onClose)
                        .padding(RosarySpace.sm),
                )
                Spacer(Modifier.weight(1f))
                Text(
                    text = if (config.showBeads) "Hide beads" else "Show beads",
                    style = RosaryType.caption,
                    color = palette.accentText,
                    modifier = Modifier
                        .clickable {
                            config = config.copy(showBeads = !config.showBeads)
                            sessionStore.updateRosaryConfig(config)
                        }
                        .padding(RosarySpace.sm),
                )
            }
            GuideMarqueeText(
                text = header,
                style = if (isPlate) RosaryType.supportingLabel else RosaryType.headingPrimary,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = RosarySpace.gutter),
            )
            if (!isPlate) {
                current?.stage?.label?.let { label ->
                    Text(
                        text = label,
                        style = RosaryType.supportingLabel,
                        color = palette.dim,
                        modifier = Modifier.padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.xs),
                    )
                }
            }

            if (showingIntentionStep) {
                PrayIntentionSheet(
                    intentions = savedIntentions,
                    selectedIds = selectedIds,
                    onToggle = { toggleIntention(it) },
                    onClear = {
                        selectedIds = emptyList()
                        selectedTitles = emptyList()
                        sessionStore.updateIntentions(emptyList(), emptyList())
                    },
                    onAdd = { title ->
                        val added = sessionStore.addIntention(title)
                        toggleIntention(added)
                    },
                    onContinue = { advance() },
                    modifier = Modifier.weight(1f),
                )
            } else {
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .verticalScroll(rememberScrollState())
                        .then(if (isPlate) Modifier else Modifier.padding(horizontal = RosarySpace.gutter)),
                ) {
                    if (isPlate && current != null) {
                        MysteryPlate(step = current, language = language)
                    } else {
                        current?.title?.resolved(language)?.takeIf { it.isNotBlank() }?.let { title ->
                            Text(text = title, style = RosaryType.headingSecondary, color = palette.ink)
                            Spacer(Modifier.height(RosarySpace.sm))
                        }
                        current?.subtitle?.english?.takeIf { it.isNotBlank() }?.let { subtitle ->
                            Text(text = subtitle, style = RosaryType.supportingLabel, color = palette.dim)
                            Spacer(Modifier.height(RosarySpace.sm))
                        }
                        current?.body?.let { body ->
                            Text(text = body.primary(language), style = RosaryType.serifBody, color = palette.ink)
                            body.secondary(language)?.let { latin ->
                                Spacer(Modifier.height(RosarySpace.md))
                                Text(text = latin, style = RosaryType.serifItalicBody, color = palette.dim)
                            }
                        }
                    }
                    Spacer(Modifier.height(RosarySpace.lg))
                    Box(Modifier.padding(horizontal = if (isPlate) RosarySpace.gutter else 0.dp)) {
                        LanguageChips(language) { language = it }
                    }
                    Spacer(Modifier.height(RosarySpace.xl))
                }
            }

            if (config.showBeads && !showingIntentionStep && !isPlate) {
                BeadRail(current = current?.bead, modifier = Modifier.fillMaxWidth())
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = RosarySpace.gutter, vertical = RosarySpace.sm),
                horizontalArrangement = Arrangement.spacedBy(RosarySpace.sm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (index > 0 || showingIntentionStep) {
                    Box(Modifier.weight(1f)) {
                        GuideSecondaryButton(title = "Back", onClick = { goBack() })
                    }
                }
                Box(Modifier.weight(1f)) {
                    GuidePrimaryButton(
                        title = if (current?.isLastPrayer == true) "Finish" else "Next",
                        onClick = { advance() },
                    )
                }
            }
            if (showCompleteDecade) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = RosarySpace.gutter)
                        .padding(bottom = RosarySpace.md),
                ) {
                    GuideSecondaryButton(title = "Complete decade", onClick = { completeDecade() })
                }
            }
        }
    }
}

@Composable
private fun LanguageChips(
    language: PrayerLanguage,
    onChange: (PrayerLanguage) -> Unit,
) {
    val palette = LocalThemePalette.current
    Row(horizontalArrangement = Arrangement.spacedBy(RosarySpace.sm)) {
        PrayerLanguage.entries.forEach { option ->
            val selected = option == language
            Text(
                text = option.chip,
                style = RosaryType.caption,
                color = if (selected) palette.accentText else palette.dim,
                modifier = Modifier
                    .widthIn(min = 44.dp)
                    .clickable { onChange(option) }
                    .padding(vertical = RosarySpace.xs, horizontal = RosarySpace.sm),
            )
        }
    }
}
