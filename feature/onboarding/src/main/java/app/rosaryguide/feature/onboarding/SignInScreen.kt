package app.rosaryguide.feature.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withLink
import androidx.compose.ui.text.withStyle
import app.rosaryguide.core.data.catalog.OnboardingCopy
import app.rosaryguide.core.designsystem.component.GuideGoogleButton
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import app.rosaryguide.core.designsystem.theme.ThemePalette

@Composable
fun SignInScreen(
    onGoogle: () -> Unit,
    onGuest: () -> Unit,
    modifier: Modifier = Modifier,
    isSigningInWithGoogle: Boolean = false,
) {
    val palette = LocalThemePalette.current
    val reduceMotion = LocalReduceMotion.current
    BoxWithConstraints(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg),
    ) {
        // 50% of the full window from y=0, not of the leftover space above the quote.
        val panelHeight = RosarySpace.signInPanelHeight(maxHeight)
        val beadsWidth = RosarySpace.signInBeadsWidth(panelHeight)
        Column(modifier = Modifier.fillMaxSize()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(panelHeight)
                    .padding(horizontal = RosarySpace.panelInset)
                    .clip(
                        RoundedCornerShape(
                            bottomStart = RosarySpace.panelRadius,
                            bottomEnd = RosarySpace.panelRadius,
                        ),
                    )
                    .background(ThemePalette.brandCanvas(palette.isDark)),
            ) {
                RosaryBeadsFallPlayer(
                    plays = !reduceMotion,
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .width(beadsWidth)
                        .padding(bottom = RosarySpace.signInLoopBottomPadding),
                )
            }
            // Bottom-aligned like iOS signInLowerContent(spacious: true). Apple is omitted on
            // Android, so an invisible pill is reserved so the quote, Google, and guest stay
            // at the iOS Y instead of shifting up to fill the gap.
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .navigationBarsPadding(),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Spacer(Modifier.weight(1f).heightIn(min = RosarySpace.lg))
                Text(
                    text = OnboardingCopy.signInQuote,
                    style = RosaryType.headingPrimary,
                    color = palette.ink,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .padding(horizontal = RosarySpace.gutter)
                        .semantics {
                            contentDescription = OnboardingCopy.signInQuoteAccessibilityLabel
                        },
                )
                Spacer(Modifier.height(RosarySpace.md))
                Text(
                    text = OnboardingCopy.signInQuoteAttribution,
                    style = RosaryType.body,
                    color = palette.dim,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = RosarySpace.gutter),
                )
                Spacer(Modifier.height(RosarySpace.xl))
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = RosarySpace.gutter)
                        .padding(bottom = RosarySpace.xl),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Spacer(Modifier.height(RosarySpace.pillHeight + RosarySpace.md))
                    GuideGoogleButton(
                        title = if (isSigningInWithGoogle) OnboardingCopy.SIGNING_IN else OnboardingCopy.CONTINUE_WITH_GOOGLE,
                        enabled = !isSigningInWithGoogle,
                        onClick = onGoogle,
                    )
                    Text(
                        text = OnboardingCopy.CONTINUE_AS_GUEST,
                        style = RosaryType.body.copy(textDecoration = TextDecoration.Underline),
                        color = palette.ink,
                        textAlign = TextAlign.Center,
                        modifier = Modifier
                            .clickable(enabled = !isSigningInWithGoogle, onClick = onGuest)
                            .padding(horizontal = RosarySpace.md, vertical = RosarySpace.sm)
                            .padding(top = RosarySpace.xs)
                            .semantics { contentDescription = "Continue as guest. You can sign in later in Settings" },
                    )
                    val legal = buildAnnotatedString {
                        append(OnboardingCopy.LEGAL_PREFIX)
                        withLink(LinkAnnotation.Url(OnboardingCopy.TERMS_URL)) {
                            withStyle(SpanStyle(color = palette.ink, textDecoration = TextDecoration.Underline)) {
                                append(OnboardingCopy.TERMS_LABEL)
                            }
                        }
                        append(" and ")
                        withLink(LinkAnnotation.Url(OnboardingCopy.PRIVACY_URL)) {
                            withStyle(SpanStyle(color = palette.ink, textDecoration = TextDecoration.Underline)) {
                                append(OnboardingCopy.PRIVACY_LABEL)
                            }
                        }
                        append(".")
                    }
                    Text(
                        text = legal,
                        style = RosaryType.caption.copy(color = palette.dim, textAlign = TextAlign.Center),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = RosarySpace.sm),
                    )
                }
            }
        }
    }
}
