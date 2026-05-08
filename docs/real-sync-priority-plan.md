# Real Sync Priority Plan

> Created: 2026-05-08  
> Scope: documentation-only implementation order for real J1 game sync.

## Purpose

This plan turns the model-gap findings into an implementation order for real J1 game sync. It intentionally keeps Blaze deployment, `getCalendar` production verification, `.ics` curl checks, and API-SPORTS production sync deferred.

## Inputs Inspected

- `docs/team-game-model-gaps.md`
- `docs/jleague-season-design.md`
- `docs/current-state.md`
- `functions/src/pipelines/syncFootball.ts`
- `functions/src/adapters/football_adapter.ts`
- `functions/src/functions/getCalendar.ts`
- `lib/domain/models/game.dart`
- `functions/scripts/seedJ1SampleGame.js`

Note: `functions/src/services/football_adapter.ts` does not exist in the current repo. The existing adapter is `functions/src/adapters/football_adapter.ts`.

## Recommended Implementation Order

### 1. Define Minimal Competition Season / Tournament Profile

Status: must-have before real sync.

Why needed:

- J.League has 2026 special competition and 2026/27 season complexity.
- Real sync must not derive API season from `new Date().getFullYear()`.
- A game should eventually point to both stable `competitionKey` and a concrete `competitionSeasonKey`.

Likely affected files later:

- `functions/src/types.ts`
- `functions/src/pipelines/syncFootball.ts`
- `functions/src/adapters/football_adapter.ts`
- `functions/scripts/seedJ1SampleGame.js` if sample games should mirror the new field
- `lib/domain/models/game.dart` if the Flutter model should read `competitionSeasonKey`
- Future seed/config file for competition season profiles

Risks if skipped:

- Sync may fetch the wrong API season.
- 2026 special tournament and 2026/27 league data can be mixed.
- Future J2/J3 or overseas league seasons may require breaking migrations.

Decision:

- Implement this first.
- Start with a minimal static/config-driven profile for `football_j1`, not a broad multi-sport season system.
- Keep `competitionKey: football_j1`.
- Add a `competitionSeasonKey` concept before real API fixture writes.

### 2. Make API Season Handling Explicit

Status: must-have before real sync.

Why needed:

- `syncFootball.ts` currently uses `new Date().getFullYear()`.
- API-SPORTS Free plan cannot fetch 2025/2026 J1 teams directly, and API season availability differs from current membership.
- API season is a property of a competition season/tournament profile, not the current calendar year.

Likely affected files later:

- `functions/src/pipelines/syncFootball.ts`
- Future competition season config/data module
- Verification scripts for real sync input planning

Risks if skipped:

- Real sync may silently query the wrong season.
- Special competitions crossing calendar years will be hard to represent.
- Test data may pass while production sync returns 0 fixtures.

Decision:

- Implement immediately after the minimal profile.
- Pass `apiSeason` from profile/config into fixture fetch.
- Preserve the ability to mark a profile as not accessible on the current plan.

### 3. Move `syncFootball` Conversion to Adapter Parity

Status: must-have before real sync.

Why needed:

- Sample games and `football_adapter.ts` write the richer shape:
  - `competitionKey`
  - `sportKey`
  - English names
  - team logo URLs
  - `externalFixtureId`
  - `rapidApiFixtureId`
- `syncFootball.ts` inline conversion currently omits several of those fields.

Likely affected files later:

- `functions/src/pipelines/syncFootball.ts`
- `functions/src/adapters/football_adapter.ts`
- `functions/src/types.ts`
- `functions/scripts/verifyJ1SampleGame.js` or a new real-sync verification script

Risks if skipped:

- Real synced games will not match sample-game behavior.
- Flutter can still render basic cards, but logos and compatibility IDs may be missing.
- Future verification will have false gaps between sample and real data.

Decision:

- Use `functions/src/adapters/football_adapter.ts` as the single conversion point.
- Extend adapter inputs as needed to include `competitionSeasonKey` after step 1.
- Bring `syncFootball.ts` to sample-game field parity before enabling writes from real API data.

### 4. Lock External Fixture ID Compatibility

Status: must-have before real sync.

Why needed:

- Current Flutter `Game` reads `externalFixtureId`, falling back to `rapidApiFixtureId`.
- Existing Cloud Functions code still writes `rapidApiFixtureId` in the inline converter.
- Sample games write both.

Likely affected files later:

- `functions/src/adapters/football_adapter.ts`
- `functions/src/pipelines/syncFootball.ts`
- `functions/src/types.ts`
- Real sync verify script

Risks if skipped:

- Duplicate or unstable game IDs.
- Migration ambiguity between legacy and preferred fields.
- Harder deduplication when re-syncing fixtures.

Decision:

- Real sync should write both `externalFixtureId` and `rapidApiFixtureId` during the transition.
- Firestore document ID should remain stable, likely `football_${fixture.fixture.id}` unless a competition-season prefix is later required.

### 5. Confirm Team ID Mapping Policy

Status: must-have before real sync.

Why needed:

- Home and calendar queries depend on internal team IDs such as `kashima_antlers`.
- `syncFootball.ts` currently falls back to placeholder IDs like `football_team_{id}` when API team IDs are not mapped.
- J1 team master is now confirmed and seeded, so real sync should not create invisible placeholder teams for current J1 fixtures.

Likely affected files later:

- `functions/src/pipelines/syncFootball.ts`
- `functions/scripts/data/j1Teams.js`
- `functions/scripts/data/competitionRegistry.js`
- Real sync verify script

Risks if skipped:

- Followed teams will not match real synced games.
- Home may show no games even though fixtures exist.
- Calendar output may omit games for followed teams.

Decision:

- For current J1 sync, treat unmapped API team IDs as a verification failure or skipped fixture with explicit logging.
- Do not silently write placeholder team IDs for J1 production sync.

### 6. Review Status Mapping

Status: must-have before real sync writes are trusted; can be implemented after converter parity.

Why needed:

- `mapFootballStatus` maps API short codes into the app enum.
- Home multi-team query currently does not filter by status, while single-team query does filter `scheduled`.
- `GameCard` changes rendering based on `scheduled`, `live`, `finished`, `postponed`, and `cancelled`.

Likely affected files later:

- `functions/src/utils/timezone.ts`
- `lib/data/repositories/game_repository.dart` if query behavior is changed
- Real sync verify script

Risks if skipped:

- Postponed/cancelled/live/finished matches may display incorrectly.
- Home may include games that product logic should hide or separate.
- Calendar may include cancelled games unless explicitly filtered later.

Decision:

- Keep the current enum for now.
- Add real fixture status coverage tests/verification before relying on production sync.
- Decide separately whether Home should filter only `scheduled` for multi-follow queries.

### 7. Add Real Game Data Verification Script

Status: must-have before running non-dry real sync on important data.

Why needed:

- Sample games have a strong verify script.
- Real sync needs verification for mapped team IDs, required fields, status values, date windows, query behavior, and fixture ID compatibility.

Likely affected files later:

- New script under `functions/scripts/`
- `functions/package.json`
- Possibly shared helpers with `verifyJ1SampleGame.js`

Risks if skipped:

- Sync can write structurally valid but app-invisible games.
- Query/index problems may only appear during UI testing.
- Data regressions may be hard to diagnose.

Decision:

- Add this after converter and mapping rules are stable.
- It should support dry-run / read-only modes first.

## Deferred Items

| Item | Reason |
|---|---|
| `getCalendar` deploy and curl verification | Requires Blaze and production Function deployment; still deferred. |
| API-SPORTS scheduled sync deployment | Requires API key config and deploy; still deferred. |
| Broadcast platform ingestion | Source is not confirmed; current model supports it as optional data. |
| Team logos on `GameCard` | UI polish; model and sample data already support logo fields. |
| Venue/stadium master data | Useful later, not required for current Home / `.ics` behavior. |
| Full all-sports game abstraction | Better after J1 real sync has one reliable path. |

## First Implementation Target

Implement a minimal `competitionSeasonKey` / tournament profile foundation.

Suggested first slice:

1. Define a small competition season profile shape for `football_j1`.
2. Include `competitionKey`, `competitionSeasonKey`, display names, `externalLeagueId`, `apiSeason`, accessibility flag, start/end dates, and status.
3. Keep it local/config-driven at first.
4. Do not deploy or run API sync yet.
5. Update sample/verify or model reads only as needed after the shape is chosen.

Why this comes first:

- It unlocks explicit API season handling.
- It prevents calendar-year assumptions from leaking deeper into sync.
- It gives converter parity and real verification a stable target field to validate.

## Summary Order

1. Minimal `competitionSeasonKey` / tournament profile foundation.
2. Explicit API season handling from that profile.
3. `syncFootball.ts` conversion through `football_adapter.ts` with sample-game field parity.
4. External fixture ID compatibility (`externalFixtureId` + `rapidApiFixtureId`).
5. Strict API team ID to internal team ID mapping.
6. Status mapping verification.
7. Real game data verification script.
8. Only after the above: consider non-dry API sync / deploy path.
