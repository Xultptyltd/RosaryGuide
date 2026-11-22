package app.rosaryguide.feature.pray

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.catalog.QuoteCatalog
import app.rosaryguide.core.data.sequence.RosaryHaptics
import app.rosaryguide.core.data.sequence.RosarySequenceBuilder
import app.rosaryguide.core.data.session.OfferIntention
import app.rosaryguide.core.data.session.SessionStore
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.feature.profile.IntentionEditorScreen
import app.rosaryguide.core.model.CompletionQuote
import app.rosaryguide.core.model.MysterySetKind
import app.rosaryguide.core.model.PrayTrackStage
import app.rosaryguide.core.model.PrayerLanguage
import app.rosaryguide.core.model.RosaryConfig
import app.rosaryguide.core.model.RosaryStep
import app.rosaryguide.core.model.RosaryStepKind
import app.rosaryguide.feature.settings.CustomiseRosaryScreen
import androidx.compose.runtime.snapshotFlow
import app.rosaryguide.core.data.motion.ScrollMorph
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.theme.MotionTokens
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.animate

data class PrayLaunch(
    val mysterySet: MysterySetKind,
    val startStep: Int? = null,
    val showIntentions: Boolean = false,
    val showCompletion: Boolean = false,
    val showSaintMichael: Boolean = false,
    val showCustomise: Boolean = false,
    val forceFresh: Boolean = false,
    val isResume: Boolean = false,
    val showReplaceDialog: Boolean = false,
    val config: RosaryConfig = RosaryConfig.default,
    val seedIntentions: List<Pair<String, String>> = emptyList(),
    val completionQuoteId: String? = null,
    /** Scroll the mystery plate to the end so Fruit sits above the scroll circle. */
    val scrollPlateToEnd: Boolean = false,
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrayScreen(
    launch: PrayLaunch,
    sessionStore: SessionStore,
    quotePreferences: app.rosaryguide.core.data.catalog.QuotePreferences,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    hapticEnabled: Boolean = true,
    settingsConfig: RosaryConfig = launch.config,
    onRosaryConfigChange: (RosaryConfig) -> Unit = {},
    onReadyForReview: () -> Unit = {},
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    val haptics = remember { HapticPlayer(context) }
    val saved by sessionStore.session.collectAsState()
    val savedIntentions by sessionStore.intentions.collectAsState()

    var config by remember { mutableStateOf(launch.config) }
    var steps by remember { mutableStateOf(RosarySequenceBuilder.build(launch.mysterySet, launch.config)) }
    var index by remember { mutableIntStateOf(launch.startStep ?: 0) }
    var showingIntentionStep by remember { mutableStateOf(launch.showIntentions) }
    var showingCompletion by remember { mutableStateOf(launch.showCompletion || launch.showSaintMichael) }
    var showingMichael by remember { mutableStateOf(launch.showSaintMichael) }
    var celebrated by remember { mutableStateOf(setOf<Int>()) }
    var language by remember { mutableStateOf(PrayerLanguage.English) }
    var selectedIds by remember { mutableStateOf(listOf<String>()) }
    var selectedTitles by remember { mutableStateOf(listOf<String>()) }
    var completionQuote by remember { mutableStateOf<CompletionQuote?>(null) }
    var lastAdvanceAt by remember { mutableStateOf(0L) }
    var showCustomise by remember { mutableStateOf(launch.showCustomise) }
    var showComposer by remember { mutableStateOf(false) }
    var confirmReplace by remember { mutableStateOf(launch.showReplaceDialog) }
    val prayerScroll = rememberScrollState()
    val reduceMotion = LocalReduceMotion.current
    var actionLocked by remember { mutableStateOf(false) }
    var arrowArmed by remember { mutableStateOf(false) }
    var lastDragAtMs by remember { mutableStateOf(0L) }
    val showScrollCircle = prayerScroll.maxValue > ScrollMorph.minimumOffset && !actionLocked
    val scope = rememberCoroutineScope()


    LaunchedEffect(launch) {
        haptics.prepare(hapticEnabled)
        launch.seedIntentions.forEach { (id, title) ->
            if (savedIntentions.none { it.id == id || it.title == title }) {
                sessionStore.addIntention(title)
            }
        }
        val existing = saved?.takeIf { it.isResumable(System.currentTimeMillis()) }
        val shouldAsk = existing != null &&
            !launch.forceFresh &&
            !launch.isResume &&
            !launch.showCompletion &&
            !launch.showSaintMichael &&
            !launch.showCustomise &&
            launch.startStep == null
        if (shouldAsk || launch.showReplaceDialog) {
            // Keep the opening step visible under the dimmed alert, like iOS.
            config = launch.config
            steps = RosarySequenceBuilder.build(launch.mysterySet, launch.config)
            index = 0
            confirmReplace = true
            return@LaunchedEffect
        }
        if (launch.isResume && !launch.forceFresh && !launch.showCompletion && !launch.showSaintMichael && existing != null) {
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
        if (launch.showCompletion || launch.showSaintMichael) {
            completionQuote = launch.completionQuoteId?.let { id ->
                QuoteCatalog.all.firstOrNull { it.id == id }
            } ?: QuoteCatalog.freshCompletionQuote(quotePreferences)
            showingCompletion = true
        }
        showingMichael = launch.showSaintMichael
        showCustomise = launch.showCustomise
    }

    DisposableEffect(Unit) {
        onDispose { }
    }

    LaunchedEffect(index, showingIntentionStep) {
        actionLocked = false
        arrowArmed = false
        prayerScroll.scrollTo(0)
    }

    LaunchedEffect(prayerScroll) {
        var lastY = prayerScroll.value
        snapshotFlow { prayerScroll.value to prayerScroll.maxValue }.collect { (value, max) ->
            val y = value.toFloat()
            val maxOffset = max.toFloat()
            if (kotlin.math.abs(value - lastY) > 0.5f && !arrowArmed) {
                lastDragAtMs = System.currentTimeMillis()
            }
            lastY = value
            if (!launch.scrollPlateToEnd) {
                val next = ScrollMorph.resolve(actionLocked, arrowArmed, y, maxOffset)
                if (next.locked != actionLocked) actionLocked = next.locked
                if (next.armed != arrowArmed) arrowArmed = next.armed
            }
        }
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
        if (from?.closesDecade == true) {
            from.decadeNumber?.let { sessionStore.recordCompletedDecadeIfNeeded(it) }
        }
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
            if (current.closesDecade) current.decadeNumber?.let { sessionStore.recordCompletedDecadeIfNeeded(it) }
            if (completionQuote == null) completionQuote = QuoteCatalog.freshCompletionQuote(quotePreferences)
            showingCompletion = true
            sessionStore.complete()
            return
        }
        if (current?.isLastPrayer == true) {
            if (current.closesDecade) current.decadeNumber?.let { sessionStore.recordCompletedDecadeIfNeeded(it) }
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
        goTo(closing, current, viaCompleteDecade = true)
    }

    fun jumpTo(stage: PrayTrackStage) {
        val target = steps.indexOfFirst { it.stage == stage }
        if (target >= 0) goTo(target, steps.getOrNull(index))
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
    val canRetreat = index > 0 || showingIntentionStep
    val showCompleteDecade = current?.kind == RosaryStepKind.HailMary &&
        (current.hailMaryNumber ?: 0) in 1..9 &&
        current.decadeNumber != null &&
        !showingIntentionStep &&
        !showingCompletion
    val showBeads = config.showBeads &&
        language != PrayerLanguage.Bilingual &&
        !showingIntentionStep &&
        !isPlate &&
        current?.isFinis != true
    val progressLabel = when {
        showingIntentionStep -> current?.progressLabel ?: "Opening prayers"
        else -> current?.progressLabel ?: launch.mysterySet.titleText.english
    }
    val nextTitle = current?.nextLabel ?: "Next"
    val screenHeight = LocalConfiguration.current.screenHeightDp.dp
    // 0.62 matches the iOS plate's visible art bottom (~0.558 after the fade)
    // on Pixel 7, so the scripture + Fruit overflow and the scroll circle appears.
    val plateArtHeight = screenHeight * 0.62f
    // iOS textTop = imageBottom + Space.xl; reading already starts with Space.md.
    val plateHeroSpacer = plateArtHeight + RosarySpace.xl - RosarySpace.md
    // iOS plateEndSpacer + text padding: last line (Fruit) sits
    // `prayerReadingContentToActionGap` (48) above the floating action
    // (pill 52 + Space.lg). Android also clears navigationBars because the
    // footer is padded by them. ScrollMorph.tailPadding then guarantees at
    // least a 56 dp scroll range so the collapsed circle can appear.
    val navBottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
    // Action clearance + 48 dp reading gap + nav, plus ScrollMorph.minimumRange
    // so a Pixel 7's slightly taller frame still overflows like the iPhone ref.
    val plateTail = 52.dp + RosarySpace.lg + 48.dp + navBottom + ScrollMorph.minimumRange.dp
    val plateTailForShot = plateTail
    val plateScrollLeftoverPx = with(androidx.compose.ui.platform.LocalDensity.current) { 57.dp.toPx() }

    // Reproduce the iOS plate ref: Fruit is visible above a collapsed scroll
    // circle. Scrolling all the way to max would trip ScrollMorph.expandGap and
    // morph the control into the Next pill, so stop just short of that threshold.
    LaunchedEffect(isPlate, launch.scrollPlateToEnd, index, showingIntentionStep) {
        if (!launch.scrollPlateToEnd || !isPlate) return@LaunchedEffect
        snapshotFlow { prayerScroll.maxValue }
            .first { it > ScrollMorph.minimumOffset.toInt() }
        val target = (prayerScroll.maxValue - plateScrollLeftoverPx).toInt().coerceAtLeast(0)
        actionLocked = false
        prayerScroll.scrollTo(target)
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(palette.prayBg),
    ) {

        if (confirmReplace) {
            AlertDialog(
                onDismissRequest = {
                    confirmReplace = false
                    onClose()
                },
                title = { Text("Start a new rosary?") },
                text = {
                    Text("You already have a rosary in progress today. Starting fresh will replace it once you move past the first step.")
                },
                confirmButton = {
                    TextButton(
                        onClick = {
                            confirmReplace = false
                            config = launch.config
                            steps = RosarySequenceBuilder.build(launch.mysterySet, launch.config)
                            val started = sessionStore.start(launch.mysterySet, language, config = launch.config)
                            selectedIds = started.intentionIds
                            selectedTitles = started.intentionTitles
                            index = 0
                            celebrated = emptySet()
                        },
                    ) { Text("Replace saved place") }
                },
                dismissButton = {
                    TextButton(onClick = {
                        confirmReplace = false
                        onClose()
                    }) { Text("Cancel") }
                },
            )
        }

        when {
            showingMichael -> {
                SaintMichaelScreen(
                    onDone = { showingMichael = false },
                    onClose = { showingMichael = false },
                    initialLanguage = language,
                    modifier = Modifier.fillMaxSize(),
                )
            }
            showingCompletion -> {
                CompletionScreen(
                    mysterySet = launch.mysterySet,
                    quote = completionQuote ?: QuoteCatalog.all.first(),
                    intentionTitles = selectedTitles,
                    includeSaintMichael = true,
                    onDone = {
                        sessionStore.discard()
                        onClose()
                    },
                    onMichael = { showingMichael = true },
                    onReadyForReview = onReadyForReview,
                    modifier = Modifier.fillMaxSize(),
                )
            }
            else -> {
                val header: @Composable () -> Unit = {
                    Column(Modifier.statusBarsPadding()) {
                        PrayFlowHeader(
                            progressLabel = progressLabel,
                            canRetreat = canRetreat,
                            onBack = { goBack() },
                            onSettings = { showCustomise = true },
                            onClose = onClose,
                        )
                        current?.stage?.let { stage ->
                            SevenStageTrack(current = stage, onJump = { jumpTo(it) })
                        }
                    }
                }
                val footer: @Composable () -> Unit = {
                    if (showingIntentionStep) {
                        IntentionActionFooter(
                            onAdd = { showComposer = true },
                            onNext = { advance() },
                            modifier = Modifier.navigationBarsPadding(),
                        )
                    } else {
                        PrayActionFooter(
                            nextTitle = nextTitle,
                            showCompleteDecade = showCompleteDecade,
                            showLanguage = !isPlate,
                            language = language,
                            onNext = { advance() },
                            onCompleteDecade = { completeDecade() },
                            onLanguageChange = { language = it },
                            modifier = Modifier.navigationBarsPadding(),
                            showScroll = showScrollCircle,
                            resetKey = index,
                            onScroll = {
                                val now = System.currentTimeMillis()
                                if (now - lastDragAtMs > 250L) {
                                    val maxOffset = prayerScroll.maxValue
                                    arrowArmed = (maxOffset - prayerScroll.value) > ScrollMorph.minimumOffset
                                    actionLocked = true
                                    scope.launch {
                                        prayerScroll.animateScrollTo(maxOffset)
                                        arrowArmed = false
                                    }
                                }
                            },
                        )
                    }
                }

                if (isPlate && current != null) {
                    Box(Modifier.fillMaxSize()) {
                        // Fixed hero, matching iOS plateHeroImage. Only the
                        // reading scrolls, so Fruit can rise without the
                        // painting leaving the top of the frame.
                        MysteryPlateArt(
                            step = current,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(plateArtHeight),
                        )
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .verticalScroll(prayerScroll),
                        ) {
                            Spacer(Modifier.height(plateHeroSpacer))
                            MysteryPlateReading(
                                step = current,
                                language = language,
                            )
                            Spacer(Modifier.height(plateTailForShot))
                        }
                        header()
                        Box(Modifier.align(Alignment.BottomCenter).fillMaxWidth()) { footer() }
                    }
                } else {
                    Column(
                        Modifier
                            .fillMaxSize()
                            .navigationBarsPadding(),
                    ) {
                        header()
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
                                onAdd = { _ -> showComposer = true },
                                // Measured iOS track-to-title gap is 0.0565 of the frame;
                                // Android was 0.0792 (21 dp too low). Nudge the block up.
                                modifier = Modifier.weight(1f).offset(y = (-21).dp),
                            )
                        } else {
                            val pinTop = current?.kind == RosaryStepKind.Creed
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .fillMaxWidth(),
                                contentAlignment = if (pinTop) Alignment.TopStart else Alignment.CenterStart,
                            ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .verticalScroll(prayerScroll)
                                    .padding(horizontal = RosarySpace.gutter),
                            ) {
                                current?.let { step ->
                                    if (step.kind == RosaryStepKind.HailMary &&
                                        step.decadeNumber != null &&
                                        step.hailMaryNumber != null
                                    ) {
                                        Text(
                                            text = "${step.hailMaryNumber} of 10",
                                            style = RosaryType.caption.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Medium),
                                            color = palette.dim,
                                        )
                                        Spacer(Modifier.height(RosarySpace.sm))
                                    }
                                    step.title.resolved(language).takeIf { it.isNotBlank() }?.let { title ->
                                        Text(text = title, style = RosaryType.modalTitle, color = palette.ink)
                                        val titleGap = if (step.kind == RosaryStepKind.SignOfTheCross) {
                                            RosarySpace.lg
                                        } else {
                                            RosarySpace.prayerTitleBodyGap
                                        }
                                        Spacer(Modifier.height(titleGap))
                                    }
                                    if (language == PrayerLanguage.Bilingual) {
                                        step.title.latin.takeIf { it.isNotBlank() && it != step.title.english }?.let { latin ->
                                            Text(text = latin, style = RosaryType.body, color = palette.dim)
                                            Spacer(Modifier.height(RosarySpace.sm))
                                        }
                                    }
                                    step.body.let { body ->
                                        Text(
                                            text = body.primary(language),
                                            style = RosaryType.prayerText,
                                            color = palette.ink,
                                        )
                                        body.secondary(language)?.let { latin ->
                                            Spacer(Modifier.height(RosarySpace.md))
                                            Text(text = latin, style = RosaryType.serifItalicBody, color = palette.dim)
                                        }
                                    }
                                }
                                Spacer(Modifier.height(RosarySpace.lg))
                            }
                            }
                        }
                        if (showBeads) {
                            BeadRail(current = current?.bead, modifier = Modifier.fillMaxWidth())
                        }
                        footer()
                    }
                }
            }
        }

        if (showComposer) {
            val paletteSheet = LocalThemePalette.current
            ModalBottomSheet(
                onDismissRequest = { showComposer = false },
                sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
                containerColor = paletteSheet.bg,
            ) {
                IntentionEditorScreen(
                    existing = null,
                    onBack = { showComposer = false },
                    onSave = { draft ->
                        val added = sessionStore.addIntention(
                            title = draft.title,
                            note = draft.note,
                            category = draft.category,
                            accent = draft.accent,
                            emoji = draft.emoji,
                            pin = draft.isPinned,
                        )
                        toggleIntention(added)
                        showComposer = false
                    },
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }

        if (showCustomise) {
            val statusTop = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
            // Modal windows in the Roborazzi harness may not see the test
            // status-bar inset (0 dp); fall back to the real Pixel 7 value
            // so the large detent sits just below 9:41, like iOS.
            val sheetTopGap = if (statusTop > 0.dp) statusTop else 52.57.dp
            ModalBottomSheet(
                onDismissRequest = { showCustomise = false },
                sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
                modifier = Modifier.padding(top = sheetTopGap),
            ) {
                // iOS uses presentationDetents([.large]) — just below the
                // status bar — not a 75% peek.
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .fillMaxHeight()
                        .padding(bottom = RosarySpace.md),
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = RosarySpace.gutter),
                    ) {
                        Text(
                            text = "Customise rosary",
                            style = RosaryType.navigationTitle,
                            color = palette.ink,
                            modifier = Modifier.align(Alignment.Center),
                        )
                        TextButton(
                            onClick = { showCustomise = false },
                            modifier = Modifier.align(Alignment.CenterEnd),
                        ) {
                            Text("Done")
                        }
                    }
                    CustomiseRosaryScreen(
                        config = settingsConfig.copy(showBeads = config.showBeads),
                        onConfigChange = { next ->
                            onRosaryConfigChange(next)
                            config = config.copy(showBeads = next.showBeads)
                            sessionStore.updateRosaryConfig(config)
                        },
                        onBack = { showCustomise = false },
                        showChrome = false,
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f),
                    )
                }
            }
        }
    }
}
