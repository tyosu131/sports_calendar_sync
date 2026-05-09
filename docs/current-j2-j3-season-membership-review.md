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

## EAST-A

| status | group | club nameJa | internal team id | externalTeamId | logoUrl | official source | seedable | notes |
|---|---|---|---|---|---|---|---|---|
| review | EAST-A | ベガルタ仙台 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-A | 湘南ベルマーレ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-A | ブラウブリッツ秋田 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-A | ＳＣ相模原 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-A | 横浜ＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-A | モンテディオ山形 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-A | ザスパ群馬 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-A | 栃木シティ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-A | 栃木ＳＣ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-A | ヴァンラーレ八戸 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |

## EAST-B

| status | group | club nameJa | internal team id | externalTeamId | logoUrl | official source | seedable | notes |
|---|---|---|---|---|---|---|---|---|
| review | EAST-B | ヴァンフォーレ甲府 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-B | いわきＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-B | ＲＢ大宮アルディージャ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-B | 北海道コンサドーレ札幌 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-B | 藤枝ＭＹＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-B | ＦＣ岐阜 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-B | 松本山雅ＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-B | ジュビロ磐田 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-B | 福島ユナイテッドＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | EAST-B | ＡＣ長野パルセイロ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |

## WEST-A

| status | group | club nameJa | internal team id | externalTeamId | logoUrl | official source | seedable | notes |
|---|---|---|---|---|---|---|---|---|
| review | WEST-A | カターレ富山 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-A | 徳島ヴォルティス | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-A | アルビレックス新潟 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-A | 高知ユナイテッドＳＣ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-A | 愛媛ＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-A | ツエーゲン金沢 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-A | ＦＣ大阪 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-A | ＦＣ今治 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-A | 奈良クラブ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-A | カマタマーレ讃岐 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |

## WEST-B

| status | group | club nameJa | internal team id | externalTeamId | logoUrl | official source | seedable | notes |
|---|---|---|---|---|---|---|---|---|
| review | WEST-B | テゲバジャーロ宮崎 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-B | サガン鳥栖 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-B | 鹿児島ユナイテッドＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-B | レノファ山口ＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-B | ロアッソ熊本 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-B | 大分トリニータ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-B | ガイナーレ鳥取 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-B | ギラヴァンツ北九州 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-B | レイラック滋賀ＦＣ | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |
| review | WEST-B | ＦＣ琉球 | TBD | TBD | TBD | J.LEAGUE standings | no | Membership evidence only |

## Unresolved Items

- Map each club to an existing stable internal team ID where one already exists.
- Create new stable team IDs only after identity review confirms the club is not already present.
- Verify API-SPORTS team IDs.
- Verify logo URLs.
- Add season membership data separately after stable team IDs are confirmed.
- Keep `j2Teams.js` and `j3Teams.js` empty until seedable stable identities are approved.
