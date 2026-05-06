# Phase 0 — Change Summary

> Generated: 2026-04-29 (updated after follow-up fix)
> Purpose: Summarise all Phase 0 changes and list Phase 1 TODOs.

---

## Goals

1. **Registry-based competition list** — replace hard-coded enum with a single
   registry file that controls add / remove / reorder / enable / disable.
2. **Domain model extension** — add `competitionKey`, `externalFixtureId`,
   `favoriteTeamIdsByCompetition`, etc.
3. **Adapter layer** — establish a clear boundary between external API responses
   and domain models.
4. **API-SPORTS direct contract preparation** — document config key and HTTP
   header changes needed in Phase 1.
5. **Backward compatibility** — existing Firestore data and existing code must
   not break.

---

## Naming rationale: `competitionKey` not `sportKey`

`football_j1`, `football_premier`, `baseball_npb` etc. identify specific
competitions (leagues / tournaments), not generic sport categories.  Using
`sportKey` was misleading.

| Old name | New name | Firestore field |
|---|---|---|
| `sportKey` | `competitionKey` | `competitionKey` (new) + `sportKey` (legacy alias) |
| `SportKey` type (TS) | `CompetitionKey` type (TS) | — |
| `selectedSports` | `selectedCompetitions` | `selectedCompetitions` |
| `favoriteTeamIdsBySport` | `favoriteTeamIdsByCompetition` | `favoriteTeamIdsByCompetition` |
| `SportDefinition.key` | `SportDefinition.competitionKey` | — |
| `SportDefinition.category` | `SportDefinition.sportCategory` | — |

Legacy Firestore field `sportKey` is still written on every save so existing
queries continue to work.

---

## Fallback policy

**Removed** all "smart" inference fallbacks that mapped ambiguous data to a
specific competition key (e.g. `football → football_j1`).  Such inference
silently misclassifies data.

**Current policy**: if `competitionKey` / `sportKey` is absent in a Firestore
document, the field is read as `null`.  Callers must handle `null` explicitly.

---

## New files

| File | Description |
|---|---|
| `lib/domain/models/sport_definition.dart` | Competition definition class (registry entry) |
| `lib/core/config/sports_registry.dart` | 8-competition registry (J1, Premier, NPB, MLB, NBA, NFL, NHL, B.League) |
| `functions/src/adapters/football_adapter.ts` | API-SPORTS football → GameDoc adapter (Phase 0 placeholder) |
| `functions/src/adapters/README.md` | Adapter layer design notes |
| `docs/phase0-current-architecture.md` | Architecture overview |
| `docs/phase0-boundaries.md` | Firebase / AWS boundary + API-SPORTS config |
| `docs/phase0-summary.md` | This file |

---

## Changed files

### `lib/domain/models/game.dart`
- `competitionKey` (nullable) replaces `sportKey` (required String)
- `homeTeamNameEn` / `awayTeamNameEn` added
- `homeTeamLogoUrl` / `awayTeamLogoUrl` added
- `externalFixtureId` added; `rapidApiFixtureId` deprecated
- `fromFirestore`: reads `competitionKey` then falls back to `sportKey`; no
  inference from `leagueId`

### `lib/domain/models/team.dart`
- `competitionKey` (nullable) replaces `sportKey` (required String)
- `externalTeamId` added; `rapidApiId` deprecated
- `fromFirestore`: reads `competitionKey` then falls back to `sportKey`; no
  inference from `sportType`

### `lib/domain/models/sport.dart`
- `League.competitionKey` (nullable) replaces `League.sportKey` (required)
- `League.externalLeagueId` added; `rapidApiId` deprecated
- `League.sportDefinition` getter: returns null when `competitionKey` is null
- `SportType` enum kept for backward compatibility; marked deprecated
- `SportTypeExtension.sportCategory` replaces `.category`

### `lib/domain/models/user_profile.dart`
- `selectedCompetitions` replaces `selectedSports`
- `favoriteTeamIdsByCompetition` replaces `favoriteTeamIdsBySport`
- `followedTeamIds` kept as legacy field (written on save for `getCalendar`)
- `favoriteTeamIdsForCompetition()` / `hasCompetitionSelected()` added

### `functions/src/types.ts`
- `CompetitionKey` type added; `SportType` deprecated
- `GameDoc.competitionKey` added; `sportKey` kept as legacy alias
- `TeamDoc.competitionKey` / `externalTeamId` added
- `LeagueDoc.competitionKey` / `externalLeagueId` added
- `UserDoc.selectedCompetitions` / `favoriteTeamIdsByCompetition` added

---

## Phase 1 TODOs (not yet implemented)

### 1. `syncFootball.ts` — HTTP header change

```typescript
// Before (RapidAPI proxy)
const apiKey = functions.config().rapidapi?.key;
headers: { "x-rapidapi-key": apiKey, "x-rapidapi-host": "v3.football.api-sports.io" }

// After (API-SPORTS direct)
const apiKey = functions.config().apisports?.key;
headers: { "x-apisports-key": apiKey }
```

**File**: `functions/src/pipelines/syncFootball.ts`

### 2. Firebase Functions config

```bash
firebase functions:config:set apisports.key="YOUR_API_KEY"
```

### 3. Move `fixtureToGameDoc` into `football_adapter.ts`

`syncFootball.ts` still performs inline conversion.  Phase 1 should call
`adaptFootballFixtureToGameDoc` from `football_adapter.ts` instead.

### 4. `team_search_screen.dart` — use SportsRegistry

```dart
// Before
...SportType.values.map((s) => Tab(text: s.displayNameJa))

// After
...SportsRegistry.enabled.map((s) => Tab(text: s.displayNameJa))
```

---

## Backward compatibility guarantees

| Guarantee | Mechanism |
|---|---|
| Legacy Firestore reads | `fromFirestore` reads `competitionKey` then falls back to `sportKey` |
| Legacy Firestore writes | `toFirestore` writes both `competitionKey` and `sportKey` |
| `getCalendar` function | `followedTeamIds` is always written (= `allFavoriteTeamIds`) |
| Existing code compiles | Deprecated fields are kept, not removed |

---

## References

- `docs/phase0-current-architecture.md` — architecture detail
- `docs/phase0-boundaries.md` — Firebase / AWS boundary + API-SPORTS config
- `docs/e2e-minimum-setup.md` — E2E setup instructions
