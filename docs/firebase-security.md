# Firebase Security and Privacy

Rosary Guide uses Firebase for authentication and private intention sync. The sync surface is intentionally narrow: prayer intentions sync across signed-in devices, while unrelated app state remains local unless a future feature explicitly requires cloud persistence.

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

Allowed intention fields:

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

Latest local result: passed with the Firestore Emulator after installing JDK 21. Run with:

```zsh
JAVA_HOME=/opt/homebrew/opt/openjdk@21 PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH npm run test:rules
```

## Data Collected and Stored

### Firebase Authentication

Firebase Authentication stores the account identifiers it needs to authenticate the user. The iOS client does not manually persist Firebase ID tokens, OAuth access tokens, refresh tokens, authorization codes, Apple credentials, or Google credentials.

### Cloud Firestore

For signed-in users, prayer intentions and intention notes sync to Firestore under the private UID-scoped path above. This enables restoration on another iOS device and future Android support.

### Local Device

The app still stores local cache/preferences in `UserDefaults`:

- Firestore-synced intention cache for offline display
- Rosary session progress
- Recent prayed-day history
- App language, rosary language, appearance, text size, haptics, and prayer preferences
- Onboarding completion state

Sign out clears private local intention/session data from the device, removes the Firestore listener, and clears Firestore's local persisted cache. It does not delete cloud intentions.

## Migration Behaviour

After authentication, existing local intentions are migrated to Firestore using their existing UUIDs as document IDs. Migration is idempotent:

- if a remote document with the same UUID already exists, it is not duplicated
- migration only marks complete after uploads succeed
- interrupted migrations retry on the next authenticated launch
- after sync starts, Firestore becomes the authoritative intention store and local storage acts as cache/offline state

## Account Deletion

Delete Account reauthenticates the user first, deletes Firestore intentions while the user is still authenticated, then deletes the Firebase Authentication account. Success is only reported after both cloud intention deletion and Auth account deletion succeed. If cloud deletion fails, the Auth account is not deleted.

If more cloud data is added later, it must be included in this deletion flow before Auth deletion.

Full order in the app:

1. Re-authenticate with the account's provider (Apple or Google). Cancelling stops quietly.
2. Delete every document in `/users/{uid}/intentions` (batched) and clear Firestore's local cache. This is the only per-user cloud data; no `/users/{uid}` parent document is ever written.
3. Sign in with Apple only: revoke the user's Apple tokens with `Auth.auth().revokeToken(withAuthorizationCode:)`, using the one-time code from step 1. Firebase calls Apple's `/auth/revoke` endpoint, so no Cloud Function is needed, but the Apple provider in the Firebase console must have its Services ID, Apple Team ID, Key ID and private key filled in. A failed revocation is logged in Debug and does not block deletion.
4. Delete the Firebase Auth user.
5. Google only: `GIDSignIn.disconnect` revokes the app's Google grant and clears Google Sign-In's keychain entry (other providers just sign out of Google Sign-In locally).
6. Clear local intentions, the migration marker for that UID, Rosary session progress and prayed-day history.

If step 2 or 4 fails, the local intentions are uploaded again so nothing is lost, and the user sees why. Device preferences (appearance, reminders, onboarding state) are kept because they are not account data.

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

`PrivacyInfo.xcprivacy` now declares account-linked user ID and account-linked user content for app functionality. Before App Store submission, review App Store Connect privacy answers against Firebase Authentication and synced Firestore intentions.
