# Rosary Guide — Android

Native Kotlin + Jetpack Compose port of Rosary Guide. Milestone **M0** is the
toolchain, Gradle skeleton, design tokens, and a four-tab navigation shell.

This repository is local-only for now. It has not been pushed to GitHub.

## Application id (provisional)

`applicationId` is currently `app.rosaryguide.android`. This is a placeholder
and must be confirmed before any Play Console or Firebase Android app is
created — it cannot change once shipped.

## Sign-in (v1)

Google Sign-In and continue-as-guest only. Sign in with Apple is not offered
on Android. Firebase / `google-services.json` is not included in M0.

## Modules

- `:app` — single `MainActivity`, Hilt, Navigation Compose shell
- `:core:model` — pure Kotlin domain models (placeholder)
- `:core:data` — DataStore keys, later Room + catalogs
- `:core:designsystem` — iOS `AppTheme` colour tokens and type scale
- `:feature:onboarding` / `:today` / `:learn` / `:feasts` / `:profile` / `:pray` / `:settings`
- `:sync` — Auth / Firestore (M5)
- `:notifications` — reminder scheduler (M6)

## Build

Requires JDK 17 and an Android SDK (`ANDROID_HOME`). On this machine:

```
export JAVA_HOME=/home/box/jdk-17
export ANDROID_HOME=/home/box/android-sdk
./gradlew assembleDebug test
```

Companion planning docs: `/workspace/android/plan.md` and
`/workspace/android/inventory.md`.
