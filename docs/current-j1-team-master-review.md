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
| pending | 浦和レッズ | Urawa Reds | `urawa_reds` | 287 | `https://media.api-sports.io/football/teams/287.png` | 浦和, レッズ, Urawa Reds | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | ジェフユナイテッド千葉 | JEF United Chiba | `jef_united_chiba` | 要確認 | 要確認 | 千葉, ジェフ, ジェフ千葉, JEF United Chiba, JEF Chiba | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | 柏レイソル | Kashiwa Reysol | `kashiwa_reysol` | 281 | `https://media.api-sports.io/football/teams/281.png` | 柏, レイソル, Kashiwa Reysol | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | ＦＣ東京 | FC Tokyo | `fc_tokyo` | 292 | `https://media.api-sports.io/football/teams/292.png` | FC東京, 東京, FC Tokyo | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | 東京ヴェルディ | Tokyo Verdy | `tokyo_verdy` | 306 | `https://media.api-sports.io/football/teams/306.png` | 東京V, ヴェルディ, Tokyo Verdy | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | ＦＣ町田ゼルビア | FC Machida Zelvia | `fc_machida_zelvia` | 303 | `https://media.api-sports.io/football/teams/303.png` | 町田, ゼルビア, FC Machida Zelvia, Machida Zelvia | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | 川崎フロンターレ | Kawasaki Frontale | `kawasaki_frontale` | 294 | `https://media.api-sports.io/football/teams/294.png` | 川崎, フロンターレ, Kawasaki Frontale | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | 横浜Ｆ・マリノス | Yokohama F･Marinos | `yokohama_f_marinos` | 296 | `https://media.api-sports.io/football/teams/296.png` | 横浜FM, マリノス, Yokohama F･Marinos, Yokohama F. Marinos, F. Marinos | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | 清水エスパルス | Shimizu S-Pulse | `shimizu_s_pulse` | 要確認 | 要確認 | 清水, エスパルス, Shimizu S-Pulse | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | 名古屋グランパス | Nagoya Grampus | `nagoya_grampus` | 288 | `https://media.api-sports.io/football/teams/288.png` | 名古屋, グランパス, Nagoya Grampus | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | 京都サンガF.C. | Kyoto Sanga F.C. | `kyoto_sanga` | 302 | `https://media.api-sports.io/football/teams/302.png` | 京都, サンガ, Kyoto Sanga F.C., Kyoto Sanga | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | ガンバ大阪 | Gamba Osaka | `gamba_osaka` | 293 | `https://media.api-sports.io/football/teams/293.png` | G大阪, ガンバ, Gamba Osaka | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | セレッソ大阪 | Cerezo Osaka | `cerezo_osaka` | 291 | `https://media.api-sports.io/football/teams/291.png` | C大阪, セレッソ, Cerezo Osaka | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | ヴィッセル神戸 | Vissel Kobe | `vissel_kobe` | 289 | `https://media.api-sports.io/football/teams/289.png` | 神戸, ヴィッセル, Vissel Kobe | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | ファジアーノ岡山 | Fagiano Okayama | `fagiano_okayama` | 要確認 | 要確認 | 岡山, ファジアーノ, Fagiano Okayama | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |
| pending | サンフレッチェ広島 | Sanfrecce Hiroshima | `sanfrecce_hiroshima` | 282 | `https://media.api-sports.io/football/teams/282.png` | 広島, サンフレッチェ, Sanfrecce Hiroshima | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | アビスパ福岡 | Avispa Fukuoka | `avispa_fukuoka` | 316 | `https://media.api-sports.io/football/teams/316.png` | 福岡, アビスパ, Avispa Fukuoka | J.LEAGUE official 2026 J1 list | API-SPORTS 2024 J1 output; reference-only ID/logo match | Membership confirmed; API match reference-only |
| pending | Ｖ・ファーレン長崎 | V-Varen Nagasaki | `v_varen_nagasaki` | 要確認 | 要確認 | 長崎, Ｖ・ファーレン, V-Varen Nagasaki, V. Varen Nagasaki | J.LEAGUE official 2026 J1 list | pending; 2024 API output may be reference-only | Membership confirmed; API match pending |

## Pending Current J1 Teams

The Review Table above now includes the official/current J1 membership candidates. Rows remain `pending` until the API-SPORTS team ID and logo URL are confirmed. Do not add pending rows to `j1Teams.js`.

## Next Steps

1. Confirm current J1 team list from official/current source.
2. Match API-SPORTS team ID and logo URL only where identity is confirmed.
3. Add confirmed rows to `j1Teams.js`.
4. Run generic seed/verify dry-run.
5. Run actual seed/verify only after approval.
