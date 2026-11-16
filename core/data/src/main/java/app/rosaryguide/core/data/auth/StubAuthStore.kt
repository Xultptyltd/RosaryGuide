package app.rosaryguide.core.data.auth

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Local auth stub for M2. Google and guest only; no Firebase and no Apple.
 * A successful Google or guest action counts as an interactive sign-in this launch
 * (matching iOS `AuthStore.interactiveSignIns`), so [LaunchGate] keeps onboarding
 * up until onboarding itself completes.
 */
enum class AuthProvider { None, Guest, Google }

data class AuthState(
    val provider: AuthProvider = AuthProvider.None,
    val userId: String? = null,
    val isSigningInWithGoogle: Boolean = false,
    val interactiveSignIns: Int = 0,
) {
    /** Guest is not a signed-in account; it only unlocks the device-local app. */
    val isSignedIn: Boolean get() = provider == AuthProvider.Google
}

class StubAuthStore(
    initial: AuthState = AuthState(),
) {
    private val _state = MutableStateFlow(initial)
    val state: StateFlow<AuthState> = _state.asStateFlow()

    val isSignedIn: Boolean get() = _state.value.isSignedIn
    val interactiveSignIns: Int get() = _state.value.interactiveSignIns

    fun signInWithGoogle() {
        val next = _state.value.interactiveSignIns + 1
        _state.value = AuthState(
            provider = AuthProvider.Google,
            userId = "stub-google-user",
            interactiveSignIns = next,
        )
    }

    fun continueAsGuest() {
        val next = _state.value.interactiveSignIns + 1
        _state.value = AuthState(
            provider = AuthProvider.Guest,
            userId = null,
            interactiveSignIns = next,
        )
    }

    fun signOut() {
        _state.value = AuthState()
    }
}
