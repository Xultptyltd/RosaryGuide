# M5: Firebase accounts and sync (23 Nov 2026)

Android now uses the same Firebase project as iOS (`rosary-guide-f5c02`).

## Firebase app

- Android app `1:365777448061:android:0c7baf321c53b419c5d514`, package `app.rosaryguide.android`.
- Debug SHA-1 `6A:3C:87:F6:C2:97:7E:38:96:12:38:CF:D3:47:B0:F0:00:6E:A7:50` is registered.
  Add the **release / Play App Signing SHA-1 and SHA-256** before any Play build, or Google
  sign-in fails there (`DEVELOPER_ERROR`). Download the refreshed `google-services.json` afterwards.
- `app/google-services.json` is committed (it is not a secret; the repo does not ignore it).
  The google-services plugin generates `default_web_client_id` from the OAuth web client
  (`client_type` 3), which Credential Manager uses as the server client id.
- SDKs: Firebase BoM 35.2.0 (Auth, Firestore), Credential Manager 1.6.0 +
  `credentials-play-services-auth`, `googleid` 1.2.1. No Analytics, Crashlytics, Storage,
  Functions or Remote Config (iOS `docs/firebase-security.md`).

## Sign-in

- **Google**: Credential Manager "Sign in with Google" sheet → `GoogleAuthProvider` credential →
  `FirebaseAuth.signInWithCredential`. The sign-in screen stays up (Google button spinner) until
  Firebase has the user; cancel shows nothing, other failures show a short toast with the iOS wording.
- **Guest**: local only, as on iOS. No anonymous Firebase account (the iOS privacy review allows
  Google and Apple only). A guest never calls Firebase.
- Sign out: `FirebaseAuth.signOut()` + `clearCredentialState`. Data stays on the device; sync stops.
- No Apple sign-in on Android v1.

## Firestore paths (identical to iOS)

| Path | Contents |
| --- | --- |
| `/users/{uid}/meta/preferences` | `schemaVersion`, `appearance`, `prayerLanguage`, `rosaryLanguage`, `textSize`, `includeSaintMichael`, `hideIntentionText`, `dailyReminderEnabled`, `dailyReminderMinutes`, `feastAlertsEnabled`, `feastAlertMinutes`, `appIcon`, `updatedAt`, optional `rosaryConfig`, `fieldUpdatedAt` |
| `/users/{uid}/meta/progress` | `schemaVersion`, `completedDays`, `sessionChangedAt`, `updatedAt`, optional `historyResetAt`, `session`, `rosaries` |
| `/users/{uid}/intentions/{UUID}` | iOS `OfferIntention.firestoreData()` fields, including `archivedAt` |

- Every UUID that goes to the account is **upper case** (iOS `UUID.uuidString`), so both apps
  address the same documents. Existing lower-case Android ids are upper-cased once at sign-in.
  Non-UUID ids (papal intentions) are left out of `intentionId(s)`, which the rules only accept as UUIDs.
- Merge rules are ported from iOS: preferences last-write-wins **per field** (`fieldUpdatedAt`),
  prayed days are a union minus the newest `historyResetAt`, the in-progress Rosary is
  last-write-wins by `sessionChangedAt`, finished Rosaries union by id, intentions newest
  `updatedAt` wins with tombstones for local deletes.
- Preferences Android has no control for yet (prayer language, Rosary language, text size)
  round-trip unchanged with their change times, so an Android device never resets an iPhone choice.
- Each account has its own device copy (`sync.*` / `offer.*` DataStore keys). The first account to
  sign in adopts guest data; another account starts from its own copy.
- Uploads wait 2 s (preferences) / 3 s (progress); bead-by-bead progress goes up with the next
  significant change or when the app stops. A permission-denied write steps the document down to
  the older schema, like iOS.

## Delete account

Settings → Delete account (signed in): confirm → re-authenticate with Google → delete
`meta/preferences`, `meta/progress` and every `intentions/*` (20 s limit) → clear the Firestore
cache → delete the Firebase Auth user → clear this account's data on the device → "Account deleted"
→ onboarding. A failure at any step re-uploads the device copy and shows "Account not deleted"
with the reason (iOS wording). `requires-recent-login` and user-mismatch have their own messages.

## Rules

No rules change. The deployed rules (read 23 Nov 2026) are identical to iOS `firestore.rules`;
every Android document shape is checked against them in `SyncDocumentsTest`.

## Code

- `core/data/.../auth/AuthStore.kt`: auth state and flows behind `AuthBackend`.
- `core/data/.../sync/`: `SyncedPreferences`, `SyncedProgress`, `IntentionDocuments` /
  `IntentionMerge`, `AccountSync`, `AccountDeletion`, `AccountRemote`.
- `sync/`: `FirebaseAuthBackend` (Credential Manager + Firebase Auth), `FirestoreAccountRemote`.
- Tests with fakes: `core/data/src/test/.../sync/` (`FakeAccountRemote`, `FakeAuthBackend`).

## Open items

- Release / Play App Signing SHA fingerprints (console).
- App Check: iOS uses App Check (App Attest). If enforcement is ever turned on for Firestore or
  Auth, Android needs the Play Integrity provider first, or every Android request fails.
- Google sign-in needs a device or emulator with a Google account and Play services; not yet
  exercised end to end.
- Android shows no sync-error notice yet (`AccountSync.syncErrorMessage` is exposed for one).
