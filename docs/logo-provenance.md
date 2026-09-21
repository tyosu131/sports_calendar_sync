# Logo provenance and public-release boundary

Audit date: 2026-09-21. This inventory covers every logo URL introduced into the
shared presentation catalog by the current local diff. No logo bytes were
copied, downloaded into the repository, or rehosted. Tests use URLs as metadata;
they do not load remote images.

## Current public V1 policy

Only logos with an exact URL and reviewed public-use permission evidence may
reach an image widget. The shared public policy currently has **zero approved
assets**. All existing API-SPORTS and new ESPN URLs remain candidate metadata;
Home, Schedule, Detail, Search and Followed Teams use neutral badges/monograms
without requesting those images. Game/master authority does not bypass rights.
Permission is required to enable these images, not to ship the neutral UI.
No license claim is made for any unresolved third-party source.

## Findings

| Source class | Count | Evidence | Release conclusion |
|---|---:|---|---|
| Existing project URLs, third-party API-SPORTS CDN | 60 | Unchanged J1/J2/J3 master files; some are already displayed by Team Search | Existing usage is code evidence, not a rights grant. API-SPORTS describes identification use but leaves third-party rights to the customer |
| New external references, ESPN third-party team listing/CDN | 29 | Actual listing URLs, club reference pages and observation dates in internationalClubPresentation.json | No ESPN external-app license is evidenced. Public availability/HTTP 200 is insufficient. Blocked from public rendering; neutral fallback is the approved release behavior |
| Provider-returned GOAL URLs (evidence only, not used by the renderer) | 3 | Authorized Tokyo/Tochigi/Sabah detail projections in goalPresentationEvidence.json | Not new runtime image sources; Sabah badge returned 403 in prior investigation |
| Official club image sources | 0 | Club history/venue pages were identity corroboration, not logo licenses | No claim of official image permission |
| Rehosted/copied image assets | 0 | Catalog contains remote URL strings only | No rehosting permission assumed |

[API-SPORTS terms](https://api-sports.io/terms) explain that visual assets identify
clubs and other entities, while relevant rights remain with their owners and
additional permission may be needed. The repository demonstrates remote provider
logo rendering as an existing implementation practice. It does **not** contain
an approved policy or contract granting unrestricted public logo use.

[Disney terms, which explicitly include ESPN](https://disneytermsofuse.com/english/), do not
supply the external application redistribution/business-use permission needed
to declare this new source cleared. The applicable agreement/territory and any
separate license must be established by the operator; this is not a legal
opinion that every descriptive logo use is prohibited.

**Before enabling any club logo:** provide the applicable permission/contract or
an approved, evidenced replacement image source. No paid provider adoption is
implied. Do not silently ship these references as licensed assets, and do not
discard the requested presentation implementation to hide the issue. Local
functional verification and the rights/public-release gate are separate.
The user's acknowledgment did not supply license evidence. No outreach to
providers or clubs was performed.

## Exact URL inventory

Each row is metadata provenance, not a license assertion. All 60 Japanese URLs
already existed in the referenced project masters. All 29 ESPN URLs are new
external references in this uncommitted bundle.

| Participant | Class | Exact logo URL | Evidence |
|---|---|---|---|
| AC Nagano Parceiro | existing project / third-party API | https://media.api-sports.io/football/teams/4323.png | functions/scripts/data/j3Teams.js |
| AFC Bournemouth | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/349.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Albirex Niigata | existing project / third-party API | https://media.api-sports.io/football/teams/311.png | functions/scripts/data/j2Teams.js |
| Arsenal | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/359.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Aston Villa | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/362.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Avispa Fukuoka | existing project / third-party API | https://media.api-sports.io/football/teams/316.png | functions/scripts/data/j1Teams.js |
| Bayern Munich | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/132.png | https://site.api.espn.com/apis/site/v2/sports/soccer/ger.1/teams?limit=100 |
| Blaublitz Akita | existing project / third-party API | https://media.api-sports.io/football/teams/4315.png | functions/scripts/data/j2Teams.js |
| Borussia Dortmund | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/124.png | https://site.api.espn.com/apis/site/v2/sports/soccer/ger.1/teams?limit=100 |
| Brentford | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/337.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Brighton & Hove Albion | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/331.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Cerezo Osaka | existing project / third-party API | https://media.api-sports.io/football/teams/291.png | functions/scripts/data/j1Teams.js |
| Chelsea | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/363.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Coventry City | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/388.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Crystal Palace | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/384.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Ehime FC | existing project / third-party API | https://media.api-sports.io/football/teams/318.png | functions/scripts/data/j2Teams.js |
| Everton | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/368.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| FC Gifu | existing project / third-party API | https://media.api-sports.io/football/teams/297.png | functions/scripts/data/j3Teams.js |
| FC Imabari | existing project / third-party API | https://media.api-sports.io/football/teams/10075.png | functions/scripts/data/j3Teams.js |
| FC Machida Zelvia | existing project / third-party API | https://media.api-sports.io/football/teams/303.png | functions/scripts/data/j1Teams.js |
| FC Osaka | existing project / third-party API | https://media.api-sports.io/football/teams/7138.png | functions/scripts/data/j3Teams.js |
| FC Ryukyu | existing project / third-party API | https://media.api-sports.io/football/teams/2235.png | functions/scripts/data/j3Teams.js |
| FC Tokyo | existing project / third-party API | https://media.api-sports.io/football/teams/292.png | functions/scripts/data/j1Teams.js |
| Fagiano Okayama | existing project / third-party API | https://media.api-sports.io/football/teams/310.png | functions/scripts/data/j1Teams.js |
| Fleetwood Town | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/3891.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.4/teams?limit=100 |
| Fujieda MYFC | existing project / third-party API | https://media.api-sports.io/football/teams/4317.png | functions/scripts/data/j2Teams.js |
| Fukushima United | existing project / third-party API | https://media.api-sports.io/football/teams/4318.png | functions/scripts/data/j3Teams.js |
| Fulham | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/370.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Gainare Tottori | existing project / third-party API | https://media.api-sports.io/football/teams/4319.png | functions/scripts/data/j3Teams.js |
| Gamba Osaka | existing project / third-party API | https://media.api-sports.io/football/teams/293.png | functions/scripts/data/j1Teams.js |
| Giravanz Kitakyushu | existing project / third-party API | https://media.api-sports.io/football/teams/805.png | functions/scripts/data/j3Teams.js |
| Hokkaido Consadole Sapporo | existing project / third-party API | https://media.api-sports.io/football/teams/279.png | functions/scripts/data/j2Teams.js |
| Hull City | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/306.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Ipswich Town | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/373.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Iwaki FC | existing project / third-party API | https://media.api-sports.io/football/teams/7127.png | functions/scripts/data/j2Teams.js |
| JEF United Chiba | existing project / third-party API | https://media.api-sports.io/football/teams/301.png | functions/scripts/data/j1Teams.js |
| Jubilo Iwata | existing project / third-party API | https://media.api-sports.io/football/teams/280.png | functions/scripts/data/j2Teams.js |
| Kagoshima United | existing project / third-party API | https://media.api-sports.io/football/teams/2236.png | functions/scripts/data/j2Teams.js |
| Kamatamare Sanuki | existing project / third-party API | https://media.api-sports.io/football/teams/317.png | functions/scripts/data/j3Teams.js |
| Kashima | existing project / third-party API | https://media.api-sports.io/football/teams/290.png | functions/scripts/data/j1Teams.js |
| Kashiwa Reysol | existing project / third-party API | https://media.api-sports.io/football/teams/281.png | functions/scripts/data/j1Teams.js |
| Kataller Toyama | existing project / third-party API | https://media.api-sports.io/football/teams/4322.png | functions/scripts/data/j3Teams.js |
| Kawasaki Frontale | existing project / third-party API | https://media.api-sports.io/football/teams/294.png | functions/scripts/data/j1Teams.js |
| Kochi United | existing project / third-party API | https://media.api-sports.io/football/teams/7129.png | functions/scripts/data/j3Teams.js |
| Kyoto Sanga F.C. | existing project / third-party API | https://media.api-sports.io/football/teams/302.png | functions/scripts/data/j1Teams.js |
| Leeds United | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/357.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Lille | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/166.png | https://site.api.espn.com/apis/site/v2/sports/soccer/fra.1/teams?limit=100 |
| Liverpool | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/364.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Manchester City | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/382.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Manchester United | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/360.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Matsumoto Yamaga | existing project / third-party API | https://media.api-sports.io/football/teams/304.png | functions/scripts/data/j3Teams.js |
| Mito Hollyhock | existing project / third-party API | https://media.api-sports.io/football/teams/305.png | functions/scripts/data/j1Teams.js |
| Montedio Yamagata | existing project / third-party API | https://media.api-sports.io/football/teams/312.png | functions/scripts/data/j2Teams.js |
| Nagoya Grampus | existing project / third-party API | https://media.api-sports.io/football/teams/288.png | functions/scripts/data/j1Teams.js |
| Napoli | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/114.png | https://site.api.espn.com/apis/site/v2/sports/soccer/ita.1/teams?limit=100 |
| Nara Club | existing project / third-party API | https://media.api-sports.io/football/teams/7135.png | functions/scripts/data/j3Teams.js |
| Newcastle United | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/361.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Nottingham Forest | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/393.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Oita Trinita | existing project / third-party API | https://media.api-sports.io/football/teams/298.png | functions/scripts/data/j2Teams.js |
| RB Omiya Ardija | existing project / third-party API | https://media.api-sports.io/football/teams/313.png | functions/scripts/data/j2Teams.js |
| Real Betis | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/244.png | https://site.api.espn.com/apis/site/v2/sports/soccer/esp.1/teams?limit=100 |
| Real Madrid | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/86.png | https://site.api.espn.com/apis/site/v2/sports/soccer/esp.1/teams?limit=100 |
| Reilac Shiga FC | existing project / third-party API | https://media.api-sports.io/football/teams/7117.png | functions/scripts/data/j3Teams.js |
| Renofa Yamaguchi | existing project / third-party API | https://media.api-sports.io/football/teams/309.png | functions/scripts/data/j2Teams.js |
| Roasso Kumamoto | existing project / third-party API | https://media.api-sports.io/football/teams/314.png | functions/scripts/data/j2Teams.js |
| SC Sagamihara | existing project / third-party API | https://media.api-sports.io/football/teams/4324.png | functions/scripts/data/j3Teams.js |
| Sabah | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/21922.png | https://site.api.espn.com/apis/site/v2/sports/soccer/uefa.champions/teams?limit=100 |
| Sagan Tosu | existing project / third-party API | https://media.api-sports.io/football/teams/295.png | functions/scripts/data/j2Teams.js |
| Sanfrecce Hiroshima | existing project / third-party API | https://media.api-sports.io/football/teams/282.png | functions/scripts/data/j1Teams.js |
| Shimizu S-Pulse | existing project / third-party API | https://media.api-sports.io/football/teams/283.png | functions/scripts/data/j1Teams.js |
| Shonan Bellmare | existing project / third-party API | https://media.api-sports.io/football/teams/284.png | functions/scripts/data/j2Teams.js |
| Slavia Prague | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/494.png | https://site.api.espn.com/apis/site/v2/sports/soccer/uefa.champions/teams?limit=100 |
| Sunderland | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/366.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Tegevajaro Miyazaki | existing project / third-party API | https://media.api-sports.io/football/teams/10409.png | functions/scripts/data/j3Teams.js |
| Thespa Gunma | existing project / third-party API | https://media.api-sports.io/football/teams/756.png | functions/scripts/data/j2Teams.js |
| Tochigi City | existing project / third-party API | https://media.api-sports.io/football/teams/7145.png | functions/scripts/data/j2Teams.js |
| Tochigi SC | existing project / third-party API | https://media.api-sports.io/football/teams/315.png | functions/scripts/data/j2Teams.js |
| Tokushima Vortis | existing project / third-party API | https://media.api-sports.io/football/teams/299.png | functions/scripts/data/j2Teams.js |
| Tokyo Verdy | existing project / third-party API | https://media.api-sports.io/football/teams/306.png | functions/scripts/data/j1Teams.js |
| Tottenham Hotspur | new external / third-party API | https://a.espncdn.com/i/teamlogos/soccer/500/367.png | https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/teams?limit=100 |
| Urawa Reds | existing project / third-party API | https://media.api-sports.io/football/teams/287.png | functions/scripts/data/j1Teams.js |
| V-Varen Nagasaki | existing project / third-party API | https://media.api-sports.io/football/teams/285.png | functions/scripts/data/j1Teams.js |
| Vanraure Hachinohe | existing project / third-party API | https://media.api-sports.io/football/teams/4326.png | functions/scripts/data/j3Teams.js |
| Vegalta Sendai | existing project / third-party API | https://media.api-sports.io/football/teams/286.png | functions/scripts/data/j2Teams.js |
| Ventforet Kofu | existing project / third-party API | https://media.api-sports.io/football/teams/308.png | functions/scripts/data/j2Teams.js |
| Vissel Kobe | existing project / third-party API | https://media.api-sports.io/football/teams/289.png | functions/scripts/data/j1Teams.js |
| Yokohama FC | existing project / third-party API | https://media.api-sports.io/football/teams/307.png | functions/scripts/data/j2Teams.js |
| Yokohama F･Marinos | existing project / third-party API | https://media.api-sports.io/football/teams/296.png | functions/scripts/data/j1Teams.js |
| Zweigen Kanazawa | existing project / third-party API | https://media.api-sports.io/football/teams/300.png | functions/scripts/data/j3Teams.js |
