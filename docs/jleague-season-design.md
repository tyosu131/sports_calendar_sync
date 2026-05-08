# J.League Season / Tournament Design

## Purpose

This document prevents future breakage when J.League naming, season timing, and tournament structure change. The app must keep stable internal identifiers separate from UI labels, API seasons, tournament names, team membership, and games.

## Problem

The app currently risks mixing different concepts:

- `competitionKey`
- display name
- Firestore league doc
- API league id
- API season
- tournament / season name
- team membership
- games

These concepts can change on different schedules. For example, the UI can say `Jリーグ` while the internal key remains `football_j1`, and a special tournament can use API season `2026` without meaning every current team can be derived from that API endpoint.

## Current Facts

- UI label: `Jリーグ`
- Stable `competitionKey`: `football_j1`
- Firestore league doc: `j1_league`
- API-SPORTS league id: `98`
- API-SPORTS Free plan can only use 2022-2024 season data for this endpoint, based on the observed plan error: `"Free plans do not have access to this season, try from 2022 to 2024."`
- 2024 API output is reference-only for API team IDs / logo URLs.
- Current J1 membership must be confirmed separately from an official or otherwise trusted source.

## Required Concepts

### competition

A stable sport / league category, such as `football_j1`.

### competition season / tournament profile

A concrete season or tournament instance, such as `football_j1_2026_hyakunen` or `football_j1_2026_27`.

### team master

Team identity independent of season, such as `kashima_antlers`.

### team membership

Which teams belong to which competition season or tournament.

### game

An actual match. A game should eventually point to both `competitionKey` and `competitionSeasonKey` or an equivalent season/tournament identifier.

## Proposed Future Data Shape

### `competitions/{competitionKey}`

- `competitionKey: football_j1`
- `displayNameJa: Jリーグ`
- `displayNameEn: J.League`
- `sportCategory: football`
- `defaultExternalLeagueId: 98`

### `competitionSeasons/{competitionSeasonKey}`

- `competitionSeasonKey: football_j1_2026_hyakunen`
- `competitionKey: football_j1`
- `displayNameJa: 明治安田Ｊリーグ百年構想リーグ`
- `displayNameEn: MEIJI YASUDA J.LEAGUE 100 YEAR VISION LEAGUE`
- `apiProvider: api-sports`
- `externalLeagueId: 98`
- `apiSeason: 2026`
- `apiAccessibleOnCurrentPlan: false`
- `startDate`
- `endDate`
- `status: active / upcoming / archived`

### `competitionSeasons/{competitionSeasonKey}/teamMemberships/{teamId}`

- `teamId`
- `competitionKey`
- `competitionSeasonKey`
- `status: active / promoted / relegated / reference-only`

### `games/{gameId}`

- `competitionKey`
- `competitionSeasonKey`
- `leagueId`
- `homeTeamId`
- `awayTeamId`
- `startTimeUTC`
- `startTimeJST`
- `status`

## Minimal Current Policy

For the current Spark plan route:

- Keep `competitionKey` as `football_j1`.
- Keep UI label as `Jリーグ`.
- Keep `j1Teams.js` as the team master scaffold.
- Add only confirmed team rows.
- Do not derive current membership from 2024 API output.
- Do not rely on current calendar year as source of truth.
- Treat API season as configurable and season/tournament-specific.

## What Not To Do

- Do not rename `football_j1` to `football_jleague`.
- Do not use display name as primary key.
- Do not treat 2024 teams as current J1 membership.
- Do not assume API season == current year.
- Do not mix team master and season membership.
- Do not hard-code tournament display names into core keys.

## Recommended Next Implementation Steps

1. Create current J1 team master review table from an official or confirmed source.
2. Match API team IDs / logos only where confirmed.
3. Add confirmed rows to `j1Teams.js`.
4. Run `seed:j1:teams` and `verify:j1:teams`.
5. Later introduce `competitionSeasonKey` / tournament profile when games or real schedule sync needs it.
