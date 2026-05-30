# Current J2 / J3 Season Membership Review

## Purpose

This document records official J.LEAGUE membership evidence for the 2026 `明治安田Ｊ２・Ｊ３百年構想リーグ`.

It is not seedable team master data. Every club row below remains `review` until stable internal team identity, API-SPORTS team ID, and logo URL are separately verified.

## Official Sources

- J.LEAGUE special page: <https://www.jleague.jp/special/2026specialseason/j2-j3/>
- J.LEAGUE official standings: <https://www.jleague.jp/standings/j2j3/>

Source confirmation notes:

- The special page identifies the competition as `明治安田Ｊ２・Ｊ３百年構想リーグ`.
- The regional league round uses four groups: `EAST-A`, `EAST-B`, `WEST-A`, and `WEST-B`.
- Each group contains 10 clubs.
- The standings page provides the current group tables.
- J.LEAGUE states that the J2/J3 special competition results do not cause promotion or relegation.
- The 2026 J2/J3 special competition should be modeled as season / tournament membership evidence, not permanent J2 or J3 team master data.

## Modeling Policy

- Stable club identity stays in `/teams/{id}`.
- Division or tournament membership belongs in competition season membership data.
- Promoted or relegated clubs should reuse the same internal team ID across J1 / J2 / J3.
- Do not duplicate club docs per division.
- Do not add these rows to `j2Teams.js` or `j3Teams.js` until stable identity and API / logo verification are complete.
- Do not infer API-SPORTS team IDs or logo URLs from these official J.LEAGUE pages.

## J2 / J3 Multi-Year Season Membership Data Design

This section defines a docs-only design for J2 / J3 season membership data that can be reused beyond the 2026 `明治安田Ｊ２・Ｊ３百年構想リーグ`.

This is not actual seed data, a Firestore write, a source code change, an API call, an API sync, a deploy change, or a non-dry seed execution.

### Design Goal

- Model 2026 special tournament membership and 2027 / 2028+ normal seasons or other tournaments with the same structure.
- Keep stable team master data separate from season / tournament membership data.
- Treat `/teams/{id}` as the stable club identity. Promotion / relegation must reuse the same internal team ID.
- Do not create duplicate club docs per division, year, group, or tournament.
- Keep division, group, tournament, and year membership on `competitionSeasonKey` scoped data.
- Keep `reilac_shiga` / `Biwako Shiga` excluded from confirmed entry / seedable candidates until continuity approval is completed.

### Proposed Key Concepts

| Field | Examples | Meaning |
|---|---|---|
| `competitionKey` | `football_j2`, `football_j3`, `football_j2_j3_special` | Competition family / display bucket. It should not duplicate stable club identity. |
| `competitionSeasonKey` | `football_j2_j3_2026_hyakunen`, `football_j2_2027`, `football_j3_2027` | Specific season / tournament / format key. This is the primary scope for membership rows. |
| `seasonYear` | `2026`, `2027`, `2028` | Calendar / competition year for the season profile. |
| `membershipType` | `league`, `special_tournament`, `cup`, `playoff` | Format of the membership set. |
| `groupKey` | `east_a`, `east_b`, `west_a`, `west_b`, `null` | Optional group within a season. Omit or set to `null` for normal leagues without groups. |
| `teamId` | `jubilo_iwata`, `fc_gifu` | Stable `/teams/{id}` reference. |
| `source` | official source URL, API evidence note, review document section | Evidence trail for why a team is included in the season membership. |
| `status` | `review`, `approved`, `seedable`, `seeded` | Review / execution state of the membership row or season profile. |

Notes:

- `competitionKey` is not enough to identify a specific year. Use `competitionSeasonKey` for season-scoped membership.
- A team can appear under different `competitionSeasonKey` values over time while keeping the same `teamId`.
- 2026 group membership is season / tournament evidence only. It does not mean permanent J2 or J3 division membership.
- Future J2 / J3 normal seasons can use the same design without groups.

### Proposed Data Shape

The following is an example data-only object structure. Do not create this file or seed it from this document alone.

```js
{
  competitionSeasonKey: 'football_j2_j3_2026_hyakunen',
  seasonYear: 2026,
  competitionKey: 'football_j2_j3_special',
  displayNameJa: '明治安田Ｊ２・Ｊ３百年構想リーグ',
  membershipType: 'special_tournament',
  groups: [
    {
      groupKey: 'east_a',
      displayNameJa: 'EAST-A',
      teamIds: [
        'vegalta_sendai',
        'shonan_bellmare',
      ],
    },
  ],
  source: {
    official: [
      'https://www.jleague.jp/special/2026specialseason/j2-j3/',
      'https://www.jleague.jp/standings/j2j3/',
    ],
    reviewDocument: 'docs/current-j2-j3-season-membership-review.md',
  },
  status: 'review',
}
```

A normal league season without groups could omit `groups` and use flat membership rows.

```js
{
  competitionSeasonKey: 'football_j2_2027',
  seasonYear: 2027,
  competitionKey: 'football_j2',
  displayNameJa: '明治安田Ｊ２リーグ',
  membershipType: 'league',
  teamIds: [
    '...',
  ],
  source: {
    official: [
      'TBD',
    ],
    reviewDocument: 'docs/current-j2-j3-season-membership-review.md',
  },
  status: 'review',
}
```

### Review / Seed Flow

- Add or update stable team master entries only after stable identity, API team ID, and logo URL evidence are approved together.
- Add season membership rows only after the relevant `teamId` exists as a confirmed stable identity.
- Keep membership rows in `review` until official source evidence and target season profile are reviewed.
- Move to `approved` only after the season membership is checked against stable team IDs and no duplicate club docs are introduced.
- Move to `seedable` only after a separate exact diff plan and approval.
- Move to `seeded` only after a separately approved Firestore write or non-dry seed.
- Firestore write, non-dry seed, API sync, and deploy remain deferred for this design step.

## J2 / J3 Season Membership Exact Data Module Plan

This section records a docs-only exact data module plan for future J2 / J3 season membership data.

It does not edit `functions/scripts/data/competitionSeasonMemberships.js`, create actual source code changes, create seed data, write Firestore documents, run a non-dry seed, call an API, run API sync, or deploy.

Summary:

- Target future module: `functions/scripts/data/competitionSeasonMemberships.js`
- Actual file entries added: 0
- Firestore writes: 0
- non-dry seed: 0
- API calls: 0
- deploy: 0
- `reilac_shiga` included as confirmed/seedable: no

### Planned Module Responsibility

- `competitionSeasonMemberships.js` should be a data-only module for season / tournament membership, not stable team master data.
- `j2Teams.js` / `j3Teams.js` / `j1Teams.js` remain stable team identity master modules and must not directly represent group membership.
- `competitionSeasonMemberships.js` should manage season profiles and membership rows scoped by `competitionSeasonKey`.
- 2026 `EAST-A` / `EAST-B` / `WEST-A` / `WEST-B` are season / tournament group metadata, not team master fields.
- 2027 / 2028+ normal J2 / J3 seasons or other tournaments should use the same structure with new `competitionSeasonKey` values.
- Promotion / relegation should be represented by adding a membership row under a new `competitionSeasonKey` while reusing the same stable `teamId`.

### Planned Export Shape

The planned module shape is below. Do not create or edit the actual file from this document alone.

```js
'use strict';

const competitionSeasonMemberships = [
  {
    competitionSeasonKey: 'football_j2_j3_2026_hyakunen',
    seasonYear: 2026,
    competitionKey: 'football_j2_j3_special',
    displayNameJa: '明治安田Ｊ２・Ｊ３百年構想リーグ',
    membershipType: 'special_tournament',
    source: {
      official: [
        'https://www.jleague.jp/special/2026specialseason/j2-j3/',
        'https://www.jleague.jp/standings/j2j3/',
      ],
      reviewDocument: 'docs/current-j2-j3-season-membership-review.md',
    },
    groups: [
      {
        groupKey: 'east_a',
        displayNameJa: 'EAST-A',
        teamIds: [],
      },
      {
        groupKey: 'east_b',
        displayNameJa: 'EAST-B',
        teamIds: [],
      },
      {
        groupKey: 'west_a',
        displayNameJa: 'WEST-A',
        teamIds: [],
      },
      {
        groupKey: 'west_b',
        displayNameJa: 'WEST-B',
        teamIds: [],
      },
    ],
    status: 'review',
    seedable: false,
  },
];

module.exports = {
  competitionSeasonMemberships,
};
```

### Planned Membership Row Shape

The grouped structure above should also be expandable to one row per team membership when validation or seed preparation needs flat rows.

```js
{
  competitionSeasonKey: 'football_j2_j3_2026_hyakunen',
  seasonYear: 2026,
  competitionKey: 'football_j2_j3_special',
  membershipType: 'special_tournament',
  groupKey: 'east_a',
  teamId: 'vegalta_sendai',
  teamIdStatus: 'confirmed_team_master',
  membershipStatus: 'review',
  seedable: false,
  source: 'J.LEAGUE official 2026 special season page + docs/current-j2-j3-season-membership-review.md',
}
```

### Team ID Status Policy

| teamIdStatus | Meaning | Seedable implication |
|---|---|---|
| `confirmed_team_master` | `teamId` exists as a confirmed team master entry in `j2Teams.js`, `j3Teams.js`, or `j1Teams.js`. | May become seedable only after membership review and separate approval. |
| `candidate_not_confirmed` | `teamId` exists only as a documentation candidate and has not become an actual team module entry. | Not seedable. |
| `blocked_continuity` | `teamId` is blocked by unresolved continuity review, such as `reilac_shiga` / `Biwako Shiga`. | Not seedable. |
| `missing_team_master` | Season membership evidence exists, but the stable team master identity is not yet confirmed. | Not seedable. |

### 2026 Planned Group Membership Table

This table is a docs-only plan for the 2026 special season. It is not actual seed data. `seedable` is `false` for every row at this planning stage.

| groupKey | teamId | teamIdStatus | seedable |
|---|---|---|---|
| `east_a` | `vegalta_sendai` | `confirmed_team_master` | false |
| `east_a` | `shonan_bellmare` | `confirmed_team_master` | false |
| `east_a` | `blaublitz_akita` | `confirmed_team_master` | false |
| `east_a` | `sc_sagamihara` | `candidate_not_confirmed` | false |
| `east_a` | `yokohama_fc` | `confirmed_team_master` | false |
| `east_a` | `montedio_yamagata` | `confirmed_team_master` | false |
| `east_a` | `thespa_gunma` | `candidate_not_confirmed` | false |
| `east_a` | `tochigi_city` | `confirmed_team_master` | false |
| `east_a` | `tochigi_sc` | `confirmed_team_master` | false |
| `east_a` | `vanraure_hachinohe` | `confirmed_team_master` | false |
| `east_b` | `ventforet_kofu` | `confirmed_team_master` | false |
| `east_b` | `iwaki_fc` | `candidate_not_confirmed` | false |
| `east_b` | `rb_omiya_ardija` | `candidate_not_confirmed` | false |
| `east_b` | `hokkaido_consadole_sapporo` | `candidate_not_confirmed` | false |
| `east_b` | `fujieda_myfc` | `confirmed_team_master` | false |
| `east_b` | `fc_gifu` | `confirmed_team_master` | false |
| `east_b` | `matsumoto_yamaga` | `confirmed_team_master` | false |
| `east_b` | `jubilo_iwata` | `confirmed_team_master` | false |
| `east_b` | `fukushima_united` | `confirmed_team_master` | false |
| `east_b` | `ac_nagano_parceiro` | `candidate_not_confirmed` | false |
| `west_a` | `kataller_toyama` | `confirmed_team_master` | false |
| `west_a` | `tokushima_vortis` | `candidate_not_confirmed` | false |
| `west_a` | `albirex_niigata` | `candidate_not_confirmed` | false |
| `west_a` | `kochi_united` | `candidate_not_confirmed` | false |
| `west_a` | `ehime_fc` | `candidate_not_confirmed` | false |
| `west_a` | `zweigen_kanazawa` | `candidate_not_confirmed` | false |
| `west_a` | `fc_osaka` | `candidate_not_confirmed` | false |
| `west_a` | `fc_imabari` | `candidate_not_confirmed` | false |
| `west_a` | `nara_club` | `candidate_not_confirmed` | false |
| `west_a` | `kamatamare_sanuki` | `candidate_not_confirmed` | false |
| `west_b` | `tegevajaro_miyazaki` | `candidate_not_confirmed` | false |
| `west_b` | `sagan_tosu` | `candidate_not_confirmed` | false |
| `west_b` | `kagoshima_united` | `candidate_not_confirmed` | false |
| `west_b` | `renofa_yamaguchi` | `candidate_not_confirmed` | false |
| `west_b` | `roasso_kumamoto` | `candidate_not_confirmed` | false |
| `west_b` | `oita_trinita` | `candidate_not_confirmed` | false |
| `west_b` | `gainare_tottori` | `candidate_not_confirmed` | false |
| `west_b` | `giravanz_kitakyushu` | `candidate_not_confirmed` | false |
| `west_b` | `reilac_shiga` | `blocked_continuity` | false |
| `west_b` | `fc_ryukyu` | `candidate_not_confirmed` | false |

### Current Confirmed Team Master Coverage

Confirmed `football_j2` team master entries: 10

- `vegalta_sendai`
- `shonan_bellmare`
- `blaublitz_akita`
- `yokohama_fc`
- `montedio_yamagata`
- `tochigi_city`
- `tochigi_sc`
- `ventforet_kofu`
- `fujieda_myfc`
- `jubilo_iwata`

Confirmed `football_j3` team master entries: 5

- `vanraure_hachinohe`
- `fc_gifu`
- `matsumoto_yamaga`
- `fukushima_united`
- `kataller_toyama`

### Seedability Policy

- Season membership rows are not seedable until the referenced `teamId` exists as confirmed stable team master data.
- `candidate_not_confirmed` rows are not seedable.
- `blocked_continuity` rows are not seedable.
- `reilac_shiga` remains excluded from confirmed / seedable rows until continuity approval is completed.
- Group metadata can be planned before every team is confirmed, but Firestore seed must wait until referenced team IDs are safe.
- Firestore write / non-dry seed requires separate approval.

### Planned Validation Policy

After actual `competitionSeasonMemberships.js` entries are added in a later approved step, validation should check:

- `node --check functions/scripts/data/competitionSeasonMemberships.js`
- season profile has unique `competitionSeasonKey`
- group keys are unique within a season
- every group has expected number of teams for 2026 special season
  - `EAST-A`: 10
  - `EAST-B`: 10
  - `WEST-A`: 10
  - `WEST-B`: 10
- no duplicate `teamId` within a `competitionSeasonKey`
- all seedable rows reference confirmed stable team master entries
- blocked / unconfirmed rows must not be seedable
- `reilac_shiga` must remain non-seedable until continuity approval
- Firestore write must remain separate from validation

### Future-Year Examples

- `football_j2_2027`
  - `membershipType`: `league`
  - `groupKey`: `null` or omitted
- `football_j3_2027`
  - `membershipType`: `league`
  - `groupKey`: `null` or omitted
- `football_j2_2028` / `football_j3_2028` can use the same pattern.
- Promoted / relegated clubs are represented by adding a new membership row under a new `competitionSeasonKey`, while keeping the same `teamId`.

### Next-Step Recommendation

- First, commit / push this docs-only exact data module plan.
- Next, reflect the result in `docs/current-state.md`.
- Then, with separate approval, add actual entries to `functions/scripts/data/competitionSeasonMemberships.js`.
- After that, add a season membership verify script or extend an existing verify flow.
- Firestore write / non-dry seed remains the final separately approved step.

## J2 / J3 Season Membership Verification Plan

This section records a docs-only verification plan for future J2 / J3 season membership data.

It does not create a verify script, edit source code, create seed data, write Firestore documents, run a non-dry seed, call an API, run API sync, or deploy.

### Verification Target

- Future module: `functions/scripts/data/competitionSeasonMemberships.js`
- Future verify script candidate: `functions/scripts/verifyCompetitionSeasonMemberships.js`
- This step does not create the verify script.
- This step is a docs-only verification plan.

### Required Validation Checks

Future validation should check:

- `node --check functions/scripts/data/competitionSeasonMemberships.js`
- module exports `competitionSeasonMemberships`
- each season profile has required fields:
  - `competitionSeasonKey`
  - `seasonYear`
  - `competitionKey`
  - `displayNameJa`
  - `membershipType`
  - `source`
  - `status`
  - `seedable`
- `competitionSeasonKey` is unique across profiles
- `seasonYear` is a number
- `membershipType` is one of:
  - `league`
  - `special_tournament`
  - `cup`
  - `playoff`
- `status` is one of:
  - `review`
  - `approved`
  - `seedable`
  - `seeded`
- `seedable` is boolean

### Group Validation Checks

For the 2026 special season:

- `football_j2_j3_2026_hyakunen` has exactly 4 groups:
  - `east_a`
  - `east_b`
  - `west_a`
  - `west_b`
- group keys are unique within a season
- each group has exactly 10 team IDs
- total teams across all groups is 40
- no duplicate `teamId` within the same `competitionSeasonKey`
- group metadata is season / tournament data, not stable team master data

### Team Master Reference Checks

- `teamIdStatus: confirmed_team_master` rows must reference actual confirmed team IDs from:
  - `j1Teams.js`
  - `j2Teams.js`
  - `j3Teams.js`
- `candidate_not_confirmed` rows must not be seedable.
- `blocked_continuity` rows must not be seedable.
- `missing_team_master` rows must not be seedable.
- `reilac_shiga` must remain `blocked_continuity` and `seedable: false` until continuity approval is completed.
- seedable rows must never reference unconfirmed or blocked team IDs.

### Seedability Validation Policy

- A season profile can be planned with unconfirmed teams, but it must remain `seedable: false`.
- A row or season can become seedable only after all referenced `teamId` values are confirmed stable team master entries.
- Firestore write / non-dry seed requires separate approval even if validation passes.
- Validation passing does not mean Firestore seed approval.

### Future-Year Validation

- Normal league season profiles such as `football_j2_2027` / `football_j3_2027` may omit `groups`.
- Normal league season profiles may use flat `teamIds` or membership rows.
- If `groupKey` is omitted or `null`, group count validation should not apply.
- Promoted / relegated clubs should keep the same stable `teamId`.
- A club moving divisions should appear under a new `competitionSeasonKey`, not as a duplicate `/teams/{id}`.

### Dry-Run Behavior

If a future verify script is created:

- default mode should be read-only
- dry-run must not initialize Firebase Admin SDK
- dry-run must not read or write Firestore
- validation should run against local data modules only
- Firestore write must remain separate from validation

### Expected First Actual Validation Commands

After actual module entries are added in a separately approved step, expected validation commands are:

```bash
node --check functions/scripts/data/competitionSeasonMemberships.js
node functions/scripts/verifyCompetitionSeasonMemberships.js --dry-run
npm --prefix functions run build
flutter analyze --no-pub
```

### Current Known Expected Values

- `football_j2_j3_2026_hyakunen`
  - groups: 4
  - teams per group: 10
  - total teams: 40
- current confirmed team master coverage:
  - `football_j2`: 10
  - `football_j3`: 5
- `reilac_shiga`
  - `teamIdStatus`: `blocked_continuity`
  - `seedable`: false

### Verification Plan Next-Step Recommendation

- First, commit / push this docs-only verification plan.
- Next, reflect the result in `docs/current-state.md`.
- Then, with separate approval, add actual entries to `functions/scripts/data/competitionSeasonMemberships.js`.
- After that, add `functions/scripts/verifyCompetitionSeasonMemberships.js` or extend an existing verify flow.
- Firestore write / non-dry seed remains the final separately approved step.

## J2 / J3 Season Membership Verify Script Exact Diff Plan

This section records a docs-only exact diff plan for a future J2 / J3 season membership verify script.

It does not create the verify script, edit source code, create seed data, write Firestore documents, run a non-dry seed, call an API, run API sync, or deploy.

### Verify Script Exact Diff Plan Summary

- docs-only exact diff plan: yes
- target future script: `functions/scripts/verifyCompetitionSeasonMemberships.js`
- target future data module: `functions/scripts/data/competitionSeasonMemberships.js`
- actual verify script added: 0
- actual data module entries added: 0
- Firestore reads: 0
- Firestore writes: 0
- non-dry seed: 0
- API calls: 0
- deploy: 0
- `reilac_shiga` seedable: false

### Planned Script Responsibility

- Validate local data modules only.
- Do not initialize Firebase Admin SDK.
- Do not read or write Firestore.
- Do not call external APIs.
- Validate `competitionSeasonMemberships.js` structure, duplicates, seedability, and team master references.
- Validation passing does not mean Firestore seed approval.

### Planned File Path

- `functions/scripts/verifyCompetitionSeasonMemberships.js`

### Planned CLI Behavior

- default: dry-run / read-only
- `--dry-run` supported
- `--season <competitionSeasonKey>` optional
- no Firebase Admin SDK initialization
- no Firestore read/write
- exit code 0 on pass
- exit code 1 on validation failure

### Planned Validation Checks

- require `functions/scripts/data/competitionSeasonMemberships.js`
- module exports `competitionSeasonMemberships`
- `competitionSeasonMemberships` is an array
- each season profile has required fields:
  - `competitionSeasonKey`
  - `seasonYear`
  - `competitionKey`
  - `displayNameJa`
  - `membershipType`
  - `source`
  - `status`
  - `seedable`
- `competitionSeasonKey` is unique
- `seasonYear` is number
- `membershipType` is one of:
  - `league`
  - `special_tournament`
  - `cup`
  - `playoff`
- `status` is one of:
  - `review`
  - `approved`
  - `seedable`
  - `seeded`
- `seedable` is boolean

### Planned 2026 Special Season Checks

- `football_j2_j3_2026_hyakunen` has 4 groups
- required group keys:
  - `east_a`
  - `east_b`
  - `west_a`
  - `west_b`
- each group has exactly 10 team IDs
- total team IDs: 40
- no duplicate team IDs within the same `competitionSeasonKey`
- group metadata must remain season / tournament metadata, not team master data

### Planned Team Master Reference Checks

- read local confirmed team master IDs from:
  - `functions/scripts/data/j1Teams.js`
  - `functions/scripts/data/j2Teams.js`
  - `functions/scripts/data/j3Teams.js`
- `confirmed_team_master` rows must reference one of those confirmed team IDs
- `candidate_not_confirmed` rows must not be seedable
- `blocked_continuity` rows must not be seedable
- `missing_team_master` rows must not be seedable
- `reilac_shiga` must remain `blocked_continuity` and `seedable: false`
- seedable rows must not reference unconfirmed or blocked team IDs

### Planned Output Format

- print checked season count
- print checked group count
- print checked membership row count
- print confirmed team reference count
- print blocked / unconfirmed row count
- print clear PASS / FAIL result
- on failure, print exact reason and affected `competitionSeasonKey`, `groupKey`, `teamId`

### Planned First Validation Commands

```bash
node --check functions/scripts/data/competitionSeasonMemberships.js
node --check functions/scripts/verifyCompetitionSeasonMemberships.js
node functions/scripts/verifyCompetitionSeasonMemberships.js --dry-run
npm --prefix functions run build
flutter analyze --no-pub
```

## J2 / J3 Season Membership Seed Script Design Plan

This section records a docs-only design / exact diff plan for a future J2 / J3 season membership seed script.

It does not create the seed script, edit source code, create seed data, write Firestore documents, run a non-dry seed, call an API, run API sync, or deploy. Validation passing does not mean Firestore seed approval.

### Seed Script Design Plan Summary

- docs-only seed script design plan: yes
- target future script: `functions/scripts/seedCompetitionSeasonMemberships.js`
- target data module: `functions/scripts/data/competitionSeasonMemberships.js`
- target verify script: `functions/scripts/verifyCompetitionSeasonMemberships.js`
- actual seed script added: 0
- package.json changes: 0
- Firestore reads: 0
- Firestore writes: 0
- non-dry seed: 0
- API calls: 0
- deploy: 0
- `football_j2_j3_2026_hyakunen` current status: `review`
- `football_j2_j3_2026_hyakunen` current seedable: false
- `reilac_shiga` seedable: false
- this plan is not Firestore seed approval

### Planned Responsibility

- Read local `competitionSeasonMemberships.js`.
- Only seed season profiles that are seedable.
- Exclude `seedable: false` season profiles from non-dry seed.
- Exclude `status: review` season profiles from non-dry seed.
- Exclude season profiles that contain `candidate_not_confirmed`, `blocked_continuity`, or `missing_team_master`.
- Run validation equivalent to `verifyCompetitionSeasonMemberships.js --dry-run` before seed.
- Validation passing is not seed approval.
- Firestore write is allowed only after explicit approval.

### Planned Firestore Shape

Candidate collection:

- `competitionSeasonMemberships/{competitionSeasonKey}`

Candidate document fields:

- `competitionSeasonKey`
- `seasonYear`
- `competitionKey`
- `displayNameJa`
- `membershipType`
- `status`
- `seedable`
- `source`
- `groups`
- `createdAt`
- `updatedAt`

Groups shape:

- `groupKey`
- `displayNameJa`
- `teamIds`

Notes:

- `/teams/{id}` is stable team master.
- Season membership must not duplicate `/teams/{id}` documents.
- Group metadata is not team master data.
- 2026 special season group keys `east_a`, `east_b`, `west_a`, and `west_b` are season / tournament metadata.

### Planned CLI Behavior

- default: dry-run
- `--dry-run` supported
- `--season <competitionSeasonKey>` supported
- `--allow-review` should not be created, or should remain unused for now
- non-dry mode requires an explicit flag, for example `--write`
- do not write Firestore unless `--write` is present
- do not write `seedable: false` profiles even when `--write` is present
- do not write seasons that contain blocked or unconfirmed teams even when `--write` is present
- exit code 0 on pass
- exit code 1 on validation or seedability failure

### Planned Pre-Seed Checks

- `node --check functions/scripts/data/competitionSeasonMemberships.js`
- `node --check functions/scripts/verifyCompetitionSeasonMemberships.js`
- `node functions/scripts/verifyCompetitionSeasonMemberships.js --dry-run`
- `node functions/scripts/verifyCompetitionSeasonMemberships.js --dry-run --season <competitionSeasonKey>`
- season profile `seedable === true`
- season profile `status` is in a seed-allowed state
- all team IDs are `confirmed_team_master`
- all team IDs exist in local confirmed team master data
- no `candidate_not_confirmed`
- no `blocked_continuity`
- no `missing_team_master`
- exclude `reilac_shiga` / `Biwako Shiga` until continuity approval is completed

### Current Non-Seedable Reason

Do not seed `football_j2_j3_2026_hyakunen` yet because:

- `status: review`
- `seedable: false`
- confirmed team references: 15 of 40 teamIds
- blocked / unconfirmed rows: 25
- `reilac_shiga` is `blocked_continuity`
- `reilac_shiga` / `Biwako Shiga` continuity approval is not completed
- local validation is passing, but this is not Firestore seed approval

### Future Implementation Order

1. Commit / push this docs-only seed script design plan.
2. Reflect this same docs-only planning step in `docs/current-state.md`.
3. With separate approval, decide whether to create actual `seedCompetitionSeasonMemberships.js`.
4. If the actual seed script is created, start with default dry-run / no Firestore write behavior.
5. Decide whether to change `seedable: true` only with separate approval.
6. Keep Firestore write / non-dry seed as the final separately approved step.

### Explicit Deferred Items

- Firestore write
- non-dry seed
- API sync
- deploy
- serviceAccountKey work
- API key work
- `reilac_shiga` continuity approval
- `football_j2_j3_2026_hyakunen` seed approval

## Review Fields

- `status`: `review` means official membership evidence exists, but the row is not seedable.
- `group`: J.LEAGUE official regional group.
- `club nameJa`: Club name shown by J.LEAGUE official standings.
- `internal team id`: `TBD` until stable team identity is reviewed against existing team master data.
- `externalTeamId`: `TBD` until API-SPORTS lookup is verified.
- `logoUrl`: `TBD` until logo source is verified.
- `seedable`: always `no` in this review document.

## Stable Internal Team ID Mapping Summary

Compared against existing confirmed stable team identities in `functions/scripts/data/j1Teams.js`.

Note: this summary records the state at the stable internal team ID mapping review step. Later API-SPORTS team ID / logo URL lookup evidence is tracked separately in the `API-SPORTS Verification Tracker` below. The seedable status remains `no` for every row.

- Total membership rows: 40
- Matched to existing stable J1 team master: 0
- Requiring new stable internal team ID review: 40
- Existing stable team IDs reused: none
- Documentation-only candidate internal team IDs proposed: 40
- Confirmed internal team IDs: 0
- API-SPORTS IDs verified: 0
- Logo URLs verified: 0
- Seedable rows: 0
- `externalTeamId`: remains `TBD` for every row
- `logoUrl`: remains `TBD` for every row
- `seedable`: remains `no` for every row

Matched existing team IDs:

- None

Unresolved clubs requiring stable identity review:

- ベガルタ仙台
- 湘南ベルマーレ
- ブラウブリッツ秋田
- ＳＣ相模原
- 横浜ＦＣ
- モンテディオ山形
- ザスパ群馬
- 栃木シティ
- 栃木ＳＣ
- ヴァンラーレ八戸
- ヴァンフォーレ甲府
- いわきＦＣ
- ＲＢ大宮アルディージャ
- 北海道コンサドーレ札幌
- 藤枝ＭＹＦＣ
- ＦＣ岐阜
- 松本山雅ＦＣ
- ジュビロ磐田
- 福島ユナイテッドＦＣ
- ＡＣ長野パルセイロ
- カターレ富山
- 徳島ヴォルティス
- アルビレックス新潟
- 高知ユナイテッドＳＣ
- 愛媛ＦＣ
- ツエーゲン金沢
- ＦＣ大阪
- ＦＣ今治
- 奈良クラブ
- カマタマーレ讃岐
- テゲバジャーロ宮崎
- サガン鳥栖
- 鹿児島ユナイテッドＦＣ
- レノファ山口ＦＣ
- ロアッソ熊本
- 大分トリニータ
- ガイナーレ鳥取
- ギラヴァンツ北九州
- レイラック滋賀ＦＣ
- ＦＣ琉球

This is not seedable data yet. Stable identity review, API-SPORTS team ID verification, and logo URL verification must be completed before any row can move into `j2Teams.js` or `j3Teams.js`.

## Candidate Name Verification

Candidate internal team IDs were reviewed against J.LEAGUE English club/profile naming and commonly used romanized club names. This verification checks only whether the documentation-only candidate ID is a reasonable stable snake_case slug for the club identity.

- Total candidate IDs reviewed: 40
- Candidate IDs kept unchanged: 40
- Candidate IDs changed: 0
- Candidate IDs requiring further review: 0
- Confirmed internal IDs: 0
- API-SPORTS IDs verified: 0
- Logo URLs verified: 0
- Seedable rows: 0

Review notes:

- Candidate IDs do not encode J2 / J3 division or temporary 2026 group membership.
- Candidate IDs are based on stable club identity and should remain usable across promotion / relegation if later confirmed.
- `ＲＢ大宮アルディージャ` keeps `rb_omiya_ardija` to reflect current J.LEAGUE English branding as RB Omiya Ardija.
- `レイラック滋賀ＦＣ` keeps `reilac_shiga` as a stable short slug for J.LEAGUE English name Reilac Shiga FC.
- `ザスパ群馬` keeps `thespa_gunma` for J.LEAGUE English name Thespa Gunma.
- `カターレ富山` keeps `kataller_toyama` for J.LEAGUE English name Kataller Toyama.
- `ヴァンラーレ八戸` keeps `vanraure_hachinohe` for J.LEAGUE English name Vanraure Hachinohe.
- `テゲバジャーロ宮崎` keeps `tegevajaro_miyazaki` for J.LEAGUE English name Tegevajaro Miyazaki.
- `北海道コンサドーレ札幌` keeps `hokkaido_consadole_sapporo` for J.LEAGUE English name Hokkaido Consadole Sapporo.
- `松本山雅ＦＣ` keeps `matsumoto_yamaga` as a stable short slug for J.LEAGUE English name Matsumoto Yamaga F.C.
- `ＡＣ長野パルセイロ` keeps `ac_nagano_parceiro` for J.LEAGUE English name AC Nagano Parceiro.
- `ツエーゲン金沢` keeps `zweigen_kanazawa` for J.LEAGUE English name Zweigen Kanazawa.
- `ギラヴァンツ北九州` keeps `giravanz_kitakyushu` for J.LEAGUE English name Giravanz Kitakyushu.

These candidate IDs are not confirmed `/teams/{id}` documents and are not seed data.

## API-SPORTS Team ID / Logo URL Verification Plan

This section is documentation-only planning and evidence tracking for API-SPORTS team ID / logo URL verification.

The rows below reflect approved read-only API-SPORTS lookup evidence. No Firestore read/write, seed, deploy, source code change, or team module update was performed for this review update.

Current status:

- API-SPORTS league discovery succeeded for Japan / 2024
- J1 League externalLeagueId: 98
- J2 League externalLeagueId: 99
- J3 League externalLeagueId: 100
- Japan Football League externalLeagueId: 497
- Candidate rows with API evidence found: 40
- Direct / near-direct evidence rows: 29
- Name variance review rows: 11
- API-SPORTS IDs verified enough for documentation evidence: 40
- Logo URLs found: 40
- Rows ready for seed data: 0
- `seedable`: remains `no` for every row
- `j2Teams.js` / `j3Teams.js`: remain empty until stable identity + API / logo verification is complete and approved

Verification rules:

- Match API-SPORTS teams against the stable club identity, not against temporary 2026 group membership.
- Do not encode J2 / J3 division or 2026 group names in stable team IDs.
- Do not infer API-SPORTS team IDs or logo URLs from J.LEAGUE pages.
- Record API-SPORTS evidence separately before moving any row into seedable data.
- Treat name variance rows as unresolved for seed data until reviewed.
- Keep `seedable` as `no` until stable identity, API team ID, and logo URL are all verified.

Evidence required before a row can become seedable:

- candidate internal team ID
- API-SPORTS team ID
- API-SPORTS raw team name
- API-SPORTS logo URL
- lookup method and parameters
- evidence date
- match confidence / review note

Existing local reference:

- `functions/scripts/fetchJ1TeamsFromApiSports.js` is a read-only J1 inspection script pattern.
- A J2 / J3 lookup should follow the same read-only principle if implemented later.
- Do not run a lookup script or API request without approval.
- Approved read-only lookup commands used for this evidence:
  - `--leagues --season 2024 --json`
  - `--league 99 --season 2024 --json`
  - `--league 100 --season 2024 --json`
  - `--league 98 --season 2024 --json`
  - `--league 497 --season 2024 --json`

## API-SPORTS Verification Tracker

This table is API lookup evidence only. It is not seed data, and these rows are not confirmed `/teams/{id}` documents.

| group | club nameJa | candidate internal team id | API-SPORTS verification status | externalTeamId | logoUrl | API raw team name | lookup source league | evidence | seedable |
|---|---|---|---|---:|---|---|---|---|---|
| EAST-A | ベガルタ仙台 | `vegalta_sendai` | api-lookup-evidence-found | 286 | `https://media.api-sports.io/football/teams/286.png` | Vegalta Sendai | J2 2024 / 99 | API-SPORTS teams?league=99&season=2024 | no |
| EAST-A | 湘南ベルマーレ | `shonan_bellmare` | api-lookup-evidence-found | 284 | `https://media.api-sports.io/football/teams/284.png` | Shonan Bellmare | J1 2024 / 98 | API-SPORTS teams?league=98&season=2024 | no |
| EAST-A | ブラウブリッツ秋田 | `blaublitz_akita` | api-lookup-evidence-found | 4315 | `https://media.api-sports.io/football/teams/4315.png` | Blaublitz Akita | J2 2024 / 99 | API-SPORTS teams?league=99&season=2024 | no |
| EAST-A | ＳＣ相模原 | `sc_sagamihara` | api-lookup-name-variance-review | 4324 | `https://media.api-sports.io/football/teams/4324.png` | Sagamihara | J3 2024 / 100 | API raw name omits SC | no |
| EAST-A | 横浜ＦＣ | `yokohama_fc` | api-lookup-evidence-found | 307 | `https://media.api-sports.io/football/teams/307.png` | Yokohama FC | J2 2024 / 99 | API-SPORTS teams?league=99&season=2024 | no |
| EAST-A | モンテディオ山形 | `montedio_yamagata` | api-lookup-evidence-found | 312 | `https://media.api-sports.io/football/teams/312.png` | Montedio Yamagata | J2 2024 / 99 | API-SPORTS teams?league=99&season=2024 | no |
| EAST-A | ザスパ群馬 | `thespa_gunma` | api-lookup-name-variance-review | 756 | `https://media.api-sports.io/football/teams/756.png` | Thespakusatsu Gunma | J2 2024 / 99 | API raw name uses older/longer form | no |
| EAST-A | 栃木シティ | `tochigi_city` | api-lookup-evidence-found | 7145 | `https://media.api-sports.io/football/teams/7145.png` | Tochigi City | JFL 2024 / 497 | API-SPORTS teams?league=497&season=2024 | no |
| EAST-A | 栃木ＳＣ | `tochigi_sc` | api-lookup-evidence-found | 315 | `https://media.api-sports.io/football/teams/315.png` | Tochigi SC | J2 2024 / 99 | API-SPORTS teams?league=99&season=2024 | no |
| EAST-A | ヴァンラーレ八戸 | `vanraure_hachinohe` | api-lookup-evidence-found | 4326 | `https://media.api-sports.io/football/teams/4326.png` | Vanraure Hachinohe | J3 2024 / 100 | API-SPORTS teams?league=100&season=2024 | no |
| EAST-B | ヴァンフォーレ甲府 | `ventforet_kofu` | api-lookup-evidence-found | 308 | `https://media.api-sports.io/football/teams/308.png` | Ventforet Kofu | J2 2024 / 99 | API-SPORTS teams?league=99&season=2024 | no |
| EAST-B | いわきＦＣ | `iwaki_fc` | api-lookup-name-variance-review | 7127 | `https://media.api-sports.io/football/teams/7127.png` | Iwaki | J2 2024 / 99 | API raw name omits FC | no |
| EAST-B | ＲＢ大宮アルディージャ | `rb_omiya_ardija` | api-lookup-name-variance-review | 313 | `https://media.api-sports.io/football/teams/313.png` | Omiya Ardija | J3 2024 / 100 | API raw name omits RB branding | no |
| EAST-B | 北海道コンサドーレ札幌 | `hokkaido_consadole_sapporo` | api-lookup-name-variance-review | 279 | `https://media.api-sports.io/football/teams/279.png` | Consadole Sapporo | J1 2024 / 98 | API raw name omits Hokkaido | no |
| EAST-B | 藤枝ＭＹＦＣ | `fujieda_myfc` | api-lookup-evidence-found | 4317 | `https://media.api-sports.io/football/teams/4317.png` | Fujieda MYFC | J2 2024 / 99 | API-SPORTS teams?league=99&season=2024 | no |
| EAST-B | ＦＣ岐阜 | `fc_gifu` | api-lookup-evidence-found | 297 | `https://media.api-sports.io/football/teams/297.png` | FC Gifu | J3 2024 / 100 | API-SPORTS teams?league=100&season=2024 | no |
| EAST-B | 松本山雅ＦＣ | `matsumoto_yamaga` | api-lookup-evidence-found | 304 | `https://media.api-sports.io/football/teams/304.png` | Matsumoto Yamaga | J3 2024 / 100 | API raw name omits FC but stable name is clear | no |
| EAST-B | ジュビロ磐田 | `jubilo_iwata` | api-lookup-evidence-found | 280 | `https://media.api-sports.io/football/teams/280.png` | Jubilo Iwata | J1 2024 / 98 | API-SPORTS teams?league=98&season=2024 | no |
| EAST-B | 福島ユナイテッドＦＣ | `fukushima_united` | api-lookup-evidence-found | 4318 | `https://media.api-sports.io/football/teams/4318.png` | Fukushima United | J3 2024 / 100 | API raw name omits FC but stable name is clear | no |
| EAST-B | ＡＣ長野パルセイロ | `ac_nagano_parceiro` | api-lookup-name-variance-review | 4323 | `https://media.api-sports.io/football/teams/4323.png` | Parceiro Nagano | J3 2024 / 100 | API raw name differs in order and omits AC | no |
| WEST-A | カターレ富山 | `kataller_toyama` | api-lookup-evidence-found | 4322 | `https://media.api-sports.io/football/teams/4322.png` | Kataller Toyama | J3 2024 / 100 | API-SPORTS teams?league=100&season=2024 | no |
| WEST-A | 徳島ヴォルティス | `tokushima_vortis` | api-lookup-evidence-found | 299 | `https://media.api-sports.io/football/teams/299.png` | Tokushima Vortis | J2 2024 / 99 | API-SPORTS teams?league=99&season=2024 | no |
| WEST-A | アルビレックス新潟 | `albirex_niigata` | api-lookup-evidence-found | 311 | `https://media.api-sports.io/football/teams/311.png` | Albirex Niigata | J1 2024 / 98 | API-SPORTS teams?league=98&season=2024 | no |
| WEST-A | 高知ユナイテッドＳＣ | `kochi_united` | api-lookup-evidence-found | 7129 | `https://media.api-sports.io/football/teams/7129.png` | Kochi United | JFL 2024 / 497 | API raw name omits SC but stable name is clear | no |
| WEST-A | 愛媛ＦＣ | `ehime_fc` | api-lookup-evidence-found | 318 | `https://media.api-sports.io/football/teams/318.png` | Ehime FC | J2 2024 / 99 | API-SPORTS teams?league=99&season=2024 | no |
| WEST-A | ツエーゲン金沢 | `zweigen_kanazawa` | api-lookup-name-variance-review | 300 | `https://media.api-sports.io/football/teams/300.png` | Kanazawa | J3 2024 / 100 | API raw name is shortened | no |
| WEST-A | ＦＣ大阪 | `fc_osaka` | api-lookup-name-variance-review | 7138 | `https://media.api-sports.io/football/teams/7138.png` | Osaka | J3 2024 / 100 | API raw name omits FC | no |
| WEST-A | ＦＣ今治 | `fc_imabari` | api-lookup-name-variance-review | 10075 | `https://media.api-sports.io/football/teams/10075.png` | Imabari | J3 2024 / 100 | API raw name omits FC | no |
| WEST-A | 奈良クラブ | `nara_club` | api-lookup-evidence-found | 7135 | `https://media.api-sports.io/football/teams/7135.png` | Nara Club | J3 2024 / 100 | API-SPORTS teams?league=100&season=2024 | no |
| WEST-A | カマタマーレ讃岐 | `kamatamare_sanuki` | api-lookup-evidence-found | 317 | `https://media.api-sports.io/football/teams/317.png` | Kamatamare Sanuki | J3 2024 / 100 | API-SPORTS teams?league=100&season=2024 | no |
| WEST-B | テゲバジャーロ宮崎 | `tegevajaro_miyazaki` | api-lookup-evidence-found | 10409 | `https://media.api-sports.io/football/teams/10409.png` | Tegevajaro Miyazaki | J3 2024 / 100 | API-SPORTS teams?league=100&season=2024 | no |
| WEST-B | サガン鳥栖 | `sagan_tosu` | api-lookup-evidence-found | 295 | `https://media.api-sports.io/football/teams/295.png` | Sagan Tosu | J1 2024 / 98 | API-SPORTS teams?league=98&season=2024 | no |
| WEST-B | 鹿児島ユナイテッドＦＣ | `kagoshima_united` | api-lookup-evidence-found | 2236 | `https://media.api-sports.io/football/teams/2236.png` | Kagoshima United | J2 2024 / 99 | API raw name omits FC but stable name is clear | no |
| WEST-B | レノファ山口ＦＣ | `renofa_yamaguchi` | api-lookup-evidence-found | 309 | `https://media.api-sports.io/football/teams/309.png` | Renofa Yamaguchi | J2 2024 / 99 | API raw name omits FC but stable name is clear | no |
| WEST-B | ロアッソ熊本 | `roasso_kumamoto` | api-lookup-evidence-found | 314 | `https://media.api-sports.io/football/teams/314.png` | Roasso Kumamoto | J2 2024 / 99 | API-SPORTS teams?league=99&season=2024 | no |
| WEST-B | 大分トリニータ | `oita_trinita` | api-lookup-evidence-found | 298 | `https://media.api-sports.io/football/teams/298.png` | Oita Trinita | J2 2024 / 99 | API-SPORTS teams?league=99&season=2024 | no |
| WEST-B | ガイナーレ鳥取 | `gainare_tottori` | api-lookup-evidence-found | 4319 | `https://media.api-sports.io/football/teams/4319.png` | Gainare Tottori | J3 2024 / 100 | API-SPORTS teams?league=100&season=2024 | no |
| WEST-B | ギラヴァンツ北九州 | `giravanz_kitakyushu` | api-lookup-name-variance-review | 805 | `https://media.api-sports.io/football/teams/805.png` | Kitakyushu | J3 2024 / 100 | API raw name is shortened | no |
| WEST-B | レイラック滋賀ＦＣ | `reilac_shiga` | api-lookup-name-variance-review | 7117 | `https://media.api-sports.io/football/teams/7117.png` | Biwako Shiga | JFL 2024 / 497 | API raw name differs from current J.LEAGUE name | no |
| WEST-B | ＦＣ琉球 | `fc_ryukyu` | api-lookup-evidence-found | 2235 | `https://media.api-sports.io/football/teams/2235.png` | FC Ryukyu | J3 2024 / 100 | API-SPORTS teams?league=100&season=2024 | no |

## Name Variance Review

This section records documentation-only interpretation for the 11 `api-lookup-name-variance-review` rows in the API-SPORTS tracker.

These rows are not seedable approvals. They remain review evidence only and are not confirmed `/teams/{id}` documents.

Summary:

- Name variance rows reviewed: 11
- Rows acceptable as API evidence candidates: 10
- Rows requiring stronger rebrand / continuity review before seedable: 1
- Rows moved to seedable: 0
- Confirmed `/teams/{id}` documents created: 0
- `j2Teams.js` / `j3Teams.js` entries added: 0

| candidate internal team id | current club nameJa | API raw team name | variance type | review interpretation | seedable decision |
|---|---|---|---|---|---|
| `sc_sagamihara` | ＳＣ相模原 | Sagamihara | prefix omitted | API raw name omits `SC`; likely same club candidate, but keep as approval target before seedable data | no |
| `thespa_gunma` | ザスパ群馬 | Thespakusatsu Gunma | older / longer form | API raw name uses older / longer form; likely same club candidate, but keep as approval target before seedable data | no |
| `iwaki_fc` | いわきＦＣ | Iwaki | suffix omitted | API raw name omits `FC`; likely same club candidate, but keep as approval target before seedable data | no |
| `rb_omiya_ardija` | ＲＢ大宮アルディージャ | Omiya Ardija | current branding omitted | API raw name omits current `RB` branding; likely same club identity, but branding variance remains an approval target before seedable data | no |
| `hokkaido_consadole_sapporo` | 北海道コンサドーレ札幌 | Consadole Sapporo | regional prefix omitted | API raw name omits `Hokkaido`; likely same club candidate, but keep as approval target before seedable data | no |
| `ac_nagano_parceiro` | ＡＣ長野パルセイロ | Parceiro Nagano | order difference and prefix omitted | API raw name differs in order and omits `AC`; likely same club candidate, but keep as approval target before seedable data | no |
| `zweigen_kanazawa` | ツエーゲン金沢 | Kanazawa | shortened name | API raw name is shortened to `Kanazawa`; likely same club candidate, but keep as approval target before seedable data | no |
| `fc_osaka` | ＦＣ大阪 | Osaka | prefix omitted | API raw name omits `FC`; likely same club candidate, but keep as approval target before seedable data | no |
| `fc_imabari` | ＦＣ今治 | Imabari | prefix omitted | API raw name omits `FC`; likely same club candidate, but keep as approval target before seedable data | no |
| `giravanz_kitakyushu` | ギラヴァンツ北九州 | Kitakyushu | shortened name | API raw name is shortened to `Kitakyushu`; likely same club candidate, but keep as approval target before seedable data | no |
| `reilac_shiga` | レイラック滋賀ＦＣ | Biwako Shiga | rebrand / continuity variance | API raw name differs from current J.LEAGUE name; requires stronger rebrand / continuity review before seedable data | no |

## Reilac Shiga Continuity Review

This section records documentation-only continuity review for the high-attention `reilac_shiga` / `Biwako Shiga` API name variance row.

Summary:

- Reilac / Biwako continuity review documented: yes
- Continuity approval completed: no
- Confirmed entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0

| field | value |
|---|---|
| current candidate internal team id | `reilac_shiga` |
| current J.LEAGUE / club name | Reilac Shiga FC / レイラック滋賀FC |
| API-SPORTS raw team name | Biwako Shiga |
| API-SPORTS externalTeamId | 7117 |
| logoUrl | `https://media.api-sports.io/football/teams/7117.png` |
| lookup source | JFL 2024 / 497 |
| variance reason | API-SPORTS raw name differs from the current official-facing club name |
| continuity interpretation | Treat `Biwako Shiga` as API raw / older-name evidence for the `reilac_shiga` candidate only after explicit continuity approval |
| seedable decision | no |

Review policy:

- `Reilac Shiga FC` / `レイラック滋賀FC` is treated as the current official-facing name.
- `Biwako Shiga` is treated as API-SPORTS raw / older-name evidence.
- API-SPORTS externalTeamId `7117` and logoUrl remain documentation evidence.
- The raw name difference is large enough that continuity approval is required before this row can become seedable.
- Do not create a confirmed `/teams/{id}` document for this row yet.
- Keep season membership separate from stable team master data.

## Confirmed Team Module Criteria

This section defines the documentation-only criteria for later adding confirmed entries to `functions/scripts/data/j2Teams.js` or `functions/scripts/data/j3Teams.js`.

It does not create confirmed entries, seed data, Firestore documents, or competition season membership rows.

Summary:

- Confirmed team module criteria documented: yes
- Confirmed entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0

A club row can be considered for a confirmed team module entry only after all of the following are true:

- The candidate internal team ID is approved as the stable club identity.
- The API-SPORTS `externalTeamId` is confirmed from API lookup evidence.
- The `logoUrl` is confirmed from API lookup evidence.
- Any name variance row has passed additional review / approval.
- `reilac_shiga` / `Biwako Shiga` has completed stronger rebrand / continuity review before being considered as a confirmed entry.
- Stable team master data remains separate from season / tournament membership data.
- A confirmed `/teams/{id}` document is not treated as the same thing as competition membership.
- Firestore write and non-dry seed execution wait for separate approval.

Do not add rows to `j2Teams.js` or `j3Teams.js` from this review document alone. The tracker and name variance review are evidence, not seedable master data.

## Per-Club Confirmed Entry Approval Flow

This section defines the documentation-only approval flow for turning a reviewed club row into a later confirmed team module entry candidate.

It does not approve any club, edit `j2Teams.js` or `j3Teams.js`, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Per-club approval flow documented: yes
- Clubs approved for module entry: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- `reilac_shiga` approval status: blocked until continuity approval

Approval unit:

- Approve one club row at a time.
- Do not use bulk approval for all J2 / J3 candidates.
- Review candidate internal team ID, API-SPORTS `externalTeamId`, `logoUrl`, API raw team name, current club name, and name variance evidence for each club independently.

Required checks per club:

- Candidate internal team ID is acceptable as the stable club identity.
- API-SPORTS `externalTeamId` matches the tracker evidence.
- `logoUrl` matches the tracker evidence.
- API raw team name and current club name variance is acceptable for the intended stable club identity.
- Name variance rows have their variance review checked before approval.
- Season membership and stable team master data are not confused.
- Approval does not create a duplicate `/teams/{id}` document.
- Approval does not collide with an existing confirmed J1 team ID.

Approval states:

- `approval-not-started`: no per-club approval review has started.
- `approval-ready`: direct / near-direct evidence appears ready for per-club approval.
- `approval-blocked-name-variance`: name variance must be reviewed before approval.
- `approval-blocked-continuity`: rebrand / continuity review must be completed before approval.
- `approved-for-module-entry`: club may be proposed for a later confirmed module entry file change.
- `rejected`: club should not be added from the current evidence.

Current recommended state:

- Direct / near-direct rows: 29 `approval-ready` candidates.
- Name variance rows excluding `reilac_shiga`: 10 `approval-ready-after-variance-review` candidates.
- `reilac_shiga`: `approval-blocked-continuity`.
- `approved-for-module-entry`: 0.
- `rejected`: 0.
- Seedable rows changed: 0.

What approval enables:

- Approved clubs can become candidates for later `j2Teams.js` / `j3Teams.js` confirmed entries.
- Actual file changes to `j2Teams.js` / `j3Teams.js` still require separate approval.
- Firestore write and non-dry seed execution require further separate approval.

What approval does not enable:

- Firestore write.
- Non-dry seed.
- API sync.
- Deploy.
- Season membership write.
- Automatic confirmed `/teams/{id}` creation.

## Per-Club Approval Batch 1

This section records the first documentation-only per-club approval candidate list.

It is not final approval. No club in this batch is approved for module entry yet, and this section does not create seed data, confirmed `/teams/{id}` documents, `j2Teams.js` entries, `j3Teams.js` entries, Firestore writes, API sync, or deploy changes.

Summary:

- Per-club approval batch 1 documented: yes
- Batch 1 candidates listed: 5
- Batch 1 candidates approved for module entry: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- `reilac_shiga` included: no

Batch 1 intentionally contains only direct / near-direct rows whose API raw team name and current club identity are straightforward matches. `reilac_shiga` remains excluded until continuity approval is completed.

| candidate internal team id | club nameJa | API raw team name | externalTeamId | logoUrl | lookup source | variance status | recommended approval state | approval decision | notes |
|---|---|---|---:|---|---|---|---|---|---|
| `vegalta_sendai` | ベガルタ仙台 | Vegalta Sendai | 286 | `https://media.api-sports.io/football/teams/286.png` | J2 2024 / 99 | direct-or-near-direct | approval-ready | not-approved-yet | First-batch candidate only; seedable remains no |
| `shonan_bellmare` | 湘南ベルマーレ | Shonan Bellmare | 284 | `https://media.api-sports.io/football/teams/284.png` | J1 2024 / 98 | direct-or-near-direct | approval-ready | not-approved-yet | First-batch candidate only; seedable remains no |
| `blaublitz_akita` | ブラウブリッツ秋田 | Blaublitz Akita | 4315 | `https://media.api-sports.io/football/teams/4315.png` | J2 2024 / 99 | direct-or-near-direct | approval-ready | not-approved-yet | First-batch candidate only; seedable remains no |
| `yokohama_fc` | 横浜ＦＣ | Yokohama FC | 307 | `https://media.api-sports.io/football/teams/307.png` | J2 2024 / 99 | direct-or-near-direct | approval-ready | not-approved-yet | First-batch candidate only; seedable remains no |
| `montedio_yamagata` | モンテディオ山形 | Montedio Yamagata | 312 | `https://media.api-sports.io/football/teams/312.png` | J2 2024 / 99 | direct-or-near-direct | approval-ready | not-approved-yet | First-batch candidate only; seedable remains no |

## Per-Club Approval Batch 2

This section records the second documentation-only per-club approval candidate list.

It is not final approval. No club in this batch is approved for module entry yet, and this section does not create seed data, confirmed `/teams/{id}` documents, `j2Teams.js` entries, `j3Teams.js` entries, Firestore writes, API sync, or deploy changes.

Summary:

- Per-club approval batch 2 documented: yes
- Batch 2 candidates listed: 5
- Batch 2 candidates approved for module entry: 0
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- `reilac_shiga` included: no
- Batch 1 entries changed: no

Batch 2 intentionally contains only direct / near-direct rows. Name variance rows are not included. `reilac_shiga` remains excluded until continuity approval is completed.

Season membership remains separate from stable team master data. Lookup source league names below are API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership.

| candidate internal team id | club nameJa | API raw team name | externalTeamId | logoUrl | lookup source | variance status | recommended approval state | approval decision | target module candidate | notes |
|---|---|---|---:|---|---|---|---|---|---|---|
| `tochigi_city` | 栃木シティ | Tochigi City | 7145 | `https://media.api-sports.io/football/teams/7145.png` | JFL 2024 / 497 | direct-or-near-direct | approval-ready | not-approved-yet | `j2Teams.js` candidate | JFL lookup is stable identity API evidence only; seedable remains no |
| `tochigi_sc` | 栃木ＳＣ | Tochigi SC | 315 | `https://media.api-sports.io/football/teams/315.png` | J2 2024 / 99 | direct-or-near-direct | approval-ready | not-approved-yet | `j2Teams.js` candidate | Batch 2 candidate only; seedable remains no |
| `vanraure_hachinohe` | ヴァンラーレ八戸 | Vanraure Hachinohe | 4326 | `https://media.api-sports.io/football/teams/4326.png` | J3 2024 / 100 | direct-or-near-direct | approval-ready | not-approved-yet | `j3Teams.js` candidate | J3 lookup is stable identity API evidence only; docs-only candidate for now |
| `ventforet_kofu` | ヴァンフォーレ甲府 | Ventforet Kofu | 308 | `https://media.api-sports.io/football/teams/308.png` | J2 2024 / 99 | direct-or-near-direct | approval-ready | not-approved-yet | `j2Teams.js` candidate | Batch 2 candidate only; seedable remains no |
| `fujieda_myfc` | 藤枝ＭＹＦＣ | Fujieda MYFC | 4317 | `https://media.api-sports.io/football/teams/4317.png` | J2 2024 / 99 | direct-or-near-direct | approval-ready | not-approved-yet | `j2Teams.js` candidate | Batch 2 candidate only; seedable remains no |

## Per-Club Approval Batch 3

This section records the third documentation-only per-club approval candidate list.

It is not final approval. No club in this batch is approved for module entry yet, and this section does not create seed data, confirmed `/teams/{id}` documents, `j2Teams.js` entries, `j3Teams.js` entries, Firestore writes, API sync, or deploy changes.

Summary:

- Per-club approval batch 3 documented: yes
- Batch 3 candidates listed: 5
- Batch 3 candidates approved for module entry: 0
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- `reilac_shiga` included: no
- name variance rows included: no
- Batch 1 entries changed: no
- Batch 2 entries changed: no

Batch 3 intentionally contains only direct / near-direct / stable-clear API evidence rows. Name variance rows are not included. `reilac_shiga` remains excluded until continuity approval is completed.

Season membership remains separate from stable team master data. Lookup source league names below are API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership. The `J1 2024 / 98` lookup source for `jubilo_iwata` is stable club identity evidence only.

| candidate internal team id | club nameJa | API raw team name | externalTeamId | logoUrl | lookup source | variance status | recommended approval state | approval decision | target module candidate | notes |
|---|---|---|---:|---|---|---|---|---|---|---|
| `fc_gifu` | ＦＣ岐阜 | FC Gifu | 297 | `https://media.api-sports.io/football/teams/297.png` | J3 2024 / 100 | direct-or-near-direct | approval-ready | not-approved-yet | `j3Teams.js` candidate | Batch 3 candidate only; no file write yet |
| `matsumoto_yamaga` | 松本山雅ＦＣ | Matsumoto Yamaga | 304 | `https://media.api-sports.io/football/teams/304.png` | J3 2024 / 100 | direct-or-near-direct | approval-ready | not-approved-yet | `j3Teams.js` candidate | API raw name omits FC, but stable club identity is clear; no file write yet |
| `jubilo_iwata` | ジュビロ磐田 | Jubilo Iwata | 280 | `https://media.api-sports.io/football/teams/280.png` | J1 2024 / 98 | direct-or-near-direct | approval-ready | not-approved-yet | `j2Teams.js` candidate | J1 lookup is stable identity API evidence only; not permanent division membership; no file write yet |
| `fukushima_united` | 福島ユナイテッドＦＣ | Fukushima United | 4318 | `https://media.api-sports.io/football/teams/4318.png` | J3 2024 / 100 | direct-or-near-direct | approval-ready | not-approved-yet | `j3Teams.js` candidate | API raw name omits FC, but stable club identity is clear; no file write yet |
| `kataller_toyama` | カターレ富山 | Kataller Toyama | 4322 | `https://media.api-sports.io/football/teams/4322.png` | J3 2024 / 100 | direct-or-near-direct | approval-ready | not-approved-yet | `j3Teams.js` candidate | Batch 3 candidate only; no file write yet |

## Per-Club Approval Decision Review - fc_gifu

This section records a documentation-only approval decision review for one Batch 3 club row.

It does not change the Batch 3 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `fc_gifu`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 3 table changed: no
- Batch 3 individual reviews completed: 1 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `fc_gifu` is a stable club identity candidate for ＦＣ岐阜 and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `FC Gifu` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `297` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/297.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J3 2024 / 100` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `fc_gifu` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `fc_gifu` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - matsumoto_yamaga

This section records a documentation-only approval decision review for one Batch 3 club row.

It does not change the Batch 3 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `matsumoto_yamaga`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 3 table changed: no
- Batch 3 individual reviews completed: 2 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `matsumoto_yamaga` is a stable club identity candidate for 松本山雅ＦＣ and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Matsumoto Yamaga` is an acceptable direct / near-direct match for the current club identity; the API raw name omits `FC`, but stable club identity is clear | pass |
| externalTeamId | `304` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/304.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row; note the omitted `FC` is already documented as stable-clear evidence | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J3 2024 / 100` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `matsumoto_yamaga` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `matsumoto_yamaga` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - jubilo_iwata

This section records a documentation-only approval decision review for one Batch 3 club row.

It does not change the Batch 3 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `jubilo_iwata`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 3 table changed: no
- Batch 3 individual reviews completed: 3 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `jubilo_iwata` is a stable club identity candidate for ジュビロ磐田 and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Jubilo Iwata` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `280` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/280.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J1 2024 / 98` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `jubilo_iwata` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `jubilo_iwata` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - fukushima_united

This section records a documentation-only approval decision review for one Batch 3 club row.

It does not change the Batch 3 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `fukushima_united`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 3 table changed: no
- Batch 3 individual reviews completed: 4 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `fukushima_united` is a stable club identity candidate for 福島ユナイテッドＦＣ and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Fukushima United` is an acceptable direct / near-direct match for the current club identity; the API raw name omits `FC`, but stable club identity is clear | pass |
| externalTeamId | `4318` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/4318.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row; note the omitted `FC` is already documented as stable-clear evidence | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J3 2024 / 100` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `fukushima_united` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `fukushima_united` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - kataller_toyama

This section records a documentation-only approval decision review for one Batch 3 club row.

It does not change the Batch 3 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `kataller_toyama`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 3 table changed: no
- Batch 3 individual reviews completed: 5 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `kataller_toyama` is a stable club identity candidate for カターレ富山 and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Kataller Toyama` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `4322` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/4322.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J3 2024 / 100` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `kataller_toyama` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `kataller_toyama` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Batch 3 Actual Module Entry Preparation Review

This section records a documentation-only final preparation review before any Batch 3 club is moved into an actual team module entry.

It does not create `approved-for-module-entry` file entries, edit `j2Teams.js` or `j3Teams.js`, create seed data, write Firestore documents, run API sync, deploy, or change any seedable status.

Summary:

- Batch 3 actual module entry preparation review documented: yes
- Batch 3 reviewed candidates: 5
- Batch 3 ready for separate module entry approval: 5
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- `reilac_shiga` included: no
- Batch 4 created: no
- `jubilo_iwata` target module candidate: `j2Teams.js`
- Batch 3 `j3Teams.js` target module candidates: 4

Preparation policy:

- Target module candidates below are documentation-only candidates and are not actual file writes.
- All five Batch 3 rows still require a separate exact diff plan and separate module entry approval before any `j2Teams.js` or `j3Teams.js` module entry is created.
- `jubilo_iwata` is the only Batch 3 `j2Teams.js` candidate.
- `fc_gifu`, `matsumoto_yamaga`, `fukushima_united`, and `kataller_toyama` are the Batch 3 `j3Teams.js` candidates.
- Keep `seedable` as `no` until separate confirmed module entry approval and later seed approval are completed.
- Keep season membership separate from stable team master data.
- Lookup source league names are API evidence for stable club identity only. They do not imply 2026 J2 / J3 special competition membership or permanent division membership.
- `reilac_shiga` remains excluded until continuity approval is completed.

| candidate internal team id | club nameJa | API raw team name | externalTeamId | logoUrl | lookup source | per-club review status | module entry preparation status | target module candidate | notes |
|---|---|---|---:|---|---|---|---|---|---|
| `fc_gifu` | ＦＣ岐阜 | FC Gifu | 297 | `https://media.api-sports.io/football/teams/297.png` | J3 2024 / 100 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j3Teams.js` candidate | Documentation-only target; no file write yet |
| `matsumoto_yamaga` | 松本山雅ＦＣ | Matsumoto Yamaga | 304 | `https://media.api-sports.io/football/teams/304.png` | J3 2024 / 100 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j3Teams.js` candidate | API raw name omits FC, but stable club identity is clear; no file write yet |
| `jubilo_iwata` | ジュビロ磐田 | Jubilo Iwata | 280 | `https://media.api-sports.io/football/teams/280.png` | J1 2024 / 98 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | The only Batch 3 `j2Teams.js` candidate; J1 lookup is stable identity API evidence only and no file write yet |
| `fukushima_united` | 福島ユナイテッドＦＣ | Fukushima United | 4318 | `https://media.api-sports.io/football/teams/4318.png` | J3 2024 / 100 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j3Teams.js` candidate | API raw name omits FC, but stable club identity is clear; no file write yet |
| `kataller_toyama` | カターレ富山 | Kataller Toyama | 4322 | `https://media.api-sports.io/football/teams/4322.png` | J3 2024 / 100 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j3Teams.js` candidate | Documentation-only target; no file write yet |

## Batch 3 j2Teams.js / j3Teams.js Exact Diff Plan

This section records a documentation-only exact diff plan for the five Batch 3 entries that may later be added to `functions/scripts/data/j2Teams.js` or `functions/scripts/data/j3Teams.js`.

It does not edit `j2Teams.js` or `j3Teams.js`, create actual module entries, create seed data, write Firestore documents, run API sync, deploy, or change any seedable status.

Summary:

- Batch 3 exact diff plan documented: yes
- Planned target files:
  - `functions/scripts/data/j2Teams.js`
  - `functions/scripts/data/j3Teams.js`
- Planned `j2Teams.js` entries: 1
- Planned `j3Teams.js` entries: 4
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- `reilac_shiga` included: no
- implementation status: all rows `planned-not-written`

Implementation policy:

- `j2Teams.js` and `j3Teams.js` are treated as stable team master data candidate storage, not direct 2026 J2 / J3 special competition membership data.
- Season membership remains separate from stable team master data.
- Do not represent 2026 J2 / J3 special competition membership directly in `j2Teams.js` or `j3Teams.js`.
- Lookup source league names are API evidence for stable club identity only. They do not imply 2026 J2 / J3 special competition membership or permanent division membership.
- `jubilo_iwata` is the only Batch 3 `j2Teams.js` planned entry.
- The other four Batch 3 planned entries go to `j3Teams.js`.
- `reilac_shiga` remains excluded until continuity approval is completed.
- Keep `seedable` as `no` until separate module entry approval and later seed approval are completed.
- Do not run Firestore write or non-dry seed from this plan.

Planned `j2Teams.js` entries:

| target file | candidate internal team id | nameJa | nameEn | externalTeamId | logoUrl | competitionKey candidate | source evidence | implementation status | notes |
|---|---|---|---|---:|---|---|---|---|---|
| `functions/scripts/data/j2Teams.js` | `jubilo_iwata` | ジュビロ磐田 | Jubilo Iwata | 280 | `https://media.api-sports.io/football/teams/280.png` | `football_j2` | API-SPORTS teams?league=98&season=2024 + Batch 3 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | J1 2024 lookup is stable identity evidence only, not permanent division membership |

Planned `j3Teams.js` entries:

| target file | candidate internal team id | nameJa | nameEn | externalTeamId | logoUrl | competitionKey candidate | source evidence | implementation status | notes |
|---|---|---|---|---:|---|---|---|---|---|
| `functions/scripts/data/j3Teams.js` | `fc_gifu` | ＦＣ岐阜 | FC Gifu | 297 | `https://media.api-sports.io/football/teams/297.png` | `football_j3` | API-SPORTS teams?league=100&season=2024 + Batch 3 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | Stable team master candidate only; no file write yet |
| `functions/scripts/data/j3Teams.js` | `matsumoto_yamaga` | 松本山雅ＦＣ | Matsumoto Yamaga | 304 | `https://media.api-sports.io/football/teams/304.png` | `football_j3` | API-SPORTS teams?league=100&season=2024 + Batch 3 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | API raw name omits FC, but stable club identity is clear; no file write yet |
| `functions/scripts/data/j3Teams.js` | `fukushima_united` | 福島ユナイテッドＦＣ | Fukushima United | 4318 | `https://media.api-sports.io/football/teams/4318.png` | `football_j3` | API-SPORTS teams?league=100&season=2024 + Batch 3 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | API raw name omits FC, but stable club identity is clear; no file write yet |
| `functions/scripts/data/j3Teams.js` | `kataller_toyama` | カターレ富山 | Kataller Toyama | 4322 | `https://media.api-sports.io/football/teams/4322.png` | `football_j3` | API-SPORTS teams?league=100&season=2024 + Batch 3 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | Stable team master candidate only; no file write yet |

## Per-Club Approval Batch 4

This section records the fourth documentation-only per-club approval candidate list.

Batch 4 selects five remaining `candidate_not_confirmed` rows that are relatively easy to handle as direct / near-direct / stable-clear API evidence candidates. It is not final approval, and it does not create seed data, confirmed `/teams/{id}` documents, `j2Teams.js` entries, `j3Teams.js` entries, `teamIdStatuses` changes, Firestore writes, API sync, or deploy changes.

Summary:

- Per-club approval batch 4 documented: yes
- Batch 4 candidates listed: 5
- Batch 4 candidates approved for module entry: 0
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- `teamIdStatuses` changed: 0
- Firestore writes: 0
- non-dry seed: 0
- `--write`: 0
- API calls: 0
- deploy: 0
- `seedable: true` changes: 0
- `reilac_shiga` included: no
- bulk approval: no

Batch 4 policy:

- Batch 4 is a docs-only candidate list.
- This is not final approval.
- No club in Batch 4 is approved for actual module entry yet.
- Actual per-club approval decision review must be done one club at a time in later steps.
- Actual `j2Teams.js` / `j3Teams.js` entries require separate exact diff plan and separate approval.
- Season membership remains separate from stable team master data.
- Lookup source league names are API evidence for stable club identity only.
- Lookup source league names do not imply 2026 J2 / J3 special competition membership or permanent division membership.
- `reilac_shiga` remains excluded until continuity approval is completed.
- `football_j2_j3_2026_hyakunen` remains `status: review` / `seedable: false`.
- All-Sports Season Rollover Policy remains unchanged.
- New season candidates must start as `review` / `seedable: false`.
- Human approval is required before `seedable: true` or Firestore write.

| candidate internal team id | club nameJa | API raw team name | externalTeamId | logoUrl | lookup source | variance status | recommended approval state | approval decision | target module candidate | notes |
|---|---|---|---:|---|---|---|---|---|---|---|
| `tokushima_vortis` | 徳島ヴォルティス | Tokushima Vortis | 299 | `https://media.api-sports.io/football/teams/299.png` | J2 2024 / 99 | direct-or-near-direct | approval-ready | not-approved-yet | `j2Teams.js` candidate | API evidence is stable club identity evidence only; seedable remains no |
| `albirex_niigata` | アルビレックス新潟 | Albirex Niigata | 311 | `https://media.api-sports.io/football/teams/311.png` | J1 2024 / 98 | direct-or-near-direct | approval-ready | not-approved-yet | `j2Teams.js` candidate | J1 lookup is stable identity evidence only, not permanent division membership; seedable remains no |
| `kochi_united` | 高知ユナイテッドＳＣ | Kochi United | 7129 | `https://media.api-sports.io/football/teams/7129.png` | JFL 2024 / 497 | stable-clear-api-name-omits-sc | approval-ready | not-approved-yet | `j3Teams.js` candidate | API raw name omits `SC`, but stable club identity appears clear; JFL lookup is stable identity evidence only; seedable remains no |
| `ehime_fc` | 愛媛ＦＣ | Ehime FC | 318 | `https://media.api-sports.io/football/teams/318.png` | J2 2024 / 99 | direct-or-near-direct | approval-ready | not-approved-yet | `j2Teams.js` candidate | API evidence is stable club identity evidence only; seedable remains no |
| `nara_club` | 奈良クラブ | Nara Club | 7135 | `https://media.api-sports.io/football/teams/7135.png` | J3 2024 / 100 | direct-or-near-direct | approval-ready | not-approved-yet | `j3Teams.js` candidate | API evidence is stable club identity evidence only; seedable remains no |

Batch 4 next-step note:

- Next step after this docs-only batch list is one-club-at-a-time approval decision review.
- Recommended order:
  1. `tokushima_vortis`
  2. `albirex_niigata`
  3. `kochi_united`
  4. `ehime_fc`
  5. `nara_club`
- Do not create actual module entries from this batch list alone.
- Do not update `teamIdStatuses` from this batch list alone.

## Per-Club Approval Decision Review - tokushima_vortis

This section records a documentation-only approval decision review for one Batch 4 club row.

It does not change the Batch 4 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `tokushima_vortis`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- `teamIdStatuses` changed: 0
- Firestore writes: 0
- non-dry seed: 0
- `--write`: 0
- API calls: 0
- deploy: 0
- Seedable rows changed: 0
- Batch 4 table changed: no
- Batch 4 individual reviews completed: 1 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `tokushima_vortis` is a stable club identity candidate for 徳島ヴォルティス and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Tokushima Vortis` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `299` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/299.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J2 2024 / 99` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |
| target module candidate | `tokushima_vortis` may later be proposed for `j2Teams.js` only after separate exact diff plan and approval | pass |

Decision:

- `tokushima_vortis` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `tokushima_vortis` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - albirex_niigata

This section records a documentation-only approval decision review for one Batch 4 club row.

It does not change the Batch 4 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `albirex_niigata`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- `teamIdStatuses` changed: 0
- Firestore writes: 0
- non-dry seed: 0
- `--write`: 0
- API calls: 0
- deploy: 0
- Seedable rows changed: 0
- Batch 4 table changed: no
- Batch 4 individual reviews completed: 2 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `albirex_niigata` is a stable club identity candidate for アルビレックス新潟 and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Albirex Niigata` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `311` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/311.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J1 2024 / 98` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |
| target module candidate | `albirex_niigata` may later be proposed for `j2Teams.js` only after separate exact diff plan and approval | pass |

Decision:

- `albirex_niigata` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `albirex_niigata` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - kochi_united

This section records a documentation-only approval decision review for one Batch 4 club row.

It does not change the Batch 4 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `kochi_united`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- `teamIdStatuses` changed: 0
- Firestore writes: 0
- non-dry seed: 0
- `--write`: 0
- API calls: 0
- deploy: 0
- Seedable rows changed: 0
- Batch 4 table changed: no
- Batch 4 individual reviews completed: 3 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `kochi_united` is a stable club identity candidate for 高知ユナイテッドＳＣ and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Kochi United` omits `SC`, but this is acceptable stable-clear API evidence for the current club identity | pass |
| externalTeamId | `7129` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/7129.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | The API raw name omits `SC`, but the stable club identity appears clear enough for docs-only module entry candidate approval | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `JFL 2024 / 497` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |
| target module candidate | `kochi_united` may later be proposed for `j3Teams.js` only after separate exact diff plan and approval | pass |

Decision:

- `kochi_united` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `kochi_united` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - ehime_fc

This section records a documentation-only approval decision review for one Batch 4 club row.

It does not change the Batch 4 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `ehime_fc`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- `teamIdStatuses` changed: 0
- Firestore writes: 0
- non-dry seed: 0
- `--write`: 0
- API calls: 0
- deploy: 0
- Seedable rows changed: 0
- Batch 4 table changed: no
- Batch 4 individual reviews completed: 4 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `ehime_fc` is a stable club identity candidate for 愛媛ＦＣ and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Ehime FC` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `318` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/318.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J2 2024 / 99` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |
| target module candidate | `ehime_fc` may later be proposed for `j2Teams.js` only after separate exact diff plan and approval | pass |

Decision:

- `ehime_fc` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `ehime_fc` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - nara_club

This section records a documentation-only approval decision review for one Batch 4 club row.

It does not change the Batch 4 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `nara_club`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- `teamIdStatuses` changed: 0
- Firestore writes: 0
- non-dry seed: 0
- `--write`: 0
- API calls: 0
- deploy: 0
- Seedable rows changed: 0
- Batch 4 table changed: no
- Batch 4 individual reviews completed: 5 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `nara_club` is a stable club identity candidate for 奈良クラブ and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Nara Club` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `7135` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/7135.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J3 2024 / 100` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |
| target module candidate | `nara_club` may later be proposed for `j3Teams.js` only after separate exact diff plan and approval | pass |

Decision:

- `nara_club` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `nara_club` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

Batch 4 completion note:

- Batch 4 individual approval decision reviews completed: 5 / 5
- Batch 4 docs-only approved-for-module-entry-candidate rows:
  - `tokushima_vortis`
  - `albirex_niigata`
  - `kochi_united`
  - `ehime_fc`
  - `nara_club`
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- `teamIdStatuses` changed: 0
- `seedable: true` changes: 0
- Firestore writes / non-dry seed / `--write` / API sync / deploy / additional API calls: 0
- Next step is Batch 4 actual module entry preparation review.
- Do not create actual module entries from these reviews alone.

## Batch 4 Actual Module Entry Preparation Review

This section records a documentation-only actual module entry preparation review for the five Batch 4 entries that may later be added to `functions/scripts/data/j2Teams.js` or `functions/scripts/data/j3Teams.js`.

It does not edit `j2Teams.js` or `j3Teams.js`, create actual module entries, create seed data, write Firestore documents, run API sync, deploy, or change any seedable status.

Summary:

- Batch 4 actual module entry preparation review documented: yes
- Batch 4 reviewed candidates: 5
- Batch 4 ready for separate module entry approval: 5
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- `teamIdStatuses` changed: 0
- Firestore writes: 0
- non-dry seed: 0
- `--write`: 0
- API calls: 0
- deploy: 0
- `seedable: true` changes: 0
- `reilac_shiga` included: no
- bulk approval: no
- docs-only preparation review: yes

Preparation policy:

- Target module candidates below are documentation-only candidates and are not actual file writes.
- All five Batch 4 rows still require separate module entry approval before any `j2Teams.js` or `j3Teams.js` module entry is created.
- Batch 4 has three `j2Teams.js` candidates:
  - `tokushima_vortis`
  - `albirex_niigata`
  - `ehime_fc`
- Batch 4 has two `j3Teams.js` candidates:
  - `kochi_united`
  - `nara_club`
- Keep `seedable` as `no` until separate confirmed module entry approval and later seed approval are completed.
- Keep season membership separate from stable team master data.
- Lookup source league names are API evidence for stable club identity only.
- Lookup source league names do not imply 2026 J2 / J3 special competition membership or permanent division membership.
- `reilac_shiga` remains excluded until continuity approval is completed.
- `football_j2_j3_2026_hyakunen` remains `status: review` / `seedable: false`.
- All-Sports Season Rollover Policy remains unchanged.

| candidate internal team id | club nameJa | API raw team name | externalTeamId | logoUrl | lookup source | per-club review status | module entry preparation status | target module candidate | notes |
|---|---|---|---:|---|---|---|---|---|---|
| `tokushima_vortis` | 徳島ヴォルティス | Tokushima Vortis | 299 | `https://media.api-sports.io/football/teams/299.png` | J2 2024 / 99 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | Documentation-only target; no file write yet |
| `albirex_niigata` | アルビレックス新潟 | Albirex Niigata | 311 | `https://media.api-sports.io/football/teams/311.png` | J1 2024 / 98 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | J1 2024 lookup is stable identity evidence only, not permanent division membership; no file write yet |
| `kochi_united` | 高知ユナイテッドＳＣ | Kochi United | 7129 | `https://media.api-sports.io/football/teams/7129.png` | JFL 2024 / 497 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j3Teams.js` candidate | API raw name omits `SC`, but stable club identity is clear; JFL lookup is stable identity evidence only; no file write yet |
| `ehime_fc` | 愛媛ＦＣ | Ehime FC | 318 | `https://media.api-sports.io/football/teams/318.png` | J2 2024 / 99 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | Documentation-only target; no file write yet |
| `nara_club` | 奈良クラブ | Nara Club | 7135 | `https://media.api-sports.io/football/teams/7135.png` | J3 2024 / 100 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j3Teams.js` candidate | Documentation-only target; no file write yet |

## Batch 4 j2Teams.js / j3Teams.js Exact Diff Plan

This section records a documentation-only exact diff plan for the five Batch 4 entries that may later be added to `functions/scripts/data/j2Teams.js` or `functions/scripts/data/j3Teams.js`.

It does not edit `j2Teams.js` or `j3Teams.js`, create actual module entries, create seed data, write Firestore documents, run API sync, deploy, or change any seedable status.

Summary:

- Batch 4 exact diff plan documented: yes
- Planned target files:
  - `functions/scripts/data/j2Teams.js`
  - `functions/scripts/data/j3Teams.js`
- Planned `j2Teams.js` entries: 3
- Planned `j3Teams.js` entries: 2
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- `teamIdStatuses` changed: 0
- Firestore writes: 0
- non-dry seed: 0
- `--write`: 0
- API calls: 0
- deploy: 0
- `seedable: true` changes: 0
- `reilac_shiga` included: no
- implementation status: all rows `planned-not-written`

Implementation policy:

- `j2Teams.js` and `j3Teams.js` are stable team master data candidate storage, not direct 2026 J2 / J3 special competition membership data.
- Season membership remains separate from stable team master data.
- Do not represent 2026 J2 / J3 special competition membership directly in `j2Teams.js` or `j3Teams.js`.
- Lookup source league names are API evidence for stable club identity only.
- Lookup source league names do not imply 2026 J2 / J3 special competition membership or permanent division membership.
- `tokushima_vortis`, `albirex_niigata`, and `ehime_fc` are the Batch 4 `j2Teams.js` planned entries.
- `kochi_united` and `nara_club` are the Batch 4 `j3Teams.js` planned entries.
- `reilac_shiga` remains excluded until continuity approval is completed.
- Keep `seedable` as `no` until separate module entry approval and later seed approval are completed.
- Do not run Firestore write or non-dry seed from this plan.

Planned `j2Teams.js` entries:

| target file | candidate internal team id | nameJa | nameEn | aliases | externalTeamId | logoUrl | competitionKey candidate | source evidence | implementation status | notes |
|---|---|---|---|---|---:|---|---|---|---|---|
| `functions/scripts/data/j2Teams.js` | `tokushima_vortis` | 徳島ヴォルティス | Tokushima Vortis | `['徳島', 'ヴォルティス', 'Tokushima Vortis']` | 299 | `https://media.api-sports.io/football/teams/299.png` | `football_j2` | API-SPORTS teams?league=99&season=2024 + Batch 4 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | Stable team master candidate only; no file write yet |
| `functions/scripts/data/j2Teams.js` | `albirex_niigata` | アルビレックス新潟 | Albirex Niigata | `['新潟', 'アルビレックス', 'Albirex Niigata']` | 311 | `https://media.api-sports.io/football/teams/311.png` | `football_j2` | API-SPORTS teams?league=98&season=2024 + Batch 4 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | J1 2024 lookup is stable identity evidence only, not permanent division membership |
| `functions/scripts/data/j2Teams.js` | `ehime_fc` | 愛媛ＦＣ | Ehime FC | `['愛媛', '愛媛FC', 'Ehime FC']` | 318 | `https://media.api-sports.io/football/teams/318.png` | `football_j2` | API-SPORTS teams?league=99&season=2024 + Batch 4 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | Stable team master candidate only; no file write yet |

Planned `j3Teams.js` entries:

| target file | candidate internal team id | nameJa | nameEn | aliases | externalTeamId | logoUrl | competitionKey candidate | source evidence | implementation status | notes |
|---|---|---|---|---|---:|---|---|---|---|---|
| `functions/scripts/data/j3Teams.js` | `kochi_united` | 高知ユナイテッドＳＣ | Kochi United | `['高知', '高知ユナイテッド', 'Kochi United']` | 7129 | `https://media.api-sports.io/football/teams/7129.png` | `football_j3` | API-SPORTS teams?league=497&season=2024 + Batch 4 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | API raw name omits `SC`, but stable club identity is clear; JFL lookup is stable identity evidence only |
| `functions/scripts/data/j3Teams.js` | `nara_club` | 奈良クラブ | Nara Club | `['奈良', '奈良クラブ', 'Nara Club']` | 7135 | `https://media.api-sports.io/football/teams/7135.png` | `football_j3` | API-SPORTS teams?league=100&season=2024 + Batch 4 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | Stable team master candidate only; no file write yet |

Next-step note:

- After this docs-only preparation review and exact diff plan, the next step is separate approval for actual `j2Teams.js` / `j3Teams.js` entries.
- Do not add actual entries from this docs-only plan alone.
- Do not update `teamIdStatuses` from this docs-only plan alone.
- Firestore write / non-dry seed / `--write` remains deferred.

## Per-Club Approval Decision Review - tochigi_city

This section records a documentation-only approval decision review for one Batch 2 club row.

It does not change the Batch 2 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `tochigi_city`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 2 table changed: no
- Batch 2 individual reviews completed: 1 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `tochigi_city` is a stable club identity candidate for 栃木シティ and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Tochigi City` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `7145` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/7145.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `JFL 2024 / 497` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `tochigi_city` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `tochigi_city` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - tochigi_sc

This section records a documentation-only approval decision review for one Batch 2 club row.

It does not change the Batch 2 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `tochigi_sc`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 2 table changed: no
- Batch 2 individual reviews completed: 2 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `tochigi_sc` is a stable club identity candidate for 栃木ＳＣ and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Tochigi SC` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `315` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/315.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J2 2024 / 99` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `tochigi_sc` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `tochigi_sc` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - vanraure_hachinohe

This section records a documentation-only approval decision review for one Batch 2 club row.

It does not change the Batch 2 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `vanraure_hachinohe`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 2 table changed: no
- Batch 2 individual reviews completed: 3 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `vanraure_hachinohe` is a stable club identity candidate for ヴァンラーレ八戸 and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Vanraure Hachinohe` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `4326` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/4326.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J3 2024 / 100` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `vanraure_hachinohe` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `vanraure_hachinohe` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - ventforet_kofu

This section records a documentation-only approval decision review for one Batch 2 club row.

It does not change the Batch 2 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `ventforet_kofu`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 2 table changed: no
- Batch 2 individual reviews completed: 4 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `ventforet_kofu` is a stable club identity candidate for ヴァンフォーレ甲府 and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Ventforet Kofu` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `308` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/308.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J2 2024 / 99` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `ventforet_kofu` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `ventforet_kofu` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - fujieda_myfc

This section records a documentation-only approval decision review for one Batch 2 club row.

It does not change the Batch 2 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `fujieda_myfc`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 2 table changed: no
- Batch 2 individual reviews completed: 5 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `fujieda_myfc` is a stable club identity candidate for 藤枝ＭＹＦＣ and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Fujieda MYFC` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `4317` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/4317.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing confirmed team ID collision | No existing confirmed team ID collision is recorded in this review document | pass |
| season membership separation | The `J2 2024 / 99` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `fujieda_myfc` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `fujieda_myfc` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Batch 2 Actual Module Entry Preparation Review

This section records a documentation-only final preparation review before any Batch 2 club is moved into an actual team module entry.

It does not create `approved-for-module-entry` file entries, edit `j2Teams.js` or `j3Teams.js`, create seed data, write Firestore documents, run API sync, deploy, or change any seedable status.

Summary:

- Batch 2 actual module entry preparation review documented: yes
- Batch 2 reviewed candidates: 5
- Batch 2 ready for separate module entry approval: 5
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- `reilac_shiga` included: no
- `vanraure_hachinohe` target module candidate: `j3Teams.js`
- Batch 3 created: no

Preparation policy:

- Target module candidates below are documentation-only candidates and are not actual file writes.
- All five Batch 2 rows still require separate approval before any `j2Teams.js` or `j3Teams.js` module entry is created.
- `vanraure_hachinohe` is the only Batch 2 `j3Teams.js` candidate; the other four rows are `j2Teams.js` candidates.
- Keep `seedable` as `no` until separate confirmed module entry approval and later seed approval are completed.
- Keep season membership separate from stable team master data.
- Lookup source league names are API evidence for stable club identity only. They do not imply 2026 J2 / J3 special competition membership or permanent division membership.
- `reilac_shiga` remains excluded until continuity approval is completed.

| candidate internal team id | club nameJa | API raw team name | externalTeamId | logoUrl | lookup source | per-club review status | module entry preparation status | target module candidate | notes |
|---|---|---|---:|---|---|---|---|---|---|
| `tochigi_city` | 栃木シティ | Tochigi City | 7145 | `https://media.api-sports.io/football/teams/7145.png` | JFL 2024 / 497 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | JFL lookup is stable identity API evidence only; no membership implication and no file write yet |
| `tochigi_sc` | 栃木ＳＣ | Tochigi SC | 315 | `https://media.api-sports.io/football/teams/315.png` | J2 2024 / 99 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | Documentation-only target; no file write yet |
| `vanraure_hachinohe` | ヴァンラーレ八戸 | Vanraure Hachinohe | 4326 | `https://media.api-sports.io/football/teams/4326.png` | J3 2024 / 100 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j3Teams.js` candidate | The only Batch 2 `j3Teams.js` candidate; J3 lookup is stable identity API evidence only and no file write yet |
| `ventforet_kofu` | ヴァンフォーレ甲府 | Ventforet Kofu | 308 | `https://media.api-sports.io/football/teams/308.png` | J2 2024 / 99 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | Documentation-only target; no file write yet |
| `fujieda_myfc` | 藤枝ＭＹＦＣ | Fujieda MYFC | 4317 | `https://media.api-sports.io/football/teams/4317.png` | J2 2024 / 99 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | Documentation-only target; no file write yet |

## Batch 2 j2Teams.js / j3Teams.js Exact Diff Plan

This section records a documentation-only exact diff plan for the five Batch 2 entries that may later be added to `functions/scripts/data/j2Teams.js` or `functions/scripts/data/j3Teams.js`.

It does not edit `j2Teams.js` or `j3Teams.js`, create actual module entries, create seed data, write Firestore documents, run API sync, deploy, or change any seedable status.

Summary:

- Batch 2 exact diff plan documented: yes
- Planned target files:
  - `functions/scripts/data/j2Teams.js`
  - `functions/scripts/data/j3Teams.js`
- Planned `j2Teams.js` entries: 4
- Planned `j3Teams.js` entries: 1
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- `reilac_shiga` included: no
- implementation status: all rows `planned-not-written`

Implementation policy:

- `j2Teams.js` and `j3Teams.js` are treated as stable team master data candidate storage, not direct 2026 J2 / J3 special competition membership data.
- Season membership remains separate from stable team master data.
- Do not represent 2026 J2 / J3 special competition membership directly in `j2Teams.js` or `j3Teams.js`.
- Lookup source league names are API evidence for stable club identity only. They do not imply 2026 J2 / J3 special competition membership or permanent division membership.
- `vanraure_hachinohe` is the only Batch 2 `j3Teams.js` planned entry.
- `reilac_shiga` remains excluded until continuity approval is completed.
- Keep `seedable` as `no` until separate module entry approval and later seed approval are completed.
- Do not run Firestore write or non-dry seed from this plan.

Planned `j2Teams.js` entries:

| target file | candidate internal team id | nameJa | nameEn | externalTeamId | logoUrl | competitionKey candidate | source evidence | implementation status | notes |
|---|---|---|---|---:|---|---|---|---|---|
| `functions/scripts/data/j2Teams.js` | `tochigi_city` | 栃木シティ | Tochigi City | 7145 | `https://media.api-sports.io/football/teams/7145.png` | `football_j2` | API-SPORTS teams?league=497&season=2024 + Batch 2 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | JFL 2024 lookup is stable identity API evidence only; not permanent division membership |
| `functions/scripts/data/j2Teams.js` | `tochigi_sc` | 栃木ＳＣ | Tochigi SC | 315 | `https://media.api-sports.io/football/teams/315.png` | `football_j2` | API-SPORTS teams?league=99&season=2024 + Batch 2 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | Stable team master candidate only; no file write yet |
| `functions/scripts/data/j2Teams.js` | `ventforet_kofu` | ヴァンフォーレ甲府 | Ventforet Kofu | 308 | `https://media.api-sports.io/football/teams/308.png` | `football_j2` | API-SPORTS teams?league=99&season=2024 + Batch 2 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | Stable team master candidate only; no file write yet |
| `functions/scripts/data/j2Teams.js` | `fujieda_myfc` | 藤枝ＭＹＦＣ | Fujieda MYFC | 4317 | `https://media.api-sports.io/football/teams/4317.png` | `football_j2` | API-SPORTS teams?league=99&season=2024 + Batch 2 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | Stable team master candidate only; no file write yet |

Planned `j3Teams.js` entries:

| target file | candidate internal team id | nameJa | nameEn | externalTeamId | logoUrl | competitionKey candidate | source evidence | implementation status | notes |
|---|---|---|---|---:|---|---|---|---|---|
| `functions/scripts/data/j3Teams.js` | `vanraure_hachinohe` | ヴァンラーレ八戸 | Vanraure Hachinohe | 4326 | `https://media.api-sports.io/football/teams/4326.png` | `football_j3` | API-SPORTS teams?league=100&season=2024 + Batch 2 j2Teams.js / j3Teams.js Exact Diff Plan | planned-not-written | Only Batch 2 `j3Teams.js` planned entry; stable team master candidate only and no file write yet |

## Per-Club Approval Decision Review - vegalta_sendai

This section records a documentation-only approval decision review for one Batch 1 club row.

It does not change the Batch 1 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `vegalta_sendai`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 1 table changed: no

| check | review note | result |
|---|---|---|
| candidate internal team id | `vegalta_sendai` is a stable club identity candidate for ベガルタ仙台 and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Vegalta Sendai` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `286` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/286.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing J1 confirmed team ID collision | No existing confirmed J1 team ID collision is recorded in this review document | pass |
| season membership separation | This review treats 2026 J2 / J3 tournament membership separately from stable team master data | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `vegalta_sendai` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `vegalta_sendai` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - shonan_bellmare

This section records a documentation-only approval decision review for one Batch 1 club row.

It does not change the Batch 1 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `shonan_bellmare`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 1 table changed: no

| check | review note | result |
|---|---|---|
| candidate internal team id | `shonan_bellmare` is a stable club identity candidate for 湘南ベルマーレ and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Shonan Bellmare` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `284` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/284.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing J1 confirmed team ID collision | No existing confirmed J1 team ID collision is recorded in this review document | pass |
| season membership separation | The `J1 2024 / 98` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `shonan_bellmare` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `shonan_bellmare` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - blaublitz_akita

This section records a documentation-only approval decision review for one Batch 1 club row.

It does not change the Batch 1 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `blaublitz_akita`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 1 table changed: no

| check | review note | result |
|---|---|---|
| candidate internal team id | `blaublitz_akita` is a stable club identity candidate for ブラウブリッツ秋田 and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Blaublitz Akita` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `4315` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/4315.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing J1 confirmed team ID collision | No existing confirmed J1 team ID collision is recorded in this review document | pass |
| season membership separation | The `J2 2024 / 99` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `blaublitz_akita` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `blaublitz_akita` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - yokohama_fc

This section records a documentation-only approval decision review for one Batch 1 club row.

It does not change the Batch 1 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `yokohama_fc`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 1 table changed: no

| check | review note | result |
|---|---|---|
| candidate internal team id | `yokohama_fc` is a stable club identity candidate for 横浜ＦＣ and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Yokohama FC` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `307` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/307.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing J1 confirmed team ID collision | No existing confirmed J1 team ID collision is recorded in this review document | pass |
| season membership separation | The `J2 2024 / 99` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `yokohama_fc` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `yokohama_fc` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Per-Club Approval Decision Review - montedio_yamagata

This section records a documentation-only approval decision review for one Batch 1 club row.

It does not change the Batch 1 table, create a module entry, create seed data, write Firestore documents, run API sync, or deploy.

Summary:

- Approval decision review documented: yes
- Reviewed club: `montedio_yamagata`
- Review result: `approved-for-module-entry-candidate`
- Actual module entry added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 1 table changed: no
- Batch 1 individual reviews completed: 5 / 5

| check | review note | result |
|---|---|---|
| candidate internal team id | `montedio_yamagata` is a stable club identity candidate for モンテディオ山形 and does not encode temporary J2 / J3 group membership | pass |
| API raw team name | `Montedio Yamagata` is a direct / near-direct match for the current club identity | pass |
| externalTeamId | `312` matches the API-SPORTS tracker evidence | pass |
| logoUrl | `https://media.api-sports.io/football/teams/312.png` matches the API-SPORTS tracker evidence | pass |
| name variance review | Not required for this direct / near-direct row | pass |
| existing J1 confirmed team ID collision | No existing confirmed J1 team ID collision is recorded in this review document | pass |
| season membership separation | The `J2 2024 / 99` lookup source is API evidence for stable club identity only, not 2026 J2 / J3 special competition membership or permanent division membership | pass |
| duplicate `/teams/{id}` policy | Do not create a duplicate `/teams/{id}` document; only a later approved module entry may propose this stable ID | pass |

Decision:

- `montedio_yamagata` may move forward as an `approved-for-module-entry-candidate` in documentation.
- This is not an actual `approved-for-module-entry` file change.
- Do not add `montedio_yamagata` to `j2Teams.js` or `j3Teams.js` from this review alone.
- Keep `seedable` as `no` until a separate confirmed module entry approval and later seed approval are completed.

## Batch 1 Actual Module Entry Preparation Review

This section records a documentation-only final preparation review before any Batch 1 club is moved into an actual team module entry.

It does not create `approved-for-module-entry` file entries, edit `j2Teams.js` or `j3Teams.js`, create seed data, write Firestore documents, run API sync, deploy, or change any seedable status.

Summary:

- Batch 1 actual module entry preparation review documented: yes
- Batch 1 reviewed candidates: 5
- Batch 1 ready for separate module entry approval: 5
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- Batch 2 created: no
- `reilac_shiga` included: no

Preparation policy:

- Target module candidates below are documentation-only candidates and are not actual file writes.
- All five Batch 1 rows still require separate approval before any `j2Teams.js` module entry is created.
- Keep `seedable` as `no` until separate confirmed module entry approval and later seed approval are completed.
- Keep season membership separate from stable team master data.
- The `J1 2024 / 98` lookup source for `shonan_bellmare` is API evidence for stable club identity only. It does not imply 2026 J2 / J3 special competition membership or permanent division membership.

| candidate internal team id | club nameJa | API raw team name | externalTeamId | logoUrl | lookup source | per-club review status | module entry preparation status | target module candidate | notes |
|---|---|---|---:|---|---|---|---|---|---|
| `vegalta_sendai` | ベガルタ仙台 | Vegalta Sendai | 286 | `https://media.api-sports.io/football/teams/286.png` | J2 2024 / 99 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | Documentation-only target; no file write yet |
| `shonan_bellmare` | 湘南ベルマーレ | Shonan Bellmare | 284 | `https://media.api-sports.io/football/teams/284.png` | J1 2024 / 98 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | J1 lookup is stable identity API evidence only; no membership implication and no file write yet |
| `blaublitz_akita` | ブラウブリッツ秋田 | Blaublitz Akita | 4315 | `https://media.api-sports.io/football/teams/4315.png` | J2 2024 / 99 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | Documentation-only target; no file write yet |
| `yokohama_fc` | 横浜ＦＣ | Yokohama FC | 307 | `https://media.api-sports.io/football/teams/307.png` | J2 2024 / 99 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | Documentation-only target; no file write yet |
| `montedio_yamagata` | モンテディオ山形 | Montedio Yamagata | 312 | `https://media.api-sports.io/football/teams/312.png` | J2 2024 / 99 | approved-for-module-entry-candidate | ready-for-separate-module-entry-approval | `j2Teams.js` candidate | Documentation-only target; no file write yet |

## Batch 1 j2Teams.js Exact Diff Plan

This section records a documentation-only exact diff plan for the five Batch 1 entries that may later be added to `functions/scripts/data/j2Teams.js`.

It does not edit `j2Teams.js` or `j3Teams.js`, create actual module entries, create seed data, write Firestore documents, run API sync, deploy, or change any seedable status.

Summary:

- Batch 1 j2Teams exact diff plan documented: yes
- Planned target file: `functions/scripts/data/j2Teams.js`
- Planned entries: 5
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- Firestore writes: 0
- Seedable rows changed: 0
- `reilac_shiga` included: no

Implementation policy:

- `j2Teams.js` is treated as stable team master data candidate storage, not direct 2026 J2 / J3 special competition membership data.
- Season membership remains separate from stable team master data.
- Do not represent 2026 J2 / J3 special competition membership directly in `j2Teams.js`.
- `j3Teams.js` is outside the scope of this Batch 1 plan.
- Keep `seedable` as `no` until separate module entry approval and later seed approval are completed.
- Do not run Firestore write or non-dry seed from this plan.

| target file | candidate internal team id | nameJa | nameEn | externalTeamId | logoUrl | competitionKey candidate | source evidence | implementation status | notes |
|---|---|---|---|---:|---|---|---|---|---|
| `functions/scripts/data/j2Teams.js` | `vegalta_sendai` | ベガルタ仙台 | Vegalta Sendai | 286 | `https://media.api-sports.io/football/teams/286.png` | `football_j2` | API-SPORTS teams?league=99&season=2024 | planned-not-written | Stable team master candidate only; no file write yet |
| `functions/scripts/data/j2Teams.js` | `shonan_bellmare` | 湘南ベルマーレ | Shonan Bellmare | 284 | `https://media.api-sports.io/football/teams/284.png` | `football_j2` | API-SPORTS teams?league=98&season=2024 | planned-not-written | J1 2024 lookup is stable identity evidence only, not 2026 J2/J3 membership evidence; no file write yet |
| `functions/scripts/data/j2Teams.js` | `blaublitz_akita` | ブラウブリッツ秋田 | Blaublitz Akita | 4315 | `https://media.api-sports.io/football/teams/4315.png` | `football_j2` | API-SPORTS teams?league=99&season=2024 | planned-not-written | Stable team master candidate only; no file write yet |
| `functions/scripts/data/j2Teams.js` | `yokohama_fc` | 横浜ＦＣ | Yokohama FC | 307 | `https://media.api-sports.io/football/teams/307.png` | `football_j2` | API-SPORTS teams?league=99&season=2024 | planned-not-written | Stable team master candidate only; no file write yet |
| `functions/scripts/data/j2Teams.js` | `montedio_yamagata` | モンテディオ山形 | Montedio Yamagata | 312 | `https://media.api-sports.io/football/teams/312.png` | `football_j2` | API-SPORTS teams?league=99&season=2024 | planned-not-written | Stable team master candidate only; no file write yet |

## Documentation-Only Stable Internal Team ID Candidates

The candidate IDs below are review candidates only. They are not confirmed `/teams/{id}` documents, not seed data, and not safe to write until stable identity review plus API-SPORTS team ID / logo URL verification are complete.

Note: this table is for stable ID candidate review. The current source of truth for API team ID / logo URL evidence is the `API-SPORTS Verification Tracker` above. Candidate IDs remain unconfirmed review candidates, not confirmed `/teams/{id}` documents and not seed data.

| group | club nameJa | candidate internal team id | candidate status | reason | API/team/logo status | seedable |
|---|---|---|---|---|---|---|
| EAST-A | ベガルタ仙台 | `vegalta_sendai` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-A | 湘南ベルマーレ | `shonan_bellmare` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-A | ブラウブリッツ秋田 | `blaublitz_akita` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-A | ＳＣ相模原 | `sc_sagamihara` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-A | 横浜ＦＣ | `yokohama_fc` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-A | モンテディオ山形 | `montedio_yamagata` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-A | ザスパ群馬 | `thespa_gunma` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-A | 栃木シティ | `tochigi_city` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-A | 栃木ＳＣ | `tochigi_sc` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-A | ヴァンラーレ八戸 | `vanraure_hachinohe` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-B | ヴァンフォーレ甲府 | `ventforet_kofu` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-B | いわきＦＣ | `iwaki_fc` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-B | ＲＢ大宮アルディージャ | `rb_omiya_ardija` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-B | 北海道コンサドーレ札幌 | `hokkaido_consadole_sapporo` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-B | 藤枝ＭＹＦＣ | `fujieda_myfc` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-B | ＦＣ岐阜 | `fc_gifu` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-B | 松本山雅ＦＣ | `matsumoto_yamaga` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-B | ジュビロ磐田 | `jubilo_iwata` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-B | 福島ユナイテッドＦＣ | `fukushima_united` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| EAST-B | ＡＣ長野パルセイロ | `ac_nagano_parceiro` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-A | カターレ富山 | `kataller_toyama` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-A | 徳島ヴォルティス | `tokushima_vortis` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-A | アルビレックス新潟 | `albirex_niigata` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-A | 高知ユナイテッドＳＣ | `kochi_united` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-A | 愛媛ＦＣ | `ehime_fc` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-A | ツエーゲン金沢 | `zweigen_kanazawa` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-A | ＦＣ大阪 | `fc_osaka` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-A | ＦＣ今治 | `fc_imabari` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-A | 奈良クラブ | `nara_club` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-A | カマタマーレ讃岐 | `kamatamare_sanuki` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-B | テゲバジャーロ宮崎 | `tegevajaro_miyazaki` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-B | サガン鳥栖 | `sagan_tosu` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-B | 鹿児島ユナイテッドＦＣ | `kagoshima_united` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-B | レノファ山口ＦＣ | `renofa_yamaguchi` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-B | ロアッソ熊本 | `roasso_kumamoto` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-B | 大分トリニータ | `oita_trinita` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-B | ガイナーレ鳥取 | `gainare_tottori` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-B | ギラヴァンツ北九州 | `giravanz_kitakyushu` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-B | レイラック滋賀ＦＣ | `reilac_shiga` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |
| WEST-B | ＦＣ琉球 | `fc_ryukyu` | candidate-review | Common romanized club name; no existing J1 stable ID match | externalTeamId TBD; logoUrl TBD | no |

## EAST-A

| status | group | club nameJa | internal team id | externalTeamId | logoUrl | official source | seedable | notes |
|---|---|---|---|---|---|---|---|---|
| review | EAST-A | ベガルタ仙台 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-A | 湘南ベルマーレ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-A | ブラウブリッツ秋田 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-A | ＳＣ相模原 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-A | 横浜ＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-A | モンテディオ山形 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-A | ザスパ群馬 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-A | 栃木シティ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-A | 栃木ＳＣ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-A | ヴァンラーレ八戸 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |

## EAST-B

| status | group | club nameJa | internal team id | externalTeamId | logoUrl | official source | seedable | notes |
|---|---|---|---|---|---|---|---|---|
| review | EAST-B | ヴァンフォーレ甲府 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-B | いわきＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-B | ＲＢ大宮アルディージャ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-B | 北海道コンサドーレ札幌 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-B | 藤枝ＭＹＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-B | ＦＣ岐阜 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-B | 松本山雅ＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-B | ジュビロ磐田 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-B | 福島ユナイテッドＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | EAST-B | ＡＣ長野パルセイロ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |

## WEST-A

| status | group | club nameJa | internal team id | externalTeamId | logoUrl | official source | seedable | notes |
|---|---|---|---|---|---|---|---|---|
| review | WEST-A | カターレ富山 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-A | 徳島ヴォルティス | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-A | アルビレックス新潟 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-A | 高知ユナイテッドＳＣ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-A | 愛媛ＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-A | ツエーゲン金沢 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-A | ＦＣ大阪 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-A | ＦＣ今治 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-A | 奈良クラブ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-A | カマタマーレ讃岐 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |

## WEST-B

| status | group | club nameJa | internal team id | externalTeamId | logoUrl | official source | seedable | notes |
|---|---|---|---|---|---|---|---|---|
| review | WEST-B | テゲバジャーロ宮崎 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-B | サガン鳥栖 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-B | 鹿児島ユナイテッドＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-B | レノファ山口ＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-B | ロアッソ熊本 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-B | 大分トリニータ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-B | ガイナーレ鳥取 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-B | ギラヴァンツ北九州 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-B | レイラック滋賀ＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |
| review | WEST-B | ＦＣ琉球 | TBD | TBD | TBD | J.LEAGUE standings | no | new-stable-id-candidate-needed; membership evidence only |

## J2 / J3 Season Membership Seedability Readiness Review

### Summary

- docs-only seedability readiness review: yes
- target competitionSeasonKey: `football_j2_j3_2026_hyakunen`
- current status: `review`
- current seedable: false
- total membership teamIds: 40
- confirmed team references: 15
- blocked / unconfirmed rows: 25
- Firestore writes: 0
- non-dry seed: 0
- `--write` executed: 0
- API calls: 0
- deploy: 0
- this review is not Firestore seed approval
- this review does not change seedability

### Confirmed Team Master Coverage

Confirmed team master rows:

- `vegalta_sendai`
- `shonan_bellmare`
- `blaublitz_akita`
- `yokohama_fc`
- `montedio_yamagata`
- `tochigi_city`
- `tochigi_sc`
- `ventforet_kofu`
- `fujieda_myfc`
- `jubilo_iwata`
- `vanraure_hachinohe`
- `fc_gifu`
- `matsumoto_yamaga`
- `fukushima_united`
- `kataller_toyama`

### Candidate Not Confirmed Rows

Candidate not confirmed rows:

- `sc_sagamihara`
- `thespa_gunma`
- `iwaki_fc`
- `rb_omiya_ardija`
- `hokkaido_consadole_sapporo`
- `ac_nagano_parceiro`
- `tokushima_vortis`
- `albirex_niigata`
- `kochi_united`
- `ehime_fc`
- `zweigen_kanazawa`
- `fc_osaka`
- `fc_imabari`
- `nara_club`
- `kamatamare_sanuki`
- `tegevajaro_miyazaki`
- `sagan_tosu`
- `kagoshima_united`
- `renofa_yamaguchi`
- `roasso_kumamoto`
- `oita_trinita`
- `gainare_tottori`
- `giravanz_kitakyushu`
- `fc_ryukyu`

### Blocked Continuity Rows

Blocked continuity rows:

- `reilac_shiga`
  - reason: `Reilac Shiga` / `Biwako Shiga` continuity approval is not completed
  - current action: keep excluded from confirmed / seedable rows
  - seedable: false

### Seedable True Prerequisites

- all 40 teamIds must be confirmed stable team master entries
- all 40 teamIds must have approved stable internal team IDs
- all 40 teamIds must have API evidence and logo evidence approved enough for module entry
- all `candidate_not_confirmed` rows must be converted to `confirmed_team_master`
- `reilac_shiga` continuity approval must be completed, or the row must remain excluded from seedable data
- no `blocked_continuity` rows
- no `missing_team_master` rows
- no duplicate team IDs within `competitionSeasonKey`
- verify dry-run must PASS
- seed preparation dry-run must PASS
- `write candidates` must remain 0 until explicit Firestore seed approval
- Firestore write / non-dry seed requires separate approval

### Recommended Next Path

1. Keep `football_j2_j3_2026_hyakunen` as `status: review` / `seedable: false`
2. Start next confirmed team master approval batch for remaining `candidate_not_confirmed` rows
3. Do not use bulk approval
4. Continue per-club approval decision review
5. Add actual `j2Teams.js` / `j3Teams.js` entries only after separate exact diff plan and approval
6. Re-run team master dry-run / verify after each batch
7. Update `teamIdStatuses` only after actual confirmed team module entries exist
8. Re-run `verifyCompetitionSeasonMemberships.js --dry-run`
9. Re-run `seedCompetitionSeasonMemberships.js --dry-run`
10. Only after all 40 rows are safe, consider separate `seedable: true` approval
11. Firestore write / non-dry seed / `--write` remains last and separately approved

## Batch 4 teamIdStatuses Exact Diff Plan

### Summary

- Batch 4 `teamIdStatuses` exact diff plan documented: yes
- target data module:
  - `functions/scripts/data/competitionSeasonMemberships.js`
- target competitionSeasonKey:
  - `football_j2_j3_2026_hyakunen`
- planned `teamIdStatuses` updates: 5
- actual `teamIdStatuses` changed: 0
- actual data module entries changed: 0
- `seedable: true` changes: 0
- Firestore writes: 0
- non-dry seed: 0
- `--write`: 0
- API calls: 0
- deploy: 0
- `reilac_shiga` included: no
- docs-only plan: yes

### Planned Status Changes

1. `tokushima_vortis`
   - current status: `candidate_not_confirmed`
   - planned status: `confirmed_team_master`
   - reason: actual confirmed stable team master entry now exists in `functions/scripts/data/j2Teams.js`
   - source commit: `b52516c Add J2 J3 batch 4 team entries`

2. `albirex_niigata`
   - current status: `candidate_not_confirmed`
   - planned status: `confirmed_team_master`
   - reason: actual confirmed stable team master entry now exists in `functions/scripts/data/j2Teams.js`
   - source commit: `b52516c Add J2 J3 batch 4 team entries`

3. `ehime_fc`
   - current status: `candidate_not_confirmed`
   - planned status: `confirmed_team_master`
   - reason: actual confirmed stable team master entry now exists in `functions/scripts/data/j2Teams.js`
   - source commit: `b52516c Add J2 J3 batch 4 team entries`

4. `kochi_united`
   - current status: `candidate_not_confirmed`
   - planned status: `confirmed_team_master`
   - reason: actual confirmed stable team master entry now exists in `functions/scripts/data/j3Teams.js`
   - source commit: `b52516c Add J2 J3 batch 4 team entries`

5. `nara_club`
   - current status: `candidate_not_confirmed`
   - planned status: `confirmed_team_master`
   - reason: actual confirmed stable team master entry now exists in `functions/scripts/data/j3Teams.js`
   - source commit: `b52516c Add J2 J3 batch 4 team entries`

### Expected Validation After Actual Update

- `node --check functions/scripts/data/competitionSeasonMemberships.js`: PASS
- `node functions/scripts/verifyCompetitionSeasonMemberships.js --dry-run`: PASS
  - checked seasons: 1
  - checked groups: 4
  - checked membership teamIds: 40
  - confirmed team references: 20
  - blocked/unconfirmed rows: 20
- `node functions/scripts/seedCompetitionSeasonMemberships.js --dry-run`: PASS
  - seedable seasons: 0
  - skipped non-seedable seasons: 1
  - write candidates: 0
  - written seasons: 0
- `football_j2_j3_2026_hyakunen` remains `status: review` / `seedable: false`
- Firestore will not be written

### Policy Notes

- This plan only changes local season membership status metadata after actual stable team master entries exist.
- This plan does not make the season seedable.
- This plan does not approve Firestore writes.
- `seedable: true` requires separate approval after all 40 rows are safe.
- `reilac_shiga` remains `blocked_continuity`.
- `reilac_shiga` / `Biwako Shiga` continuity approval remains a separate task.
- Firestore write / non-dry seed / `--write` remains last and separately approved.
- All-Sports Season Rollover Policy remains unchanged.

### Next-Step Note

- After this docs-only plan is committed, actual `competitionSeasonMemberships.js` `teamIdStatuses` update can be considered separately.
- Do not update actual `teamIdStatuses` from this docs-only plan alone.
- Do not change `seedable: false`.

## Per-Club Approval Batch 5

This is a docs-only candidate list. It is not bulk approval, not actual module entry creation, and not season membership seed approval.

Summary:

- Batch 5 candidate list documented: yes
- Batch 5 candidates listed: 5
- Batch 5 candidates approved for module entry: 0
- Actual module entries added: 0
- `j2Teams.js` entries added: 0
- `j3Teams.js` entries added: 0
- `teamIdStatuses` changed: 0
- Firestore writes: 0
- non-dry seed: 0
- `--write`: 0
- API calls: 0
- deploy: 0
- `seedable: true` changes: 0
- `reilac_shiga` included: no
- bulk approval: no
- `football_j2_j3_2026_hyakunen` remains `status: review` / `seedable: false`
- All-Sports Season Rollover Policy remains unchanged

| candidate internal team id | club nameJa | API raw team name | externalTeamId | logoUrl | lookup source | variance status | recommended approval state | approval decision | target module candidate | notes |
|---|---|---|---|---|---|---|---|---|---|---|
| `sc_sagamihara` | `ＳＣ相模原` | `Sagamihara` | `4324` | `https://media.api-sports.io/football/teams/4324.png` | `J3 2024 / 100` | `name-variance-reviewed` | `approval-ready-after-variance-review` | `not-approved-yet` | `j3Teams.js` candidate | API raw name omits SC; stable club identity should be reviewed in per-club decision before module entry |
| `thespa_gunma` | `ザスパ群馬` | `Thespakusatsu Gunma` | `302` | `https://media.api-sports.io/football/teams/302.png` | `J2 2024 / 99` | `name-variance-reviewed` | `approval-ready-after-variance-review` | `not-approved-yet` | `j2Teams.js` candidate | API raw name uses older / variant form; stable club identity should be reviewed in per-club decision before module entry |
| `iwaki_fc` | `いわきＦＣ` | `Iwaki` | `7017` | `https://media.api-sports.io/football/teams/7017.png` | `J2 2024 / 99` | `name-variance-reviewed` | `approval-ready-after-variance-review` | `not-approved-yet` | `j2Teams.js` candidate | API raw name omits `FC`; stable club identity should be reviewed in per-club decision before module entry |
| `rb_omiya_ardija` | `ＲＢ大宮アルディージャ` | `Omiya Ardija` | `294` | `https://media.api-sports.io/football/teams/294.png` | `J3 2024 / 100` | `name-variance-reviewed` | `approval-ready-after-variance-review` | `not-approved-yet` | `j2Teams.js` candidate | Current official-facing name includes `RB`; API raw name is older / shorter evidence and requires per-club decision review before module entry |
| `hokkaido_consadole_sapporo` | `北海道コンサドーレ札幌` | `Consadole Sapporo` | `289` | `https://media.api-sports.io/football/teams/289.png` | `J1 2024 / 98` | `name-variance-reviewed` | `approval-ready-after-variance-review` | `not-approved-yet` | `j2Teams.js` candidate | API raw name omits `Hokkaido`; J1 2024 lookup is stable identity evidence only, not permanent division membership |

Correction note:

- Batch 5 correction documented: yes
- corrected candidate: `sc_sagamihara`
- corrected field values:
  - API raw team name: `Sagamihara`
  - externalTeamId: `4324`
  - logoUrl: `https://media.api-sports.io/football/teams/4324.png`
  - variance status: `name-variance-reviewed`
  - recommended approval state: `approval-ready-after-variance-review`
- reason:
  - align Batch 5 candidate list with existing API-SPORTS Verification Tracker
- actual module entries added: 0
- `teamIdStatuses` changed: 0
- `seedable: true` changes: 0
- Firestore writes: 0
- non-dry seed: 0
- `--write`: 0
- API calls: 0
- deploy: 0

Policy notes:

- Batch 5 is not bulk approval.
- Each Batch 5 club still requires a separate per-club approval decision review.
- Do not create actual `j2Teams.js` or `j3Teams.js` entries from this candidate list alone.
- Do not update `teamIdStatuses` from this candidate list alone.
- Do not change `seedable: true`.
- Firestore write / non-dry seed / `--write` remains deferred.
- `reilac_shiga` / `Biwako Shiga` continuity approval remains a separate task.

Next-step note:

- Next step is Batch 5 per-club approval decision review.
- The review can be done in one work item if each club receives a separate approval decision review section.
- Actual module entries still require separate exact diff plan and approval.

### All-Sports Season Rollover Policy

- `competitionSeasonKey` is not specific to J2 / J3 2026; it is the season / tournament membership scope for all sports and all years.
- This app requires annual season membership data updates.
- Annual updates do not mean duplicating the app itself or duplicating stable team master data every year.
- `/teams/{id}` remains the stable team identity.
- Season / tournament / league membership is added on the `competitionSeasonKey` side.
- When a season changes, create a new season membership candidate for the new `competitionSeasonKey`.
- Promotion / relegation / league expansion / conference change / division change is represented as new season membership rows, not as team master duplication.
- Automation may cover candidate generation / diff detection / validation / dry-run.
- `seedable: true`, Firestore write, non-dry seed, and `--write` require human approval.
- The 2026 special season is only the first concrete example of this general season membership model.

Example future `competitionSeasonKey` values:

- `football_j1_2027`
- `football_j2_2027`
- `football_j3_2027`
- `football_j1_2028`
- `baseball_npb_2027`
- `basketball_b_league_2027`
- `american_football_nfl_2027`
- `rugby_league_one_2027`

Annual operation flow:

1. Generate next season membership candidates
2. Compare against previous season
3. Detect promoted / relegated / new / removed / renamed / rebranded teams
4. Mark uncertain rows as `candidate_not_confirmed`, `blocked_continuity`, or `missing_team_master`
5. Run verify dry-run
6. Run seed preparation dry-run
7. Human review / approval
8. Only then consider `seedable: true`
9. Firestore write / non-dry seed / `--write` remains last and separately approved

### Explicit Deferred Items

- `seedable: true`
- Firestore write
- non-dry seed
- `--write`
- API sync
- deploy
- `reilac_shiga` / `Biwako Shiga` continuity approval
- additional confirmed team module entries
- additional API calls unless separately approved

## Unresolved Items

- No clubs in this membership review currently match existing confirmed J1 stable team IDs.
- Candidate internal team IDs remain documentation-only review candidates.
- Review `api-lookup-name-variance-review` rows before treating API evidence as seedable.
- Do not create confirmed `/teams/{id}` documents until stable identity + API evidence + logo evidence are approved together.
- Add season membership data separately after stable team IDs are confirmed.
- Keep `j2Teams.js` and `j3Teams.js` empty until seedable stable identities are approved.
