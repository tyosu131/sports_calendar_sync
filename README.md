# sports_calendar_sync

A Flutter + Firebase sports calendar app for following teams and viewing their games in one place.

The long-term goal is to let users subscribe to team schedules through iCalendar, while keeping the app useful as a cost-controlled Free MVP before any paid cloud deployment.

## Current Free MVP status

The app currently supports a sample/static data mode that can be run without Firebase Functions, API sync, Secret Manager, or Firestore writes.

In sample mode you can verify:

- Team Search
- Home followed-team summary
- Team Detail
- Schedule view
- follow / unfollow behavior with in-memory state
- football / NPB / NBA sample teams and games

The Schedule view is competition-agnostic. It displays games from multiple competitions in the same monthly schedule UI, including future scheduled games and past finished games with scores.

## Cost-control policy

This project intentionally avoids paid cloud usage at the current stage.

- No Blaze upgrade for now
- No Firebase Functions deploy for now
- No API sync for now
- No Firestore write / seed / `--write` without a separate exact approval
- No secret value committed, printed, or documented
- `API_SPORTS_KEY` / Secret Manager setup is not required for sample mode

The Firebase Functions and API-SPORTS path remains part of the architecture, but production deployment is deferred until the billing decision is explicit.

## Run sample mode

```shell
flutter pub get
flutter run --dart-define=USE_SAMPLE_DATA=true
```

Sample mode uses local in-memory repositories and does not read or write Firestore.

## Validation

```shell
flutter analyze
flutter test
```

## Architecture summary

- Flutter app with Material 3 UI
- Riverpod for state management
- GoRouter for navigation
- Firebase Auth / Firestore repositories retained for the deploy-ready path
- sample repositories for cost-control Free MVP mode
- Cloud Functions path for future iCalendar delivery
- API-SPORTS sync path for future real game data

Repository implementations are selected with:

```dart
const useSampleData = bool.fromEnvironment('USE_SAMPLE_DATA');
```

When `USE_SAMPLE_DATA=true`, the app uses:

- `SampleTeamRepository`
- `SampleGameRepository`
- `SampleUserRepository`

When sample mode is off, the app uses the Firestore-backed repositories.

## Current limitations / deferred work

- Production API sync is deferred
- Cloud Functions deploy is deferred
- real iCalendar URL verification is deferred
- `API_SPORTS_KEY` secret value setup is blocked until a Blaze / billing decision
- Schedule UI polish remains future work
- team-level local ICS generation remains future work
- README / architecture docs will continue to evolve as the Free MVP matures

## Safety notes

- Do not commit secrets
- Do not print or paste `API_SPORTS_KEY`
- Do not commit `.env` files
- Do not run Firestore write / seed / `--write` without an exact approved plan
- Do not deploy Functions or run API sync while cost-control mode is active

## Useful docs

- [Current state](docs/current-state.md)
- [Phase 0 current architecture](docs/phase0-current-architecture.md)
- [E2E minimum setup](docs/e2e-minimum-setup.md)
