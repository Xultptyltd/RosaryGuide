package app.rosaryguide.sync

import android.content.Context
import android.util.Log
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import app.rosaryguide.core.data.auth.AuthBackend
import app.rosaryguide.core.data.auth.AuthResult
import app.rosaryguide.core.data.auth.AuthUser
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenParsingException
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseNetworkException
import com.google.firebase.FirebaseTooManyRequestsException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthException
import com.google.firebase.auth.FirebaseAuthRecentLoginRequiredException
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.tasks.await

/**
 * Google sign-in with Credential Manager ("Sign in with Google" sheet), then Firebase Auth.
 * Mirrors iOS `AuthStore.signInWithGoogle` / `reauthenticateWithGoogle` / `deleteAccount`.
 */
class FirebaseAuthBackend(
    private val appContext: Context,
    /** OAuth web client (`client_type` 3) from google-services.json: `R.string.default_web_client_id`. */
    private val webClientId: String,
) : AuthBackend {
    override val isConfigured: Boolean
        get() = webClientId.isNotBlank() && FirebaseApp.getApps(appContext).isNotEmpty()

    private val auth: FirebaseAuth? get() = if (isConfigured) FirebaseAuth.getInstance() else null
    private val credentials by lazy { CredentialManager.create(appContext) }

    override val currentUser: AuthUser? get() = auth?.currentUser?.toAuthUser()

    override fun addAuthStateListener(onChange: (AuthUser?) -> Unit): () -> Unit {
        val auth = auth ?: return {}
        val listener = FirebaseAuth.AuthStateListener { onChange(it.currentUser?.toAuthUser()) }
        auth.addAuthStateListener(listener)
        return { auth.removeAuthStateListener(listener) }
    }

    override suspend fun signInWithGoogle(): AuthResult {
        val auth = auth ?: return AuthResult.Failure(NOT_SET_UP)
        val token = when (val t = googleIdToken()) {
            is Token.Ok -> t.idToken
            is Token.Done -> return t.result
        }
        return try {
            val result = auth.signInWithCredential(GoogleAuthProvider.getCredential(token, null)).await()
            result.user?.toAuthUser()?.let { AuthResult.Success(it) } ?: AuthResult.Failure(SIGN_IN_FAILED)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            AuthResult.Failure(signInMessage(e))
        }
    }

    override suspend fun reauthenticateWithGoogle(): AuthResult {
        val auth = auth ?: return AuthResult.Failure(NOT_SET_UP)
        val user = auth.currentUser ?: return AuthResult.Failure("No account is signed in")
        val token = when (val t = googleIdToken()) {
            is Token.Ok -> t.idToken
            is Token.Done -> return t.result
        }
        return try {
            user.reauthenticate(GoogleAuthProvider.getCredential(token, null)).await()
            AuthResult.Success(user.toAuthUser())
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            AuthResult.Failure(reauthenticationMessage(e))
        }
    }

    override suspend fun deleteCurrentUser(): AuthResult {
        val auth = auth ?: return AuthResult.Failure(NOT_SET_UP)
        val user = auth.currentUser ?: return AuthResult.Failure("No account is signed in")
        val snapshot = user.toAuthUser()
        return try {
            user.delete().await()
            AuthResult.Success(snapshot)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            AuthResult.Failure(deleteAccountMessage(e))
        }
    }

    override suspend fun signOut() {
        auth?.signOut()
        // Forget the chosen Google account so the next sign-in offers the account picker.
        runCatching { credentials.clearCredentialState(ClearCredentialStateRequest()) }
    }

    private sealed interface Token {
        data class Ok(val idToken: String) : Token
        data class Done(val result: AuthResult) : Token
    }

    private suspend fun googleIdToken(): Token {
        val activity = CurrentActivity.value
            ?: return Token.Done(AuthResult.Failure("Google sign-in could not open, please try again"))
        val option = GetSignInWithGoogleOption.Builder(webClientId).build()
        val request = GetCredentialRequest.Builder().addCredentialOption(option).build()
        return try {
            val credential = credentials.getCredential(activity, request).credential
            if (credential is CustomCredential &&
                credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
            ) {
                Token.Ok(GoogleIdTokenCredential.createFrom(credential.data).idToken)
            } else {
                Token.Done(AuthResult.Failure("Google Sign-In did not return an identity token"))
            }
        } catch (e: GetCredentialCancellationException) {
            Token.Done(AuthResult.Cancelled)
        } catch (e: NoCredentialException) {
            Token.Done(AuthResult.Failure("Add a Google account to this device, then try again"))
        } catch (e: GoogleIdTokenParsingException) {
            Token.Done(AuthResult.Failure("Google Sign-In did not return an identity token"))
        } catch (e: GetCredentialException) {
            Log.w(TAG, "Google credential request failed: ${e.type}", e)
            Token.Done(AuthResult.Failure(SIGN_IN_FAILED))
        }
    }

    private fun FirebaseUser.toAuthUser(): AuthUser = AuthUser(
        uid = uid,
        providerId = providerData.firstOrNull { it.providerId != "firebase" }?.providerId,
        displayName = displayName ?: providerData.firstNotNullOfOrNull { it.displayName },
    )

    companion object {
        private const val TAG = "AccountAuth"
        const val NOT_SET_UP = "Accounts are not set up in this build yet"
        private const val SIGN_IN_FAILED = "Sign-in did not finish, please try again"
        private const val OFFLINE = "You appear to be offline, connect to the internet and try again"
        private const val TOO_MANY = "Too many attempts, wait a few minutes and try again"

        fun signInMessage(e: Exception): String = when (e) {
            is FirebaseNetworkException -> OFFLINE
            is FirebaseTooManyRequestsException -> TOO_MANY
            else -> SIGN_IN_FAILED
        }

        fun reauthenticationMessage(e: Exception): String = when {
            e is FirebaseAuthException && e.errorCode == "ERROR_USER_MISMATCH" ->
                "That sign-in belongs to a different account, choose the account you’re signed in with"
            e is FirebaseNetworkException -> OFFLINE
            else -> SIGN_IN_FAILED
        }

        fun deleteAccountMessage(e: Exception): String = when (e) {
            is FirebaseAuthRecentLoginRequiredException ->
                "For your security, confirm your sign-in again, then try Delete account once more"
            is FirebaseNetworkException -> OFFLINE
            is FirebaseTooManyRequestsException -> TOO_MANY
            else -> e.localizedMessage ?: "Your account could not be deleted. Try again."
        }
    }
}
