# Current J2 Team Master Review

## Purpose

This document is the review table used before adding confirmed stable J2 club identities to `functions/scripts/data/j2Teams.js`.

## Policy

- Do not treat J2 membership as permanent team master data.
- Team master data must stay stable across `football_j1`, `football_j2`, and `football_j3`.
- A club promoted or relegated between J1 / J2 / J3 must keep the same internal `/teams/{id}` document ID.
- Do not duplicate the same club as separate team docs per division.
- J2 division membership belongs in competition season membership data, not permanent team master data.
- `football_j2` remains the stable `competitionKey`.
- Only confirmed stable team identities may be added to `j2Teams.js`.
- API team ID / logo URL must be confirmed before use.
- Uncertain teams must stay out of seed data.

## Required Fields for Future `j2Teams.js` Entries

- `id`
- `nameJa`
- `nameEn`
- `aliases`
- `externalTeamId`
- `logoUrl`
- `source`
- `status: confirmed`

## Sources

- Official/current J2/J3 special competition source: <https://www.jleague.jp/special/2026specialseason/j2-j3/>
- Official/current J2/J3 standings source: <https://www.jleague.jp/standings/j2j3/>
- Season membership review: `docs/current-j2-j3-season-membership-review.md`
- API-SPORTS team ID / logo lookup source: 未確認
- Existing stable team master baseline: `functions/scripts/data/j1Teams.js`
- Season membership scaffold: `functions/scripts/data/competitionSeasonMemberships.js`

## 2026 J2 / J3 Special Competition Source

J.LEAGUE official sources identify the 2026 special competition as `明治安田Ｊ２・Ｊ３百年構想リーグ`.

- The competition combines J2 and J3 clubs.
- The regional league round is organized into four groups: `EAST-A`, `EAST-B`, `WEST-A`, and `WEST-B`.
- Each group contains 10 clubs.
- J.LEAGUE states that the J2/J3 special competition results do not cause promotion or relegation.
- This is season / tournament membership evidence only.
- It must not be treated as permanent J2 team master data.
- It does not by itself make any row seedable in `j2Teams.js`.
- API-SPORTS team IDs and logo URLs remain unverified.

## Review Table

Do not move rows into `j2Teams.js` until the club identity, API-SPORTS team ID, logo URL, and season membership source are confirmed.

| status | internal team id | club nameJa | club nameEn | externalTeamId | logoUrl | already exists in stable team master? | membership source | API match source | season membership note | unresolved items |
|---|---|---|---|---|---|---|---|---|---|---|
| pending | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | 要確認 | J.LEAGUE official J2/J3 special competition / standings source recorded in `docs/current-j2-j3-season-membership-review.md` | 未確認 | Add only as season membership after stable team identity is confirmed. | Stable team ID, API team ID, logo URL |

## Season Membership Scaffold

- `competitionKey`: `football_j2`
- `competitionSeasonKey`: `football_j2_membership_tbd`
- `season`: `TBD`
- `memberTeamIds`: empty until official/current membership is verified

Membership verification should eventually confirm that every `memberTeamIds` value references a stable `/teams/{id}` document. Promotion / relegation should move that same ID between J1 / J2 / J3 season memberships.

## Seed Status

- `functions/scripts/data/j2Teams.js` currently has no confirmed teams.
- `j2TeamsTodo` is review-only and ignored by generic seed / verify scripts.
- Generic seed / verify should be run with `--dry-run` until confirmed data is approved.
- No Firestore writes should happen from this review step.

## Next Steps

1. Confirm official/current J2 membership source.
2. Reuse existing internal team IDs for clubs already present in stable team master data.
3. Create new internal team IDs only for confirmed clubs not already present.
4. Match API-SPORTS team ID and logo URL only where identity is confirmed.
5. Add confirmed stable identities to `j2Teams.js`.
6. Add season membership separately after stable team IDs are confirmed.
7. Run generic seed / verify dry-run.
8. Run actual seed / verify only after approval.
