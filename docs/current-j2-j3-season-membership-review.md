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

## Unresolved Items

- No clubs in this membership review currently match existing confirmed J1 stable team IDs.
- Candidate internal team IDs remain documentation-only review candidates.
- Review `api-lookup-name-variance-review` rows before treating API evidence as seedable.
- Do not create confirmed `/teams/{id}` documents until stable identity + API evidence + logo evidence are approved together.
- Add season membership data separately after stable team IDs are confirmed.
- Keep `j2Teams.js` and `j3Teams.js` empty until seedable stable identities are approved.
