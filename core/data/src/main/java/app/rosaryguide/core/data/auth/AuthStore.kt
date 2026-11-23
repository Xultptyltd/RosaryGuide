package app.rosaryguide.core.data.auth

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Google sign-in through Firebase Auth, or guest. Port of iOS `AuthStore` (Android v1 has no Apple).
 *
 * Guest never calls Firebase: like iOS, it is "not signed in" with device-only data. There is
 * no anonymous Firebase account (the project's privacy review allows Google and Apple only).
 * A Google or guest choice made by tapping counts as an interactive sign-in this launch
 * (iOS `interactiveSignIns`), so [app.rosaryguide.core.data.launch.LaunchGate] keeps onboarding up
 * until onboarding itself completes. A session restored at launch does not count.
 */
enum class AuthProvider { None, Guest, Google }

data class AuthState(
    val provider: AuthProvider = AuthProvider.None,
    val userId: String? = null,
    val displayName: String? = null,
    val isSigningInWithGoogle: Boolean = false,
    val isWorking: Boolean = false,
    val interactiveSignIns: Int = 0,
    /** Friendly failure text (sentence case, no full stop); null after a cancel. */
    val errorMessage: String? = null,
) {
    /** Guest is not a signed-in account; it only unlocks the device-local app. */
    val isSignedIn: Boolean get() = provider == AuthProvider.Google && userId != null
}

/** The signed-in Firebase user, as far as the app needs it. */
data class AuthUser(val uid: String, val providerId: String?, val displayName: String?)

sealed interface AuthResult {
    data class Success(val user: AuthUser) : AuthResult
    data object Cancelled : AuthResult
    data class Failure(val message: String) : AuthResult
}

/** Firebase Auth + Credential Manager, behind an interface so flows can be tested with a fake. */
interface AuthBackend {
    /** False when the build has no Firebase config. */
    val isConfigured: Boolean
    val currentUser: AuthUser?
    fun addAuthStateListener(onChange: (AuthUser?) -> Unit): () -> Unit
    suspend fun signInWithGoogle(): AuthResult
    /** Confirms the signed-in Google account again before a sensitive change. */
    suspend fun reauthenticateWithGoogle(): AuthResult
    /** Deletes the Firebase Auth user. Success carries the deleted user. */
    suspend fun deleteCurrentUser(): AuthResult
    suspend fun signOut()
}

/** For previews, tests and builds without Firebase. */
class LocalOnlyAuthBackend : AuthBackend {
    override val isConfigured: Boolean = false
    override val currentUser: AuthUser? = null
    override fun addAuthStateListener(onChange: (AuthUser?) -> Unit): () -> Unit = {}
    override suspend fun signInWithGoogle(): AuthResult = AuthResult.Failure(NOT_SET_UP)
    override suspend fun reauthenticateWithGoogle(): AuthResult = AuthResult.Failure(NOT_SET_UP)
    override suspend fun deleteCurrentUser(): AuthResult = AuthResult.Failure(NOT_SET_UP)
    override suspend fun signOut() {}

    companion object {
        const val NOT_SET_UP = "Accounts are not set up in this build yet"
    }
}

class AuthStore(
    private val backend: AuthBackend,
    private val scope: CoroutineScope,
) {
    private val _state = MutableStateFlow(stateFor(backend.currentUser, AuthState()))
    val state: StateFlow<AuthState> = _state.asStateFlow()

    val isSignedIn: Boolean get() = _state.value.isSignedIn
    val interactiveSignIns: Int get() = _state.value.interactiveSignIns
    val userId: String? get() = _state.value.userId

    init {
        backend.addAuthStateListener { user ->
            // A guest stays a guest until a Google account signs in.
            _state.value = stateFor(user, _state.value)
        }
    }

    /** [onResult] gets true once Firebase has the Google user; false on cancel or failure. */
    fun signInWithGoogle(onResult: (Boolean) -> Unit = {}) {
        if (_state.value.isWorking) return
        _state.value = _state.value.copy(isWorking = true, isSigningInWithGoogle = true, errorMessage = null)
        scope.launch {
            when (val result = backend.signInWithGoogle()) {
                is AuthResult.Success -> {
                    _state.value = stateFor(result.user, _state.value).copy(
                        interactiveSignIns = _state.value.interactiveSignIns + 1,
                        isWorking = false,
                        isSigningInWithGoogle = false,
                    )
                    onResult(true)
                }
                AuthResult.Cancelled -> {
                    finish(null)
                    onResult(false)
                }
                is AuthResult.Failure -> {
                    finish(result.message)
                    onResult(false)
                }
            }
        }
    }

    fun continueAsGuest() {
        val current = _state.value
        _state.value = current.copy(
            provider = if (current.isSignedIn) current.provider else AuthProvider.Guest,
            interactiveSignIns = current.interactiveSignIns + 1,
            errorMessage = null,
        )
    }

    /** Keeps data on the device; the app carries on as a guest without sync. */
    fun signOut() {
        scope.launch {
            backend.signOut()
            _state.value = _state.value.copy(provider = AuthProvider.None, userId = null, displayName = null)
        }
    }

    suspend fun reauthenticateForSensitiveOperation(): Boolean {
        if (!isSignedIn) {
            finish("No account is signed in")
            return false
        }
        _state.value = _state.value.copy(isWorking = true, isSigningInWithGoogle = true, errorMessage = null)
        return when (val result = backend.reauthenticateWithGoogle()) {
            is AuthResult.Success -> {
                finish(null)
                true
            }
            AuthResult.Cancelled -> { finish(null); false }
            is AuthResult.Failure -> { finish(result.message); false }
        }
    }

    /** Deletes the Firebase Auth user. Call only after re-authentication and the cloud data deletion. */
    suspend fun deleteAccount(): Boolean {
        _state.value = _state.value.copy(isWorking = true, errorMessage = null)
        return when (val result = backend.deleteCurrentUser()) {
            is AuthResult.Success -> {
                backend.signOut()
                _state.value = _state.value.copy(
                    provider = AuthProvider.None, userId = null, displayName = null,
                    isWorking = false, isSigningInWithGoogle = false,
                )
                true
            }
            AuthResult.Cancelled -> { finish(null); false }
            is AuthResult.Failure -> { finish(result.message); false }
        }
    }

    fun clearError() {
        _state.value = _state.value.copy(errorMessage = null)
    }

    private fun finish(message: String?) {
        _state.value = _state.value.copy(isWorking = false, isSigningInWithGoogle = false, errorMessage = message)
    }

    private fun stateFor(user: AuthUser?, previous: AuthState): AuthState = when {
        // Android signs in with Google only; any restored Firebase user is that account.
        user != null -> previous.copy(
            provider = AuthProvider.Google,
            userId = user.uid,
            displayName = user.displayName?.trim()?.ifEmpty { null },
        )
        else -> previous.copy(
            provider = if (previous.provider == AuthProvider.Guest) AuthProvider.Guest else AuthProvider.None,
            userId = null,
            displayName = null,
        )
    }

    companion object {
        const val GOOGLE_PROVIDER = "google.com"
    }
}
