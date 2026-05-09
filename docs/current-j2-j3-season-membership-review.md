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

This section is documentation-only planning and evidence tracking for the later API-SPORTS team ID / logo URL verification step.

No API-SPORTS API call was run for this review update. Any future API-SPORTS call must be approved before execution, including the reason and exact command.

Current status:

- Candidate rows requiring API / logo verification: 40
- API-SPORTS IDs verified: 0
- Logo URLs verified: 0
- Rows ready for seed data: 0
- `externalTeamId`: remains `TBD` for every row
- `logoUrl`: remains `TBD` for every row
- `seedable`: remains `no` for every row
- `j2Teams.js` / `j3Teams.js`: remain empty until stable identity + API / logo verification is complete and approved

Verification rules:

- Match API-SPORTS teams against the stable club identity, not against temporary 2026 group membership.
- Do not encode J2 / J3 division or 2026 group names in stable team IDs.
- Do not infer API-SPORTS team IDs or logo URLs from J.LEAGUE pages.
- Record API-SPORTS evidence separately before moving any row into seedable data.
- Treat ambiguous API matches as unresolved.
- Keep `externalTeamId` / `logoUrl` as `TBD` until direct API-SPORTS evidence is reviewed.
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

## API-SPORTS Verification Tracker

Every row remains not started. This table is not seed data.

| group | club nameJa | candidate internal team id | API-SPORTS verification status | externalTeamId | logoUrl | evidence | seedable |
|---|---|---|---|---|---|---|---|
| EAST-A | ベガルタ仙台 | `vegalta_sendai` | not-started | TBD | TBD | not checked | no |
| EAST-A | 湘南ベルマーレ | `shonan_bellmare` | not-started | TBD | TBD | not checked | no |
| EAST-A | ブラウブリッツ秋田 | `blaublitz_akita` | not-started | TBD | TBD | not checked | no |
| EAST-A | ＳＣ相模原 | `sc_sagamihara` | not-started | TBD | TBD | not checked | no |
| EAST-A | 横浜ＦＣ | `yokohama_fc` | not-started | TBD | TBD | not checked | no |
| EAST-A | モンテディオ山形 | `montedio_yamagata` | not-started | TBD | TBD | not checked | no |
| EAST-A | ザスパ群馬 | `thespa_gunma` | not-started | TBD | TBD | not checked | no |
| EAST-A | 栃木シティ | `tochigi_city` | not-started | TBD | TBD | not checked | no |
| EAST-A | 栃木ＳＣ | `tochigi_sc` | not-started | TBD | TBD | not checked | no |
| EAST-A | ヴァンラーレ八戸 | `vanraure_hachinohe` | not-started | TBD | TBD | not checked | no |
| EAST-B | ヴァンフォーレ甲府 | `ventforet_kofu` | not-started | TBD | TBD | not checked | no |
| EAST-B | いわきＦＣ | `iwaki_fc` | not-started | TBD | TBD | not checked | no |
| EAST-B | ＲＢ大宮アルディージャ | `rb_omiya_ardija` | not-started | TBD | TBD | not checked | no |
| EAST-B | 北海道コンサドーレ札幌 | `hokkaido_consadole_sapporo` | not-started | TBD | TBD | not checked | no |
| EAST-B | 藤枝ＭＹＦＣ | `fujieda_myfc` | not-started | TBD | TBD | not checked | no |
| EAST-B | ＦＣ岐阜 | `fc_gifu` | not-started | TBD | TBD | not checked | no |
| EAST-B | 松本山雅ＦＣ | `matsumoto_yamaga` | not-started | TBD | TBD | not checked | no |
| EAST-B | ジュビロ磐田 | `jubilo_iwata` | not-started | TBD | TBD | not checked | no |
| EAST-B | 福島ユナイテッドＦＣ | `fukushima_united` | not-started | TBD | TBD | not checked | no |
| EAST-B | ＡＣ長野パルセイロ | `ac_nagano_parceiro` | not-started | TBD | TBD | not checked | no |
| WEST-A | カターレ富山 | `kataller_toyama` | not-started | TBD | TBD | not checked | no |
| WEST-A | 徳島ヴォルティス | `tokushima_vortis` | not-started | TBD | TBD | not checked | no |
| WEST-A | アルビレックス新潟 | `albirex_niigata` | not-started | TBD | TBD | not checked | no |
| WEST-A | 高知ユナイテッドＳＣ | `kochi_united` | not-started | TBD | TBD | not checked | no |
| WEST-A | 愛媛ＦＣ | `ehime_fc` | not-started | TBD | TBD | not checked | no |
| WEST-A | ツエーゲン金沢 | `zweigen_kanazawa` | not-started | TBD | TBD | not checked | no |
| WEST-A | ＦＣ大阪 | `fc_osaka` | not-started | TBD | TBD | not checked | no |
| WEST-A | ＦＣ今治 | `fc_imabari` | not-started | TBD | TBD | not checked | no |
| WEST-A | 奈良クラブ | `nara_club` | not-started | TBD | TBD | not checked | no |
| WEST-A | カマタマーレ讃岐 | `kamatamare_sanuki` | not-started | TBD | TBD | not checked | no |
| WEST-B | テゲバジャーロ宮崎 | `tegevajaro_miyazaki` | not-started | TBD | TBD | not checked | no |
| WEST-B | サガン鳥栖 | `sagan_tosu` | not-started | TBD | TBD | not checked | no |
| WEST-B | 鹿児島ユナイテッドＦＣ | `kagoshima_united` | not-started | TBD | TBD | not checked | no |
| WEST-B | レノファ山口ＦＣ | `renofa_yamaguchi` | not-started | TBD | TBD | not checked | no |
| WEST-B | ロアッソ熊本 | `roasso_kumamoto` | not-started | TBD | TBD | not checked | no |
| WEST-B | 大分トリニータ | `oita_trinita` | not-started | TBD | TBD | not checked | no |
| WEST-B | ガイナーレ鳥取 | `gainare_tottori` | not-started | TBD | TBD | not checked | no |
| WEST-B | ギラヴァンツ北九州 | `giravanz_kitakyushu` | not-started | TBD | TBD | not checked | no |
| WEST-B | レイラック滋賀ＦＣ | `reilac_shiga` | not-started | TBD | TBD | not checked | no |
| WEST-B | ＦＣ琉球 | `fc_ryukyu` | not-started | TBD | TBD | not checked | no |

## Documentation-Only Stable Internal Team ID Candidates

The candidate IDs below are review candidates only. They are not confirmed `/teams/{id}` documents, not seed data, and not safe to write until stable identity review plus API-SPORTS team ID / logo URL verification are complete.

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
- Create new stable team IDs only after identity review confirms the club is not already present.
- Verify API-SPORTS team IDs.
- Verify logo URLs.
- Add season membership data separately after stable team IDs are confirmed.
- Keep `j2Teams.js` and `j3Teams.js` empty until seedable stable identities are approved.
