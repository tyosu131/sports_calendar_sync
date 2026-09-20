# sports_calendar_sync

A Flutter + Firebase sports calendar app for following teams and synchronizing their games to external calendars.

## Current project status

The production path is implemented and deployed:

- Cloud Functions and the GOAL V1 football synchronization path are deployed and have populated canonical real games in Firestore.
- Personalized ICS feeds are deployed; Apple Calendar production behavior has been verified. ICS remains the integration path for Apple Calendar and other ICS-capable clients.
- Google Calendar direct API synchronization is deployed and is the only normal Google Calendar path. On a real iPhone, OAuth connection, app-owned **Sports Calendar** creation/recreation, initial event population, competition labels, and finished scores have been verified.
- Clean automatic OAuth callback return after removal of the legacy Google ICS route still requires a post-PR-38 smoke test. Android real-device behavior, terminated-app return, revoked credentials, quota/rate-limit behavior, transient callback failures, and Google OAuth publishing/verification also remain unverified or incomplete.

The repository also retains sample mode as a local development and UI-test option. Sample mode is not the overall production state.

## Run sample mode

```shell
flutter pub get
flutter run --dart-define=USE_SAMPLE_DATA=true
```

With `USE_SAMPLE_DATA=true`, the app uses local in-memory team, game, and user repositories. It does not read or write Firestore, call the deployed synchronization functions, or require provider credentials. It includes football, NPB, and NBA sample teams and games for Team Search, Home, Team Detail, Schedule, and follow/unfollow testing.

When sample mode is off, the app uses Firebase Auth, Firestore-backed repositories, personalized ICS feeds, and the direct Google Calendar integration.

## Validation

Run the deterministic repository gates (Node 20, Flutter 3.41.4):

```shell
npm --prefix functions ci
npm --prefix functions run build
npm --prefix functions test
npm --prefix functions run validate:config
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
```

Functions tests and configuration validation use local synthetic fixtures and do not require provider API calls, Firebase credentials, or Firestore writes. Functions currently target Node.js 20; runtime decommission/migration is separate operational work.

## Architecture summary

- Flutter app using Material 3, Riverpod, and GoRouter
- Firebase Auth and Firestore-backed production repositories
- Cloud Functions serving personalized ICS and orchestrating real GOAL V1 synchronization
- Canonical Firestore games shared by in-app views, personalized ICS, and Google Calendar presentation
- Apple and generic calendar delivery through subscription URLs
- Direct Google Calendar API integration through OAuth and an app-owned secondary calendar
- Optional in-memory sample repositories selected by `USE_SAMPLE_DATA=true`

## Current limitations / remaining work

- Android Google Calendar connection and return have not been verified on a real device.
- Clean standard OAuth callback → `sportscalendar://` → automatic app return must be re-verified after removal of the legacy Google ICS route; terminated-app return is also pending.
- OAuth denial UX, revoked-credential behavior, quota/rate-limit behavior, and all transient callback failure paths are not fully production-verified.
- Google OAuth application publishing/verification is not complete.
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
