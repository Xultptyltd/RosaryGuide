# Firebase Security and Privacy

Rosary Guide uses Firebase for authentication and private account sync. For signed-in users, prayer intentions, prayer progress (prayed days and the in-progress rosary) and user-facing preferences sync across devices. Device-only state (onboarding seen, notification permission, caches) never leaves the device.

## Enabled Firebase Products

- Firebase Authentication
- Firebase Core
- Cloud Firestore
- Firebase App Check SDK

Do not add Firebase Storage, Analytics, Crashlytics, Cloud Functions, Remote Config, advertising, or tracking SDKs without a fresh privacy/security review.

## Authentication Providers

- Sign in with Apple
- Sign in with Google

The app does not request Apple name or email scopes. Do not add email/password, anonymous, phone/SMS, or custom authentication without a fresh privacy and security review.

## Firestore Schema

Private intentions are stored at:

```text
/users/{uid}/intentions/{intentionId}
```

`intentionId` is the local `UUID` string. Documents do not contain an owner UID field; ownership is enforced by the authenticated path.

Allowed intention fields (unchanged):

- `schemaVersion: int`
- `title: string`
- `note: string?`
- `timesCarried: int`
- `isPinned: bool`
- `createdAt: timestamp`
- `lastCarriedAt: timestamp?`
- `expiresAt: timestamp?`
- `sourceId: string?`
- `category: "personal" | "someone" | "world"`
- `accent: "skyBlue" | "mintGreen" | "purple"`
- `emoji: string?`
- `suggestOn: string[]`
- `updatedAt: timestamp`

Synced preferences and prayer progress are two fixed documents per user:

```text
/users/{uid}/meta/preferences
/users/{uid}/meta/progress
```

No other document id under `meta` can be read or written, and the `meta` collection cannot be listed.

`preferences` (all fields required, nothing else allowed):

- `schemaVersion: 1`
- `appearance: "system" | "light" | "dark"` (Colour theme)
- `prayerLanguage`, `rosaryLanguage: "english" | "latin" | "bilingual"`
- `textSize: "small" | "medium" | "large"`
- `includeSaintMichael: bool`
- `hideIntentionText: bool` (the eye toggle on the Offer screen)
- `dailyReminderEnabled: bool`
- `dailyReminderMinutes: int` (0–1439, minutes after local midnight)
- `feastAlertsEnabled: bool`
- `feastAlertMinutes: int` (0–1439, feast day alert time in minutes after local midnight; default 480 = 8:00 am. Device copies and documents written before this field existed are read as 480. Required by the rules, so builds that write it need the updated rules published.)
- `appIcon: "black" | "white" | "blue"`
- `updatedAt: timestamp` (client time of the last user change; used for last-write-wins; at most one day in the future)

`progress`:

- `schemaVersion: 1`
- `completedDays: string[]` (local calendar days `yyyy-MM-dd` with a finished rosary; at most 400, the app keeps 366 days)
- `historyResetAt: timestamp?` (set by "Delete prayer history" so other devices don't merge older days back)
- `session: map?` (the in-progress rosary: `mysterySet`, `stepIndex` 0–500, `startedAt`, `updatedAt`, `includeSaintMichael`, `language`, optional `intentionId` UUID and `intentionTitle` ≤ 160 chars)
- `sessionChangedAt: timestamp` (last-write-wins for `session`)
- `updatedAt: timestamp`

All timestamps in these two documents must not be more than one day in the future.

## Security Rules

Rules live in `firestore.rules`. They deny by default and only allow an authenticated user to read, query, create, update, or delete documents under their own UID:

```text
request.auth != null && request.auth.uid == uid
```

Rules also validate allowed keys, data types, enum values, string lengths, list contents, counters, timestamps, and UUID-format document IDs. Clients cannot add arbitrary fields such as owner UID, roles, admin status, or entitlements.

## Security Rules Tests

Tests live in `tests/firestore.rules.test.js` and are run with:

```zsh
npm run test:rules
```

They prove:

- unauthenticated users cannot read private intentions
- User A can read/query/write/delete User A intentions
- User B cannot read/query/create/update/delete User A intentions
- invalid document IDs fail
- unexpected/privileged fields fail
- invalid types, empty titles, overlong notes, invalid counters, invalid categories, and invalid mystery values fail
- User A can get/write/delete only `users/A/meta/preferences` and `users/A/meta/progress`; User B and signed-out users cannot read or write them; other `meta` ids and listing `meta` fail
- preferences with missing or extra fields, unknown enum values, out-of-range reminder minutes, wrong types or far-future `updatedAt` fail
- progress with malformed or too many day keys, non-string days, extra fields, out-of-range `stepIndex`, bad `intentionId`, overlong `intentionTitle` or far-future timestamps fail

Latest local result (5 Oct 2026, with the preferences/progress rules): passed with the Firestore Emulator and JDK 21. Run with:

```zsh
JAVA_HOME=/opt/homebrew/opt/openjdk@21 PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH npm run test:rules
```

## Data Collected and Stored

### Firebase Authentication

Firebase Authentication stores the account identifiers it needs to authenticate the user. The iOS client does not manually persist Firebase ID tokens, OAuth access tokens, refresh tokens, authorization codes, Apple credentials, or Google credentials.

### Cloud Firestore

For signed-in users, prayer intentions and intention notes, prayer progress (prayed days, the in-progress rosary and the intention title attached to it) and preferences sync to Firestore under the private UID-scoped paths above. This enables restoration after reinstalling, on another iOS device and future Android support.

### Local Device

The app still stores local cache/preferences in `UserDefaults`:

- Per-account copies of synced data for offline use: `offer.intentions.<uid>`, `offer.syncedIDs.<uid>`, `sync.preferences.<uid>`, `sync.progress.<uid>`
- The active values the app reads: `settings.*`, `offer.hideIntentionText`, `session.*`, and `sync.activeOwner` (which account those values belong to)
- Device-only, never synced: onboarding completion state, notification permission (held by iOS), the completion-quote rotation, Firestore's offline cache

Sign out keeps data. It removes the Firestore listeners and hides intentions from the UI, but keeps each account's device copies and Firestore's offline cache, which may still hold writes that have not reached the server. Preferences and prayer progress stay as they are on the device. Signing back in to the same account shows the device copy immediately and merges it with the cloud copy. A different account gets its own device copy (or defaults and an empty history the first time), so accounts never mix. Delete account removes everything.

## Sync and Merge Behaviour

Preferences and progress (`AccountSyncStore`):

- Local first: settings and progress are always read and written on the device, so the app works offline and signed out. While signed in, changes are uploaded after a short pause (2 s for preferences, 3 s for starting/finishing/discarding a rosary or deleting history). Bead-by-bead progress is not uploaded on every step; it goes up with the next significant change or when the app leaves the foreground. Each upload is one document write, which keeps usage well inside the Spark plan.
- Preferences: last write wins for the whole set by `updatedAt`; ties go to the account copy. Values that were never changed (defaults, or settings from before sync existed) have no timestamp, so any account copy wins over them.
- Prayed days: union of both sides, minus days on or before the newest "Delete prayer history" for the side that had not seen it.
- In-progress rosary: last write wins by `sessionChangedAt`; a rosary from an earlier day is dropped.
- A missing document is only treated as "nothing in the account yet" (and the device copy uploaded) when the server confirms it, never from a cache-only result.
- After preferences arrive from the account, notifications are rescheduled through `NotificationService.reschedule`, which never asks for permission and schedules nothing unless permission was already granted. If the reminders are on but this iPhone has not been asked yet, the Notifications page shows "Allow notifications".
- A synced app icon is applied with `setAlternateIconName` when the app is in the foreground (iOS shows its usual "icon changed" alert).
- If a listener fails (offline start, or rules not yet published), it is restarted the next time the app comes to the foreground.

Intentions:

Intentions created by older builds before sign-in (`offer.intentions`) are adopted by the first account that signs in. Every listener event is merged into the device copy:

- cloud documents win for ids they contain
- a device intention missing from a server-confirmed snapshot is uploaded, unless the server had confirmed it earlier (`offer.syncedIDs.<uid>`), in which case it was deleted on another device and is dropped
- cache-only snapshots (offline, or the backend unreachable or disabled) never drop anything

## Account Deletion

Delete Account reauthenticates the user first, deletes the user's Firestore data (preferences, progress and intentions) while the user is still authenticated, then deletes the Firebase Authentication account. Success is only reported after cloud deletion and Auth account deletion succeed. If cloud deletion fails, the Auth account is not deleted.

If more cloud data is added later, it must be included in this deletion flow before Auth deletion.

Full order in the app:

1. Re-authenticate with the account's provider (Apple or Google). Cancelling stops quietly.
2. Delete `/users/{uid}/meta/preferences` and `/users/{uid}/meta/progress`, then every document in `/users/{uid}/intentions` (batched), then clear Firestore's local cache. This is all the per-user cloud data; no `/users/{uid}` parent document is ever written. Preferences and progress go first because clearing the cache shuts down the Firestore instance.
3. Sign in with Apple only: revoke the user's Apple tokens with `Auth.auth().revokeToken(withAuthorizationCode:)`, using the one-time code from step 1. Firebase calls Apple's `/auth/revoke` endpoint, so no Cloud Function is needed, but the Apple provider in the Firebase console must have its Services ID, Apple Team ID, Key ID and private key filled in. A failed revocation is logged in Debug and does not block deletion.
4. Delete the Firebase Auth user.
5. Google only: `GIDSignIn.disconnect` revokes the app's Google grant and clears Google Sign-In's keychain entry (other providers just sign out of Google Sign-In locally).
6. Clear local intentions, the migration marker for that UID, the account's `sync.preferences.<uid>` and `sync.progress.<uid>` copies, Rosary session progress and prayed-day history, and reset synced preferences to defaults (which also cancels reminders). The Home Screen icon is left as it is; onboarding state is device-only and kept.

If step 2 or 4 fails, the device copies of intentions, preferences and progress are uploaded again so nothing is lost, and the user sees why.

## Private Prayer Content

Prayer intentions and notes are private devotional content. They must not be sent to Analytics, Crashlytics, logs, document IDs, URLs, notification payloads, or unrelated third parties.

Client-side encryption is not implemented yet. The repository layer keeps Firestore access abstract enough that encryption/decryption can be introduced later around the sync model.

## App Check

The app includes Firebase App Check:

- Debug builds use the App Check debug provider.
- Release builds use Firebase's App Attest provider when supported and DeviceCheck as the fallback.

Manual Firebase Console work is still required before App Check is enforced: register the iOS app for App Check, add any debug tokens used for local development, and enforce App Check for Firestore after testing.

## Environments

`.firebaserc` currently defines the development Firebase project:

```json
{ "development": "rosary-guide-f5c02" }
```

A separate production Firebase project still needs to be created and configured before production/TestFlight release. Do not use production user data in development.

## Secrets and Credentials

`GoogleService-Info.plist` is bundled with the iOS client, as required by Firebase. The Firebase client API key is not treated as a secret. Do not add service-account keys, Admin SDK credentials, private server secrets, or privileged API credentials to the iOS app or this repository.

## App Store Privacy Review

`PrivacyInfo.xcprivacy` now declares account-linked user ID and account-linked user content for app functionality. Before App Store submission, review App Store Connect privacy answers against Firebase Authentication and synced Firestore intentions, prayer history and preferences (prayer history may count as "Other User Content" or usage data linked to the user).
