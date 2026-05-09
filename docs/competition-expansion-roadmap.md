# Competition Expansion Roadmap

> Created: 2026-05-09  
> Scope: documentation-only roadmap before adding J2 / J3 or other competition seed data.

## Purpose

This document records the multi-competition expansion order for `sports_calendar_sync`. It keeps planning separate from implementation: no seed data, Firestore writes, deploys, or API sync should happen from this roadmap alone.

Current baseline:

- `football_j1` team master is seeded and verified.
- J1 sample games are seeded and verified.
- Football sync preparation now has competition season profiles, adapter-based `GameDoc` conversion, strict team ID mapping, status mapping verification, and real-game read verification.
- API-SPORTS real sync, Cloud Functions deploy, `.ics` curl verification, and Blaze decision remain deferred.

## Modeling Policy

- League, tournament, and cup competitions must be modeled separately from stable team master data.
- A team may belong to multiple competition seasons or tournaments.
- League membership is not permanent team master data.
- Team master data must stay stable across `football_j1`, `football_j2`, and `football_j3`.
- J.League division membership must be modeled per competition season.
- Promotion and relegation should move the same internal team ID between J1 / J2 / J3 season memberships, not create duplicate club documents.
- Internal `competitionKey` values should remain stable, explicit, and human-auditable.
- Cup and tournament competitions should use their own competition keys rather than being forced into league keys.
- Seed / verify workflows should support checking season membership separately from team identity.
- Real API availability must be verified before each competition moves from roadmap to seedable data.
- API IDs, team IDs, and logo URLs must be looked up or verified. Do not guess them.
- Uncertain teams must stay out of seed data until confirmed.
- Seed/verify work should start with dry-run paths. Do not write Firestore until the review table and dry-run output are approved.

## Phase 1: Football Expansion

Primary next implementation phase. Start with J.League lower divisions, then expand to major international leagues and UEFA competitions.

- `football_j2`
- `football_j3`
- `football_premier`
- `football_laliga`
- `football_seriea`
- `football_bundesliga`
- `football_ligue1`
- `football_ucl`
- `football_uel`
- `football_uecl`

### Phase 1A: J2 / J3 Scaffold

Recommended next implementation after this roadmap:

- Add competition registry entries for `football_j2` and `football_j3`.
- Create team master review docs for J2 / J3 without duplicating clubs already present in team master data.
- Add or design season membership review data separately from stable team identity.
- Add seed / verify dry-run path through the existing generic pipeline.
- Add dry-run verification that season membership references existing stable team IDs.
- Keep uncertain teams out of seed data.
- Do not write Firestore until membership and API ID / logo matches are confirmed.
- Do not enable API sync or deploy.

## Phase 2: Baseball Foundation

- `baseball_npb`
- `baseball_npb_farm`
- `baseball_mlb`
- `baseball_milb_aaa`

Baseball should get its own adapter and status mapping because innings, suspended/resumed games, doubleheaders, and probable pitchers differ from football.

## Phase 3: Basketball Foundation

- `basketball_bleague`
- `basketball_b2`
- `basketball_nba`
- `basketball_gleague`
- `basketball_ncaa`

Basketball seasons cross calendar years in several competitions, so competition season profiles should be required before real sync.

## Phase 4: American Football

- `american_football_nfl`
- `american_football_ncaa`

American football needs sport-specific status and season handling before real sync.

## Phase 5: Extras / Extended Competitions

- WEリーグ
- なでしこリーグ
- ルヴァンカップ
- 天皇杯
- ACL
- UEFA Champions League
- UEFA Europa League
- UEFA Conference League
- MLS
- K League
- KBO
- CPBL
- WNBA
- W League
- NHL
- F1

Some of these duplicate Phase 1 conceptually, but they remain listed here as product expansion candidates and should be normalized into stable `competitionKey` values before implementation.

## Product Idea: In-App Followed-Team Calendar

Add an in-app calendar view for followed teams only.

- This is separate from external `.ics` delivery.
- It should display only games involving teams the user follows.
- It can reuse the followed-team game query behavior already used by Home.
- Treat this as a future Flutter UI task, not part of the immediate backend expansion.

## Promotion Checklist

Before moving any roadmap competition into seedable data:

- Confirm official/current competition membership source.
- Confirm stable internal `competitionKey`.
- Confirm league / tournament / cup separation.
- Confirm whether the work is adding stable team identity, season membership, or both.
- Confirm promoted / relegated clubs reuse existing internal team IDs.
- Confirm API provider and API availability for the target season.
- Confirm external league ID, API season, team IDs, and logo URLs.
- Create review doc before seed data changes.
- Add dry-run seed / verify path.
- Run dry-run validation.
- Get approval before any Firestore write.
