# V1 presentation coverage — 2026-09-21

Public game/Team fields only; read-only Firestore projection. No GOAL/API-SPORTS
request is needed to reproduce this report. The snapshot contains no user data,
calendar URLs or credentials. Kickoff/status used in tests are synthetic.

- Games: 89; participant slots: 178; distinct provider labels: 52.
- Competition/participant rows: 57; server names matching frozen expectations: 178/178.
- Flutter tests independently validate all 178 names and candidate logo URLs against the same frozen oracle and captured masters.
- ICS and Google tests exercise their actual output builders for all 89 games.
- Unresolved participant names: NONE in this captured set. Candidate URLs resolve for every slot.
- Public V1 rendering: 0 rights-cleared club logos; all 178 slots intentionally use neutral badges/monograms. Tests enforce this at the public presentation boundary.
- This is URL resolution coverage, **not** an assertion of image delivery, image rights, Google publication, or iPhone verification.
- Unknown/ambiguous/partial participants outside this set retain fallback; no canonical IDs are inferred.

Reproduce after Functions build: node functions/scripts/auditV1Presentation.js.
Source: test/fixtures/v1_presentation_snapshot.json. See [logo provenance](logo-provenance.md) for release blockers.

| Competition | Provider participant | Current name output | Expected name | Candidate logo (NOT rights-cleared) | Metadata resolved | Evidence source |
|---|---|---|---|---|---|---|
| football_champions_league | Arsenal FC | Arsenal | Arsenal | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/359.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_champions_league | Bayern München | Bayern Munich | Bayern Munich | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/132.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/ger.1/teams?limit=100 |
| football_champions_league | Borussia Dortmund | Borussia Dortmund | Borussia Dortmund | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/124.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/ger.1/teams?limit=100 |
| football_champions_league | Lille | Lille | Lille | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/166.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/fra.1/teams?limit=100 |
| football_champions_league | Napoli | Napoli | Napoli | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/114.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/ita.1/teams?limit=100 |
| football_champions_league | Real Betis | Real Betis | Real Betis | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/244.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/esp.1/teams?limit=100 |
| football_champions_league | Real Madrid | Real Madrid | Real Madrid | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/86.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/esp.1/teams?limit=100 |
| football_champions_league | Sabah | Sabah | Sabah | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/21922.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/uefa.champions/teams?limit=100 |
| football_champions_league | Slavia Praha | Slavia Prague | Slavia Prague | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/494.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/uefa.champions/teams?limit=100 |
| football_emperor_cup | Kawasaki Frontale | 川崎フロンターレ | 川崎フロンターレ | [URL](https://media.api-sports.io/football/teams/294.png) | yes | functions/scripts/data/j1Teams.js |
| football_emperor_cup | Tegevajaro Miyazaki | テゲバジャーロ宮崎 | テゲバジャーロ宮崎 | [URL](https://media.api-sports.io/football/teams/10409.png) | yes | functions/scripts/data/j3Teams.js |
| football_emperor_cup | Tochigi | 栃木ＳＣ | 栃木ＳＣ | [URL](https://media.api-sports.io/football/teams/315.png) | yes | functions/scripts/data/j2Teams.js |
| football_j_league_cup | Kawasaki Frontale | 川崎フロンターレ | 川崎フロンターレ | [URL](https://media.api-sports.io/football/teams/294.png) | yes | functions/scripts/data/j1Teams.js |
| football_j_league_cup | Roasso Kumamoto | ロアッソ熊本 | ロアッソ熊本 | [URL](https://media.api-sports.io/football/teams/314.png) | yes | functions/scripts/data/j2Teams.js |
| football_j1 | Avispa Fukuoka | アビスパ福岡 | アビスパ福岡 | [URL](https://media.api-sports.io/football/teams/316.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Cerezo Osaka | セレッソ大阪 | セレッソ大阪 | [URL](https://media.api-sports.io/football/teams/291.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Fagiano Okayama | ファジアーノ岡山 | ファジアーノ岡山 | [URL](https://media.api-sports.io/football/teams/310.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Gamba Osaka | ガンバ大阪 | ガンバ大阪 | [URL](https://media.api-sports.io/football/teams/293.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | JEF United | ジェフユナイテッド千葉 | ジェフユナイテッド千葉 | [URL](https://media.api-sports.io/football/teams/301.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Kashima Antlers | 鹿島アントラーズ | 鹿島アントラーズ | [URL](https://media.api-sports.io/football/teams/290.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Kashiwa Reysol | 柏レイソル | 柏レイソル | [URL](https://media.api-sports.io/football/teams/281.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Kawasaki Frontale | 川崎フロンターレ | 川崎フロンターレ | [URL](https://media.api-sports.io/football/teams/294.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Kyoto Sanga | 京都サンガF.C. | 京都サンガF.C. | [URL](https://media.api-sports.io/football/teams/302.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Machida Zelvia | ＦＣ町田ゼルビア | ＦＣ町田ゼルビア | [URL](https://media.api-sports.io/football/teams/303.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Mito Hollyhock | 水戸ホーリーホック | 水戸ホーリーホック | [URL](https://media.api-sports.io/football/teams/305.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Nagoya Grampus | 名古屋グランパス | 名古屋グランパス | [URL](https://media.api-sports.io/football/teams/288.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Sanfrecce Hiroshima | サンフレッチェ広島 | サンフレッチェ広島 | [URL](https://media.api-sports.io/football/teams/282.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Shimizu S-Pulse | 清水エスパルス | 清水エスパルス | [URL](https://media.api-sports.io/football/teams/283.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Tokyo | ＦＣ東京 | ＦＣ東京 | [URL](https://media.api-sports.io/football/teams/292.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Tokyo Verdy | 東京ヴェルディ | 東京ヴェルディ | [URL](https://media.api-sports.io/football/teams/306.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Urawa Reds | 浦和レッズ | 浦和レッズ | [URL](https://media.api-sports.io/football/teams/287.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | V-Varen Nagasaki | Ｖ・ファーレン長崎 | Ｖ・ファーレン長崎 | [URL](https://media.api-sports.io/football/teams/285.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Vissel Kobe | ヴィッセル神戸 | ヴィッセル神戸 | [URL](https://media.api-sports.io/football/teams/289.png) | yes | functions/scripts/data/j1Teams.js |
| football_j1 | Yokohama F. Marinos | 横浜Ｆ・マリノス | 横浜Ｆ・マリノス | [URL](https://media.api-sports.io/football/teams/296.png) | yes | functions/scripts/data/j1Teams.js |
| football_league_cup | Arsenal FC | Arsenal | Arsenal | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/359.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_league_cup | Fleetwood Town | Fleetwood Town | Fleetwood Town | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/3891.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.4/teams?limit=100 |
| football_league_cup | Ipswich Town | Ipswich Town | Ipswich Town | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/373.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | AFC Bournemouth | AFC Bournemouth | AFC Bournemouth | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/349.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Arsenal FC | Arsenal | Arsenal | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/359.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Aston Villa | Aston Villa | Aston Villa | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/362.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Brentford | Brentford | Brentford | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/337.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Brighton & Hove Albion | Brighton & Hove Albion | Brighton & Hove Albion | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/331.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Chelsea | Chelsea | Chelsea | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/363.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Coventry City | Coventry City | Coventry City | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/388.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Crystal Palace | Crystal Palace | Crystal Palace | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/384.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Everton | Everton | Everton | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/368.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Fulham | Fulham | Fulham | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/370.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Hull City | Hull City | Hull City | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/306.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Ipswich Town | Ipswich Town | Ipswich Town | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/373.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Leeds United | Leeds United | Leeds United | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/357.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Liverpool | Liverpool | Liverpool | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/364.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Manchester City | Manchester City | Manchester City | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/382.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Manchester United | Manchester United | Manchester United | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/360.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Newcastle United | Newcastle United | Newcastle United | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/361.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Nottingham Forest | Nottingham Forest | Nottingham Forest | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/393.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Sunderland | Sunderland | Sunderland | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/366.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| football_premier | Tottenham Hotspur | Tottenham Hotspur | Tottenham Hotspur | [URL](https://a.espncdn.com/i/teamlogos/soccer/500/367.png) | yes | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
