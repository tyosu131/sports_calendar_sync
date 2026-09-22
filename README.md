# sports_calendar_sync

A Flutter + Firebase sports calendar app for following teams and synchronizing their games to external calendars.

## Current project status

The production path is implemented and deployed:

- Cloud Functions and the GOAL V1 football synchronization path are deployed and have populated canonical real games in Firestore.
- Presentation closure is merged, and the public domain and OAuth branding are published.
- Personalized ICS feeds are deployed; Apple Calendar production behavior has been verified. ICS remains the integration path for Apple Calendar and other ICS-capable clients.
- Google Calendar direct API synchronization is deployed and is the only normal Google Calendar path. On a real iPhone, the core flow—including OAuth connection and return, app-owned **Sports Calendar** creation/recreation, initial event population, competition labels, and finished scores—has been verified.
- Repository and production both use Node.js 22, 1st Gen. The owner reported successful updates of all 11 Functions on 2026-09-22; this task did not deploy.
- Pixel 9a release-build Google Sign-In, Google Calendar OAuth, cancel return and Settings sync passed after SHA-1 registration and a Firebase-generated config refresh (owner evidence). One initial Google login failure did not recur on retry; monitor it without speculative changes. Terminated-app return, revoked credentials and quota/rate-limit device coverage remain pending.

The repository also retains sample mode as a local development and UI-test option. Sample mode is not the overall production state.

## Run sample mode

```shell
flutter pub get
flutter run --dart-define=USE_SAMPLE_DATA=true
```

With `USE_SAMPLE_DATA=true`, the app uses local in-memory team, game, and user repositories. It does not read or write Firestore, call the deployed synchronization functions, or require provider credentials. It includes football, NPB, and NBA sample teams and games for Team Search, Home, Team Detail, Schedule, and follow/unfollow testing.

When sample mode is off, the app uses Firebase Auth, Firestore-backed repositories, personalized ICS feeds, and the direct Google Calendar integration.

## Validation

Run the deterministic repository gates (Node 22, Flutter 3.41.4):

```shell
npm --prefix functions ci
npm --prefix functions run build
npm --prefix functions test
npm --prefix functions run validate:config
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
```

Functions tests and configuration validation use local synthetic fixtures and do not require provider API calls, Firebase credentials, or Firestore writes. Repository and production runtime are Node.js 22 (production status is owner-reported deployment evidence).

## Architecture summary

- Flutter app using Material 3, Riverpod, and GoRouter
- Firebase Auth and Firestore-backed production repositories
- Cloud Functions serving personalized ICS and orchestrating real GOAL V1 synchronization
- Canonical Firestore games shared by in-app views, personalized ICS, and Google Calendar presentation
- Apple and generic calendar delivery through subscription URLs
- Direct Google Calendar API integration through OAuth and an app-owned secondary calendar
- Optional in-memory sample repositories selected by `USE_SAMPLE_DATA=true`

## Current limitations / remaining work

- Apple authentication is implemented with nonce protection but remains disabled pending Apple/Firebase/provisioning configuration and iPhone E2E. Android shows Google only; iOS shows Google plus Apple only in a configured build. No email/password login is added.
- Terminated-app OAuth return remains pending verification.
- OAuth denial UX, revoked-credential behavior, quota/rate-limit behavior, and all transient callback failure paths are not fully production-verified.
- Broader competition/provider coverage, broadcast data, notifications, full-text search, offline caching, and high-resolution local logo assets remain incomplete.

## Safety notes

- Do not commit or print secrets or `.env` files.
- Do not deploy Functions, invoke production synchronization, or write/seed Firestore without an explicitly approved operational plan.
- Do not modify OAuth configuration, redirect URIs, or production calendars as part of local development or deterministic verification.

## Useful docs

- [Current state](docs/current-state.md)
- [Google Calendar direct synchronization](docs/google-calendar-connection.md)
- [Phase 0 architecture snapshot (historical)](docs/phase0-current-architecture.md)
- [E2E minimum setup guide (historical/deprecated)](docs/e2e-minimum-setup.md)

## Mobile authentication / Store readiness

See [Apple setup and verification](docs/apple-sign-in-readiness.md) and the
[current operational evidence](docs/current-state.md). Apple Calendar ICS is
independent from Sign in with Apple; Google Calendar authorization is independent
from the Firebase login provider.

Tester IDs stay Android `com.example.sports_calendar_sync` and iOS
`com.example.sportsCalendarSync`. Android release currently uses debug signing
(`~/.android/debug.keystore`), acceptable for the reported device test, **not**
Play Store readiness. Before Store publication: choose production app/bundle IDs,
register matching Firebase apps and OAuth clients, configure release/upload
signing (including Play App Signing certificate fingerprints), and prepare store
metadata/distribution. No production signing key or identifier migration is
performed here. Web/macOS are not primary acceptance targets.
