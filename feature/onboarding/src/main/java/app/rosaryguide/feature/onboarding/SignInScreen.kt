package app.rosaryguide.feature.onboarding

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.withLink
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import app.rosaryguide.core.data.catalog.OnboardingCopy
import app.rosaryguide.core.designsystem.R
import app.rosaryguide.core.designsystem.component.GuideGoogleButton
import app.rosaryguide.core.designsystem.component.GuideTertiaryButton
import app.rosaryguide.core.designsystem.theme.LocalThemePalette
import app.rosaryguide.core.designsystem.theme.RosarySpace
import app.rosaryguide.core.designsystem.theme.RosaryType
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import app.rosaryguide.core.designsystem.component.LocalReduceMotion
import app.rosaryguide.core.designsystem.theme.ThemePalette

@Composable
fun SignInScreen(
    onGoogle: () -> Unit,
    onGuest: () -> Unit,
    modifier: Modifier = Modifier,
    isSigningInWithGoogle: Boolean = false,
) {
    val palette = LocalThemePalette.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .navigationBarsPadding(),
    ) {
        BoxWithConstraints(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f),
        ) {
            val statusTop = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
            val panelHeight = RosarySpace.signInPanelHeight(maxHeight) + statusTop
            val reduceMotion = LocalReduceMotion.current
            Box(
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .offset(y = -statusTop)
                    .padding(horizontal = RosarySpace.panelInset)
                    .fillMaxWidth()
                    .height(panelHeight)
                    .clip(RoundedCornerShape(bottomStart = RosarySpace.panelRadius, bottomEnd = RosarySpace.panelRadius))
                    .background(ThemePalette.brandCanvas(palette.isDark)),
                contentAlignment = Alignment.BottomCenter,
            ) {
                RosaryBeadsFallPlayer(
                    plays = !reduceMotion,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 40.dp),
                )
            }
        }
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = RosarySpace.gutter)
                .padding(top = RosarySpace.xl, bottom = RosarySpace.lg),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = OnboardingCopy.signInQuote,
                style = RosaryType.headingPrimary,
                color = palette.ink,
                textAlign = TextAlign.Center,
                modifier = Modifier.semantics {
                    contentDescription = OnboardingCopy.signInQuoteAccessibilityLabel
                },
            )
            Spacer(Modifier.height(RosarySpace.md))
            Text(
                text = OnboardingCopy.signInQuoteAttribution,
                style = RosaryType.body,
                color = palette.dim,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(RosarySpace.xl))
            GuideGoogleButton(
                title = if (isSigningInWithGoogle) OnboardingCopy.SIGNING_IN else OnboardingCopy.CONTINUE_WITH_GOOGLE,
                enabled = !isSigningInWithGoogle,
                onClick = onGoogle,
            )
            Spacer(Modifier.height(RosarySpace.md))
            Text(
                text = OnboardingCopy.CONTINUE_AS_GUEST,
                style = RosaryType.body.copy(textDecoration = TextDecoration.Underline),
                color = palette.ink,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .clickable(enabled = !isSigningInWithGoogle, onClick = onGuest)
                    .padding(horizontal = RosarySpace.md, vertical = RosarySpace.sm)
                    .semantics { contentDescription = "Continue as guest. You can sign in later in Settings" },
            )
            Spacer(Modifier.height(RosarySpace.lg))
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
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}
