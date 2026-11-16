package app.rosaryguide.core.data.catalog

/**
 * Onboarding and sign-in copy, ported from iOS `OnboardingPage` / `OnboardingCopy`.
 * Android v1 sign-in is Google + guest only; there is no Apple button.
 */
data class OnboardingPage(
    val title: String,
    val body: String,
    val imageName: String,
    /** `top` or `center`, matching iOS `imageAlignment`. */
    val imageAlignment: String = "top",
) {
    companion object {
        val pages: List<OnboardingPage> = listOf(
            OnboardingPage(
                title = "Make room\nfor prayer.",
                body = "Slow down and draw closer to God\nthrough the Rosary.",
                imageName = "OnboardingRosaryDaily",
            ),
            OnboardingPage(
                title = "Every prayer,\ngently guided.",
                body = "New to the Rosary? Follow along,\none bead at a time.",
                imageName = "OnboardingBeads",
                imageAlignment = "center",
            ),
            OnboardingPage(
                title = "Bring what’s\non your heart.",
                body = "Pray for the people you love\nand the intentions you carry.",
                imageName = "OnboardingIntentions",
            ),
        )
    }
}

object OnboardingCopy {
    const val CONTINUE = "Continue"
    const val BEGIN = "Begin"
    const val CONTINUE_WITH_GOOGLE = "Continue with Google"
    const val SIGNING_IN = "Signing in"
    const val CONTINUE_AS_GUEST = "Continue as guest"
    const val GUEST_ACCESSIBILITY =
        "Continue as guest. You can sign in later in Settings"
    const val SIGN_IN_QUOTE_TEXT = "A chain that links heaven and earth"
    const val SIGN_IN_QUOTE_AUTHOR = "St Thérèse of Lisieux"
    const val LEGAL_PREFIX = "By continuing you agree to our\n"
    const val TERMS_LABEL = "Terms & Conditions"
    const val TERMS_URL = "https://xult.ltd/terms/"
    const val PRIVACY_LABEL = "Privacy Policy"
    const val PRIVACY_URL = "https://xult.ltd/privacy/"

    /** Displayed quote, typographic quotes and a line break as on iOS. */
    val signInQuote: String = "\u201C" + "A chain that links\nheaven and earth" + "\u201D"

    val signInQuoteAttribution: String
        get() = "Attributed to $SIGN_IN_QUOTE_AUTHOR"

    val signInQuoteAccessibilityLabel: String
        get() = "$SIGN_IN_QUOTE_TEXT, attributed to $SIGN_IN_QUOTE_AUTHOR"

    /** Android v1 providers — never includes Apple. */
    val providers: List<String> = listOf("google", "guest")
}
