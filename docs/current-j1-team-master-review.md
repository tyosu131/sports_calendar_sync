# Current J1 Team Master Review

## Purpose

This document is the review table used before adding confirmed current J1 teams to `functions/scripts/data/j1Teams.js`.

## Policy

- Only confirmed current J1 teams may be added to `j1Teams.js`.
- 2024 API output is reference-only.
- API team ID / logo URL must be confirmed before use.
- Team master is separate from competition season / tournament membership.
- `football_j1` remains the stable `competitionKey`.

## Required Fields for `j1Teams.js`

- `id`
- `nameJa`
- `nameEn`
- `aliases`
- `externalTeamId`
- `logoUrl`
- `source`
- `status: confirmed`

## Review Table

| status | nameJa | nameEn | doc id | externalTeamId | logoUrl | aliases | membership source | API match source | notes |
|---|---|---|---|---:|---|---|---|---|---|
| confirmed | 鹿島アントラーズ | Kashima | `kashima_antlers` | 290 | `https://media.api-sports.io/football/teams/290.png` | 鹿島, アントラーズ, Kashima Antlers, Antlers | existing seed / verified in repo | existing seed / verified in repo | Current repo baseline team |

## Pending Current J1 Teams

Do not fill this section with guessed data. Current J1 teams must be confirmed from an official/current source before they are added to `j1Teams.js`.

| status | nameJa | nameEn | doc id | externalTeamId | logoUrl | aliases | membership source | API match source | notes |
|---|---|---|---|---:|---|---|---|---|---|
| pending | 要確認 | 要確認 | 要確認 |  | 要確認 | 要確認 | official/current source required | API match required | Add one row per confirmed current J1 team during review |

## Next Steps

1. Confirm current J1 team list from official/current source.
2. Match API-SPORTS team ID and logo URL only where identity is confirmed.
3. Add confirmed rows to `j1Teams.js`.
4. Run generic seed/verify dry-run.
5. Run actual seed/verify only after approval.
