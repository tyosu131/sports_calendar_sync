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

## Sources

- J.LEAGUE official 2026 club composition announcement: <https://www.jleague.jp/news/article/32852>
- J.LEAGUE official English club composition page: <https://aboutj.jleague.jp/corporate/en/about_jclubs/profile_jclubs/>
- Existing repo seed / verify baseline for `kashima_antlers`: `functions/scripts/data/j1Teams.js`

## Review Table

| status | nameJa | nameEn | doc id | externalTeamId | logoUrl | aliases | membership source | API match source | notes |
|---|---|---|---|---:|---|---|---|---|---|
| confirmed | 鹿島アントラーズ | Kashima | `kashima_antlers` | 290 | `https://media.api-sports.io/football/teams/290.png` | 鹿島, アントラーズ, Kashima Antlers, Antlers | J.LEAGUE official 2026 J1 list; existing seed / verified in repo | existing seed / verified in repo | Current repo baseline team |
| pending | 水戸ホーリーホック | Mito Hollyhock | `mito_hollyhock` | 要確認 | 要確認 | 水戸, ホーリーホック, Mito Hollyhock | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | 浦和レッズ | Urawa Reds | `urawa_reds` | 要確認 | 要確認 | 浦和, レッズ, Urawa Reds | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | ジェフユナイテッド千葉 | JEF United Chiba | `jef_united_chiba` | 要確認 | 要確認 | 千葉, ジェフ, ジェフ千葉, JEF United Chiba, JEF Chiba | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | 柏レイソル | Kashiwa Reysol | `kashiwa_reysol` | 要確認 | 要確認 | 柏, レイソル, Kashiwa Reysol | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | ＦＣ東京 | FC Tokyo | `fc_tokyo` | 要確認 | 要確認 | FC東京, 東京, FC Tokyo | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | 東京ヴェルディ | Tokyo Verdy | `tokyo_verdy` | 要確認 | 要確認 | 東京V, ヴェルディ, Tokyo Verdy | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | ＦＣ町田ゼルビア | FC Machida Zelvia | `fc_machida_zelvia` | 要確認 | 要確認 | 町田, ゼルビア, FC Machida Zelvia, Machida Zelvia | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | 川崎フロンターレ | Kawasaki Frontale | `kawasaki_frontale` | 要確認 | 要確認 | 川崎, フロンターレ, Kawasaki Frontale | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | 横浜Ｆ・マリノス | Yokohama F･Marinos | `yokohama_f_marinos` | 要確認 | 要確認 | 横浜FM, マリノス, Yokohama F･Marinos, Yokohama F. Marinos, F. Marinos | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | 清水エスパルス | Shimizu S-Pulse | `shimizu_s_pulse` | 要確認 | 要確認 | 清水, エスパルス, Shimizu S-Pulse | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | 名古屋グランパス | Nagoya Grampus | `nagoya_grampus` | 要確認 | 要確認 | 名古屋, グランパス, Nagoya Grampus | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | 京都サンガF.C. | Kyoto Sanga F.C. | `kyoto_sanga` | 要確認 | 要確認 | 京都, サンガ, Kyoto Sanga F.C., Kyoto Sanga | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | ガンバ大阪 | Gamba Osaka | `gamba_osaka` | 要確認 | 要確認 | G大阪, ガンバ, Gamba Osaka | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | セレッソ大阪 | Cerezo Osaka | `cerezo_osaka` | 要確認 | 要確認 | C大阪, セレッソ, Cerezo Osaka | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | ヴィッセル神戸 | Vissel Kobe | `vissel_kobe` | 要確認 | 要確認 | 神戸, ヴィッセル, Vissel Kobe | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | ファジアーノ岡山 | Fagiano Okayama | `fagiano_okayama` | 要確認 | 要確認 | 岡山, ファジアーノ, Fagiano Okayama | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | サンフレッチェ広島 | Sanfrecce Hiroshima | `sanfrecce_hiroshima` | 要確認 | 要確認 | 広島, サンフレッチェ, Sanfrecce Hiroshima | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | アビスパ福岡 | Avispa Fukuoka | `avispa_fukuoka` | 要確認 | 要確認 | 福岡, アビスパ, Avispa Fukuoka | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | Ｖ・ファーレン長崎 | V-Varen Nagasaki | `v_varen_nagasaki` | 要確認 | 要確認 | 長崎, Ｖ・ファーレン, V-Varen Nagasaki, V. Varen Nagasaki | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |

## Pending Current J1 Teams

The Review Table above now includes the official/current J1 membership candidates. Rows remain `pending` until the API-SPORTS team ID and logo URL are confirmed. Do not add pending rows to `j1Teams.js`.

## Next Steps

1. Confirm current J1 team list from official/current source.
2. Match API-SPORTS team ID and logo URL only where identity is confirmed.
3. Add confirmed rows to `j1Teams.js`.
4. Run generic seed/verify dry-run.
5. Run actual seed/verify only after approval.
