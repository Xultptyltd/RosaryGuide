package app.rosaryguide.core.data.sync

import app.rosaryguide.core.data.auth.AuthStore
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.withTimeout

/**
 * Delete account, in the iOS order (`SettingsView.deleteAccount`):
 * 1. confirm the Google sign-in again (Firebase needs a recent login to delete a user);
 * 2. delete `/users/{uid}/meta/preferences`, `/users/{uid}/meta/progress` and every
 *    `/users/{uid}/intentions/{id}` (the rules allow an owner to delete each of these);
 * 3. delete the Firebase Auth user;
 * 4. clear this account's data from the device.
 * Any failure leaves the account and its data in place (re-uploading the device copy) and explains why.
 */
class AccountDeletion(
    private val auth: AuthStore,
    private val sync: AccountSync,
    private val cloudTimeoutMs: Long = 20_000,
) {
    sealed interface Outcome {
        data object Deleted : Outcome
        data object Cancelled : Outcome
        data class Failed(val message: String) : Outcome
    }

    suspend fun run(): Outcome {
        if (!auth.reauthenticateForSensitiveOperation()) {
            val message = auth.state.value.errorMessage
            auth.clearError()
            return message?.let { Outcome.Failed(it) } ?: Outcome.Cancelled
        }
        val uid = auth.userId
        try {
            // A Firestore delete waits for the server; without a limit an unreachable backend
            // would leave the flow hanging after the Google sheet.
            withTimeout(cloudTimeoutMs) { sync.deleteCloudDataForCurrentUser() }
        } catch (e: TimeoutCancellationException) {
            sync.restoreCloudDataAfterFailedDeletion()
            return Outcome.Failed(CLOUD_FAILED)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            sync.restoreCloudDataAfterFailedDeletion()
            return Outcome.Failed(CLOUD_FAILED)
        }
        if (auth.deleteAccount()) {
            sync.finishAccountDeletion(uid)
            return Outcome.Deleted
        }
        sync.restoreCloudDataAfterFailedDeletion()
        val message = auth.state.value.errorMessage ?: "Your account could not be deleted. Try again."
        auth.clearError()
        return Outcome.Failed(message)
    }

    companion object {
        const val CLOUD_FAILED =
            "Your synced data could not be deleted, so your account was not deleted. Check your connection and try again."
    }
}
