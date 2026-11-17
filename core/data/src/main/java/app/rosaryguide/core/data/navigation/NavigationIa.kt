package app.rosaryguide.core.data.navigation

import app.rosaryguide.core.data.catalog.FeastNarratives
import app.rosaryguide.core.data.launch.LaunchGate
import app.rosaryguide.core.model.DatedFeast
import app.rosaryguide.core.model.Feast
import java.time.LocalDate

/**
 * Routing decisions that must match the iOS information architecture.
 * UI layers present these destinations with Material 3 equivalents
 * (ModalBottomSheet, NavHost push, full-screen overlay).
 */
object NavigationIa {
    enum class JourneySheet { PrayerDetail, DayDetail }

    /** History list rows open the prayer-detail sheet, not the day sheet. */
    fun journeySheetForHistoryRow(): JourneySheet = JourneySheet.PrayerDetail

    /** Calendar day taps open the day sheet. */
    fun journeySheetForCalendarDay(): JourneySheet = JourneySheet.DayDetail

    sealed class WeekDayAction {
        data class SelectDay(val date: LocalDate) : WeekDayAction()
        data class OpenWeekFeastSheet(val feast: DatedFeast) : WeekDayAction()
    }

    fun weekDayAction(date: LocalDate, feast: DatedFeast?): WeekDayAction =
        if (feast != null) WeekDayAction.OpenWeekFeastSheet(feast) else WeekDayAction.SelectDay(date)

    fun weekFeastDescription(feast: Feast): String = when (feast.id) {
        "michael" ->
            "The Church celebrates the three archangels named in Scripture: Michael, defender against evil; Gabriel, messenger of the Annunciation; and Raphael, healer and guide. This feast honors God’s angelic servants and their work in salvation history."
        "guardian-angels" ->
            "The Church gives thanks for the guardian angels, whom God entrusts to watch over and guide His people. This memorial celebrates God’s personal care for each soul through these unseen companions."
        else -> FeastNarratives.narrative(feast.id)?.about ?: feast.summary
    }

    /** Sign out and (once M5 ships) delete account return the user to onboarding. */
    const val ONBOARDING_COMPLETED_AFTER_SIGN_OUT = false

    fun showsAppAfterSignOut(): Boolean = LaunchGate.showsApp(
        didCompleteOnboarding = ONBOARDING_COMPLETED_AFTER_SIGN_OUT,
        isSignedIn = false,
    )

    enum class SettingsEntry { ProfileGear, Today, Tab }

    /** Settings opens only from the Profile gear, never from Today or a tab. */
    fun isSettingsEntryAllowed(entry: SettingsEntry): Boolean = entry == SettingsEntry.ProfileGear

    enum class SettingsRootClose { Back, Close }

    fun settingsRootClose(): SettingsRootClose = SettingsRootClose.Back

    sealed class ProfileEditorPresentation { data object Sheet : ProfileEditorPresentation(); data object FullScreenPage : ProfileEditorPresentation() }

    fun profileEditorPresentation(): ProfileEditorPresentation = ProfileEditorPresentation.Sheet

    enum class FeastSecondaryPage { RelatedPrayers, Patronages, Scripture }

    /**
     * Live iOS feast detail inlines related prayers and scripture on the detail
     * page (Keep the day too). The FeastSecondaryPage types exist in iOS source
     * but are not mounted, so Android stays in-page as well.
     */
    fun feastSecondaryPagesArePushes(): Boolean = false

    enum class LearnSearchDestination { Prayer, MysterySet, Feast, HowToPray, Article }

    fun isLiveLearnSearchDestination(destination: LearnSearchDestination): Boolean =
        destination == LearnSearchDestination.Prayer ||
            destination == LearnSearchDestination.MysterySet ||
            destination == LearnSearchDestination.Feast

    enum class SignInOrigin { Profile, Settings }

    enum class AfterSignInLanding { TodayClearingStacks, StayOnSettings, StayOnProfile }

    fun afterSignIn(origin: SignInOrigin): AfterSignInLanding = when (origin) {
        SignInOrigin.Profile -> AfterSignInLanding.TodayClearingStacks
        SignInOrigin.Settings -> AfterSignInLanding.StayOnSettings
    }

    /** Replay welcome is a full-screen overlay on top of Settings; finishing returns there. */
    const val REPLAY_WELCOME_KEEPS_SETTINGS = true

    /** Notification taps open the app at LaunchGate (usually Today), with no custom destination. */
    const val NOTIFICATION_TAP_OPENS_LAUNCHER = true
    const val NOTIFICATION_TAP_HAS_CUSTOM_DESTINATION = false

    /** Delete account stays stubbed until M5 Firebase sync. */
    const val DELETE_ACCOUNT_STUBBED_UNTIL_M5 = true

    /** Theme Gallery is a debug tool, not a product entry. */
    const val THEME_GALLERY_EXPORTED = false

    /** In-Pray Add / Edit intention is a nested sheet, not an in-place composer. */
    enum class PrayAddIntentionPresentation { NestedSheet, InPlaceComposer }

    fun prayAddIntentionPresentation(): PrayAddIntentionPresentation =
        PrayAddIntentionPresentation.NestedSheet
}
