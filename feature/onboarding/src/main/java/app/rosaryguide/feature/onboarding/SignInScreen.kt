package app.rosaryguide.feature.onboarding

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.ClickableText
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.SpanStyle
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

@Composable
fun SignInScreen(
    onGoogle: () -> Unit,
    onGuest: () -> Unit,
    modifier: Modifier = Modifier,
    isSigningInWithGoogle: Boolean = false,
) {
    val palette = LocalThemePalette.current
    val context = LocalContext.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(palette.bg)
            .navigationBarsPadding(),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f),
        ) {
            Image(
                painter = painterResource(R.drawable.onboarding_sign_in),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                alignment = Alignment.TopCenter,
                modifier = Modifier.fillMaxSize(),
            )
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
                style = RosaryType.serifTitle,
                color = palette.ink,
                textAlign = TextAlign.Center,
                modifier = Modifier.semantics {
                    contentDescription = OnboardingCopy.signInQuoteAccessibilityLabel
                },
            )
            Spacer(Modifier.height(RosarySpace.sm))
            Text(
                text = OnboardingCopy.signInQuoteAttribution,
                style = RosaryType.caption,
                color = palette.dim,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(RosarySpace.xl))
            GuideGoogleButton(
                title = if (isSigningInWithGoogle) OnboardingCopy.SIGNING_IN else OnboardingCopy.CONTINUE_WITH_GOOGLE,
                enabled = !isSigningInWithGoogle,
                onClick = onGoogle,
            )
            Spacer(Modifier.height(RosarySpace.sm))
            GuideTertiaryButton(
                title = OnboardingCopy.CONTINUE_AS_GUEST,
                enabled = !isSigningInWithGoogle,
                onClick = onGuest,
            )
            Spacer(Modifier.height(RosarySpace.lg))
            val legal = buildAnnotatedString {
                append(OnboardingCopy.LEGAL_PREFIX)
                pushStringAnnotation("url", OnboardingCopy.TERMS_URL)
                withStyle(SpanStyle(color = palette.accentText, textDecoration = TextDecoration.Underline)) {
                    append(OnboardingCopy.TERMS_LABEL)
                }
                pop()
                append(" and ")
                pushStringAnnotation("url", OnboardingCopy.PRIVACY_URL)
                withStyle(SpanStyle(color = palette.accentText, textDecoration = TextDecoration.Underline)) {
                    append(OnboardingCopy.PRIVACY_LABEL)
                }
                pop()
                append(".")
            }
            ClickableText(
                text = legal,
                style = RosaryType.caption.copy(color = palette.dim, textAlign = TextAlign.Center),
                modifier = Modifier.fillMaxWidth(),
                onClick = { offset ->
                    legal.getStringAnnotations("url", offset, offset).firstOrNull()?.let { annotation ->
                        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(annotation.item)))
                    }
                },
            )
        }
    }
}
