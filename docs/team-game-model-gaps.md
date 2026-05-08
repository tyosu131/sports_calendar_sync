# Team / Game Model Gaps

> Created: 2026-05-08  
> Scope: documentation-only inspection of Flutter models, repositories, UI, seed scripts, and Cloud Functions source.

## Purpose

This document records the current `Team` / `Game` data shape before adding real game data coverage or enabling API sync. It separates fields that already exist from fields that are missing, ambiguous, or should be deferred.

Current state:

- J1 20 team master data is seeded and verified.
- J1 sample games are seeded and verified.
- Home sample-game display and My Teams summary UI are manually verified.
- Blaze / `getCalendar` deploy / `.ics` curl / API-SPORTS sync remain deferred.

## Files Inspected

- `lib/domain/models/team.dart`
- `lib/domain/models/game.dart`
- `lib/data/repositories/team_repository.dart`
- `lib/data/repositories/game_repository.dart`
- `lib/presentation/widgets/game_card.dart`
- `lib/presentation/screens/home_screen.dart`
- `functions/scripts/data/j1Teams.js`
- `functions/scripts/seedJ1SampleGame.js`
- `functions/scripts/verifyJ1SampleGame.js`
- `functions/src/pipelines/syncFootball.ts`
- `functions/src/functions/getCalendar.ts`
- `functions/src/types.ts`
- `functions/src/adapters/football_adapter.ts`

## Current Team Shape

Flutter `Team` currently reads and writes:

| Field | Required | Notes |
|---|---:|---|
| `id` | yes | Firestore document ID. |
| `nameEn` | yes | Display/search field. |
| `nameJa` | yes | Primary Japanese display/search field. |
| `leagueId` | yes | Current J1 value: `j1_league`. |
| `competitionKey` | no | Preferred key, falls back from legacy `sportKey`. |
| `logoUrl` | no | Used by My Teams summary UI. |
| `country` | no | Seeded for J1 teams. |
| `externalTeamId` | no | Preferred API/provider team ID. |
| `rapidApiId` | no | Legacy alias for `externalTeamId`. |

Seeded J1 team docs also include derived compatibility/search fields via scripts:

- `competitionKey`
- `sportKey`
- `sportType`
- `dataSourceKey`
- `externalTeamId`
- `rapidApiId`
- `logoUrl`
- `searchKeywords`

## Current Game Shape

Flutter `Game` currently supports:

| Field | Required | Notes |
|---|---:|---|
| `id` | yes | Firestore document ID. |
| `competitionKey` | no | Preferred competition key; falls back from `sportKey`. |
| `leagueId` | yes | Current J1 value: `j1_league`. |
| `homeTeamId` / `awayTeamId` | yes | Used for followed-team game queries. |
| `homeTeamNameJa` / `awayTeamNameJa` | yes | Used by `GameCard` and calendar summary. |
| `homeTeamNameEn` / `awayTeamNameEn` | no | Written by sample games and adapter; useful fallback. |
| `homeTeamLogoUrl` / `awayTeamLogoUrl` | no | Supported by model but not currently displayed by `GameCard`. |
| `startTimeUTC` | yes | Firestore `Timestamp`; used for sorting, queries, and `.ics`. |
| `startTimeJST` | yes | Stored display string; current UI formats from `startTimeUTC` instead. |
| `timezone` | yes | Sample games use `Asia/Tokyo`; API sync may write API timezone. |
| `status` | yes | Flutter enum: `scheduled`, `live`, `finished`, `postponed`, `cancelled`. |
| `venue` | no | Displayed by `GameCard`; used as calendar location. |
| `homeScore` / `awayScore` | no | Displayed when status is `live` or `finished`. |
| `broadcastPlatforms` | yes | List of `{ platform, url?, note? }`; displayed as chips when non-empty. |
| `externalFixtureId` | no | Preferred provider fixture/game ID. |
| `rapidApiFixtureId` | no | Legacy alias for `externalFixtureId`. |

## Fields Actually Used by UI

### Home

`HomeScreen` uses:

- `followedTeamsProvider` for My Teams summary.
- `upcomingGamesForFollowedTeamsProvider` for upcoming games.
- Team fields shown in My Teams:
  - `logoUrl`
  - `nameJa`
  - `nameEn`
- Game fields passed into `GameCard`.

### Game Card

`GameCard` displays:

- `startTimeUTC` via `DateTimeUtils.formatJst(...)`
- `status`
- `homeTeamNameJa`
- `awayTeamNameJa`
- `homeScore` / `awayScore` for `live` or `finished`
- `venue`
- `broadcastPlatforms[].platform`

`GameCard` does not currently display:

- `homeTeamLogoUrl`
- `awayTeamLogoUrl`
- `competitionRound`
- `matchday`
- `competitionSeasonKey`
- `isNeutralVenue`

### Team Search / My Teams

Team search uses:

- `nameJa` prefix query
- `searchKeywords`
- `competitionKey` with legacy `sportKey` fallback

My Teams uses full team docs fetched by document ID, so followed teams can be visible even when they have no upcoming games.

## Fields Written by Sample Games

`functions/scripts/seedJ1SampleGame.js` writes:

- `leagueId`
- `competitionKey`
- `sportKey`
- `homeTeamId`
- `homeTeamNameJa`
- `homeTeamNameEn`
- `homeTeamLogoUrl`
- `awayTeamId`
- `awayTeamNameJa`
- `awayTeamNameEn`
- `awayTeamLogoUrl`
- `startTimeUTC`
- `startTimeJST`
- `timezone`
- `status`
- `venue`
- `homeScore: null`
- `awayScore: null`
- `broadcastPlatforms: []`
- `externalFixtureId`
- `rapidApiFixtureId`

`functions/scripts/verifyJ1SampleGame.js` validates the planned shape and, in non-dry mode, checks:

- document existence
- required fields
- UTC / JST consistency
- single-team home / away upcoming queries
- multi-follow home-screen query shape:
  - `homeTeamId in [followed team IDs]`
  - `awayTeamId in [followed team IDs]`
  - `startTimeUTC >= now`
  - `orderBy startTimeUTC`
  - no status filter, matching `GameRepository.fetchUpcomingGamesForTeams`

## Fields Written or Expected by Cloud Functions

### `syncFootball.ts`

The active inline conversion in `functions/src/pipelines/syncFootball.ts` writes:

- `leagueId`
- `homeTeamId`
- `homeTeamNameJa`
- `awayTeamId`
- `awayTeamNameJa`
- `startTimeUTC`
- `startTimeJST`
- `timezone`
- `status`
- `venue`
- `homeScore`
- `awayScore`
- `broadcastPlatforms: []`
- `rapidApiFixtureId`

Important gap: this inline conversion does not currently write:

- `competitionKey`
- `sportKey`
- `homeTeamNameEn`
- `awayTeamNameEn`
- `homeTeamLogoUrl`
- `awayTeamLogoUrl`
- `externalFixtureId`

### `football_adapter.ts`

`functions/src/adapters/football_adapter.ts` already defines a richer target shape and writes:

- `competitionKey`
- `sportKey`
- `homeTeamNameEn`
- `awayTeamNameEn`
- `homeTeamLogoUrl`
- `awayTeamLogoUrl`
- `externalFixtureId`
- `rapidApiFixtureId`

However, the file comment says `syncFootball.ts` still performs inline conversion. Before real sync, the adapter should become the single conversion path or the inline converter should be brought to parity.

### `getCalendar.ts`

`getCalendar` reads:

- user followed team IDs from `followedTeamIds`, falling back to `favoriteTeamIdsByCompetition`
- games by `homeTeamId` / `awayTeamId` with `startTimeUTC >= now`, ordered by `startTimeUTC`
- `homeTeamNameJa`
- `awayTeamNameJa`
- `startTimeUTC`
- `broadcastPlatforms`
- `venue`

It does not require logos, scores, round, or season profile fields for current `.ics` output.

## Gaps for Real J.League Game Data

### Must-Have Before Real Game Sync

| Gap | Why it matters |
|---|---|
| Sync converter parity with app model | Real sync should write `competitionKey`, `sportKey`, `externalFixtureId`, English names, and team logos consistently. |
| Season/tournament profile key | J.League has 2026 special competition and 2026/27 season complexity; real sync should not rely only on `new Date().getFullYear()`. |
| API season configurability | Current sync uses calendar year. API season must be competition-season specific. |
| Team ID mapping policy | API team IDs must map to confirmed `/teams/{teamId}` docs; placeholder `football_team_{id}` docs should be avoided or explicitly treated as unresolved. |
| Status mapping review | Confirm API-SPORTS status codes map cleanly to `scheduled`, `live`, `finished`, `postponed`, `cancelled`. |
| Duplicate external fixture handling | Use stable doc IDs and both `externalFixtureId` / `rapidApiFixtureId` compatibility during transition. |
| Query/index readiness | Home and calendar use home/away queries with `startTimeUTC`; real sync should preserve those fields exactly. |

### Nice-to-Have for UI Polish

| Gap | Why it helps |
|---|---|
| `competitionRound` / `matchday` / section | Enables display such as `第12節` or cup rounds. |
| Team logos on `GameCard` | `Game` already supports `homeTeamLogoUrl` / `awayTeamLogoUrl`; UI does not display them yet. |
| Venue normalization | `venue` string works, but stable venue/stadium IDs would help richer displays. |
| Broadcast platform data | Model and UI support chips, but sync currently writes empty arrays. |
| Neutral venue flag | Useful for cup finals, special venues, and non-home fixtures. |
| Kickoff uncertainty flags | Helpful when APIs provide TBD dates/times. |

### Should Defer

| Gap | Reason to defer |
|---|---|
| Full venue/stadium master data | Useful, but not required for upcoming game display or `.ics`. |
| Rich standings / table data | Separate product surface from calendar sync. |
| Player / roster / lineup data | Out of scope for calendar MVP. |
| Ticketing / broadcast deep links | Depends on source availability and commercial constraints. |
| Fully generic all-sports game model | Better to evolve after one real football sync path is reliable. |

## Gaps for Future Sports

### NPB / MLB

- Baseball uses innings, probable pitchers, doubleheaders, suspended/resumed games, and series context.
- Score shape may need more than `homeScore` / `awayScore` if inning-by-inning display is desired.
- Venue timezone is important for MLB.
- Team membership is season-specific but team identity remains stable.

### NBA

- NBA games have quarter/period status, arena timezone, and regular season / playoffs / play-in distinctions.
- Broadcast info may vary by region.
- `competitionSeasonKey` is important because seasons cross calendar years.

### Premier League

- Uses football-like fixture shape, but season crosses calendar years.
- `competitionSeasonKey` and API season handling are must-have.
- Matchweek / round display is important for UI polish.

## Recommended Direction

1. Keep `Team` as stable team identity.
2. Keep `Game` as match/event document, but add season/tournament metadata before real sync:
   - `competitionSeasonKey`
   - optional `competitionRound` / `matchday`
3. Use `football_adapter.ts` as the single API-SPORTS football conversion path.
4. Ensure real sync writes the same rich fields as sample games:
   - `competitionKey`
   - `sportKey`
   - English names
   - logo URLs
   - `externalFixtureId`
   - `rapidApiFixtureId`
5. Keep `homeTeamLogoUrl` / `awayTeamLogoUrl` duplicated on `Game` for feed performance and historical correctness, while retaining `Team.logoUrl` for team identity and My Teams.
6. Treat broadcast data as optional until a confirmed source exists.
7. Defer broader all-sports abstractions until J1 real data sync has one stable path.
