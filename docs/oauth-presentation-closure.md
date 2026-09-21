# OAuth and team presentation closure — one delivery bundle

## Authority and acceptance

Goal: close OAuth cancellation, public OAuth readiness, and consistent V1 team
names/logos together. This document does not defer any of those requirements to
another PR. Implementation base: freshly fetched `origin/main`
`e27d4490939654026316c8cd98fc1e2e6a407ceb` (PR #41), 2026-09-21.

Scope: application callback, all existing team presentation surfaces, public
homepage/privacy/terms, Hosting preparation, verification materials and human
Console handoff. Out of scope: changing provider identity, follows, competition
memberships, fixture inclusion, acquiring paid services, or purchasing a domain.
No production fixture write, secret change, provider adoption or automatic
release approval is implied by display metadata.

The latest user instruction is the scope authority. `AGENTS.md`,
`docs/product/product-goal.md`, `docs/decisions/v1-foundation.md`, actual PR #41
source, tests and CI are the repository authority. Requested **nj Source Map /
Core / Workflow Router** originals were not located in the available local/Drive
sources. Referencing prompt documents were found, but are not substitutes for
those originals. Applying those originals remains pending their URL/path.

## Current evidence and root causes

Read-only production Firestore inspection on 2026-09-21 selected only public
participant names, competition keys and logo fields from 89 existing V1 games.
It observed 52 distinct participant labels; Game logo fields were empty. After
separate human authorization, only Tokyo/Tochigi/Sabah GOAL team details were
queried (including bounded timeout retries). No API-SPORTS API call or Firestore
write was performed. No credential or authorization header was exposed.

Home previously enriched only J1 games through Japanese aliases and master
names. Schedule/detail used Game logos alone. Search and the followed-team strip
used Team master logos. Arsenal's committed Team master has no logo. `JEF United`
is not the previous `JEF United Chiba` alias. Domestic-cup and European opponents
therefore need the same presentation resolver, not more canonical identities.

`homeTeamId`/`awayTeamId` participate in Home/Schedule queries, personal ICS
filtering and Google event reconciliation. Extending GOAL canonical mappings to
fix logos would change those product semantics. The mapping remains unchanged.

## V1 presentation boundary

Follow/sync targets remain `kawasaki_frontale` and `arsenal`. Their currently
active competition families remain:

| Target | Active families | Default displayed language |
|---|---|---|
| Kawasaki | `football_j1`, `football_j_league_cup`, `football_emperor_cup` | Japanese |
| Arsenal | `football_premier`, `football_champions_league`, `football_league_cup` | English |

Presentation scope includes **both sides** of their games, including unmapped
opponents, and matching master entries in Search, followed teams and Team detail.
J1/J2/J3 discovery uses Japanese, including when those clubs appear in domestic
cups. FA Cup is still inactive; no excluded competition is activated by this work.

One reviewed catalog is generated from the existing J1/J2/J3 masters and
`functions/scripts/data/internationalClubPresentation.json` into server JSON and
Flutter constants. International logo URLs and names were read from the public
ESPN team listings linked in that evidence file on 2026-09-21, with the
human-authorized GOAL detail used to disambiguate Sabah. This does not
introduce an ESPN fixture/sync API, runtime metadata API, provider Team IDs or
followable opponent records. A reachable logo URL does not establish licensing
rights: existing Japanese and newly referenced international logo usage needs
rights review before public distribution.

`JEF United` is a presentation alias for the existing Chiba master, grounded in
the user's real-device report and the existing club evidence. `Arsenal FC`,
`Tottenham`, `Bayern München` and `Slavia Praha` have explicit display aliases.
No approximate/partial match or generated logo URL is used.

### Final name resolution and rejected evidence

Existing canonical IDs retain their explicit names; this does not infer an ID.
For other participants, the generated catalog is the only identity-like name
resolver. A unique match supplies Japanese for domestic competitions and English
for overseas competitions. A miss/conflict is final: there is no second alias
lookup. The retired Dart/TypeScript Japanese alias maps have been removed; all
their explicit aliases were already covered by the generated master catalog.

Unresolved inputs use the first nonblank original field in this exact order:
`provider` → `english` → `japanese` → empty string. Only surrounding whitespace
is trimmed; Japanese suffixes, parentheses, U-18 and reserve labels are retained.
GOAL's adapter stores the original participant name in `*TeamProviderName` and
also in `*TeamNameEn`; `*TeamNameJa` can contain previously derived localization.
This precedence selects source text, not a winner among conflicting clubs.
Thus English `FC Tokyo` plus provider `JEF United` displays raw `JEF United`,
not either club's confirmed Japanese name. No fabricated evidence is added.

`test/fixtures/presentation_name_regressions.json` is a shared expected-output
oracle consumed by Dart and TypeScript final-policy tests. It includes modified,
unknown, conflicting, empty and confirmed inputs. The same cases pass through
local ICS and server ICS/Google event output, separately from the 89-game live
snapshot. These tests require no network, Firebase initialization or locale data.

Logo order: Game logo → existing canonical Team logo → unique exact presentation
match in master → reviewed catalog logo → existing initials/shield. A conflicting
or ambiguous match yields no guessed logo. Catalog entries contain **no IDs**.
No Game/Team identity or membership is written. Calendar output uses the same
generated naming evidence as Flutter; existing stored games need no migration.
Only ambiguous short aliases have competition context restrictions. Confirmed
full club names such as `FC Tokyo` and `Tochigi SC` retain their catalog logo
across football competitions; the club itself is not restricted to J1.

Home, Schedule and Team detail share cached competition-master providers. A
screen fetches all its canonical IDs in one repository call (Firestore batches
of 30). At most four presentation masters are fetched per provider lifetime:
J1/J2/J3 for Japanese fixtures, Premier for international fixtures. Each master
uses the current and legacy field queries (at most eight queries total),
deduplicated in memory. Competition queries return the entire bounded master;
the old limit of 20 could truncate J2's 22 entries and hide ambiguity. No card
performs a repository read. Metadata failures preserve the games and use static
reviewed presentation/fallback. Pull-to-refresh invalidates metadata as well.

### Current coverage

A repeated read-only audit captured all 89 stored V1 games, 178 participant
sides and 52 distinct labels in `test/fixtures/v1_presentation_snapshot.json`.
It selects public fields only and captures 21 current football masters, not
users/credentials. The [57-row competition/participant matrix](v1-presentation-coverage.md)
shows exact current/expected names, URL evidence and resolution for every label.
Both Flutter and actual ICS/Google output tests consume this frozen oracle:
178/178 names and candidate logo URLs resolve; 0 unresolved participant names.
Public rendering separately enforces rights: 0 approved logo assets and 178
intentional neutral badges/monograms in this snapshot. Unknown/ambiguous participants remain tested
fallback cases. This is not 100% image-delivery or rights coverage.

The prior Arsenal/Fulham/Tottenham/Real Madrid/Sabah representative HTTP 200
checks do not replace on-device verification. The [complete logo inventory](logo-provenance.md)
classifies all 60 existing Japanese URLs and 29 new international references.
No blanket public-use license is evidenced. These assets are blocked by the
public rendering policy; neutral presentation can ship without inventing
permission. A reviewed rights record is required before enabling any such URL.

### Three previously ambiguous participants resolved by authorized evidence

| Stored label | GOAL detail | Display resolution / scope |
|---|---|---|
| Tokyo | `cmril1r9rg5yus107g34hsm6u`; Japan, founded `1935 / 199`, Ajinomoto Stadium / Chōfu | FC東京 master, Japanese competitions only |
| Tochigi | `cmrjf0tcy94r1t5075wjsxmv8`; Japan, founded 1953, Tochigi Green Stadium / Utsunomiya | 栃木SC master, Japanese competitions only |
| Sabah | `cmri0gkbgbr6mlb07s324klf3`; Azerbaijan, Bank Respublika Arena / Masazir | Provider's Sabah name and ESPN badge, `football_champions_league` only |

The FC Tokyo and Tochigi SC presentation conclusions are inferences corroborated
by the provider country/founding/stadium evidence and the clubs' official
histories: [FC Tokyo profile](https://www.fctokyo.co.jp/en/club/profile/) and
[Tochigi SC club history](https://www.tochigisc.jp/info/10994).
Sabah’s provider badge returned HTTP 403 and is not used by the app. Its
ESPN Champions League listing supplied a replacement image verified as HTTP 200
`image/png`; UEFA’s [club page](https://www.uefa.com/uefachampionsleague/clubs/2609356--sabah/)
corroborates the Azerbaijani club.

Sanitized provider fields are in
`functions/scripts/data/goalPresentationEvidence.json`. They are evidence, not
runtime canonical mappings. Runtime catalog entries contain no Team IDs.
`Tokyo`, `Tochigi` and `Sabah` outside their confirmed competition contexts do
not match the catalog. Future new participants still require reviewed metadata;
CI must not fabricate it or call live APIs.

## OAuth outcome contract

PR #41 already implements and tests the actual HTTP/domain boundary. Preserve:

| Input after validation | HTTP | Page | Automatic / manual app return |
|---|---:|---|---|
| Valid one-time state + code; bootstrap succeeds | 200 | Success | Both |
| Valid one-time state + exactly `access_denied`, no code | 200 | Cancelled | Both |
| Invalid/expired/reused state, malformed/non-scalar query, unknown/empty error, code+error | 400 | Failure | Manual only |
| Token exchange / bootstrap failure | 502 | Failure | Manual only |

State remains random, hashed, expiring, UID-bound and consumed once before denial
classification. Cancellation exchanges no token and changes no credential,
calendar, connection or sync state; state consumption is the only mutation.
Cancel copy now explicitly preserves an existing connection during reconnect.
Flutter still reads authoritative backend status after resume; URL launch is
not a success signal. Google's pre-callback warning/safe-return page is outside
this handler and cannot be intercepted by app HTML.

## Verification ownership

| Acceptance | Direct verifier |
|---|---|
| Callback success/cancel/errors + state safety | `functions/test/google-calendar-connection.test.js` HTTP recorder + in-memory store/provider |
| Shared naming evidence, no identity promotion, generated drift | `functions/test/presentation-catalog.test.js` |
| Names/logos, ambiguous/unknown inputs, master priority, no Game mutation | `test/team_presentation_policy_test.dart` |
| Bounded cached reads and metadata failures | ProviderContainer + recording TeamRepository in the same test |
| Card image source/fallback and existing surfaces | `test/game_logo_resolution_test.dart` plus full Flutter tests |
| Public pages and publishing guard | `functions/test/public-site.test.js` |
| All captured names/URLs + ICS/Google parity | `test/v1_presentation_coverage_test.dart`, `functions/test/v1-presentation-coverage.test.js` |
| Settings policy discoverability + sanitized launch failure | `test/public_policy_links_test.dart` |
| Actual Google warning removal / app return / image loading | Human Console verification + deployed iPhone smoke test |

CI performs no real Google OAuth, Firebase or sports API request. Intl is
initialized in date-rendering widget tests; network image behavior is inspected
through image URLs, not a live download. Fresh widget keys/containers avoid
State/provider reuse. Source build and generated-catalog drift checks run in
the existing standard test entrypoints.

## Completion ledger

- Repository implementation and deterministic tests: see latest verification
  results in `docs/current-state.md`.
- Public page content: operator/support/domain values are confirmed and the
  site builds without unresolved placeholders. Public commitments and deployment
  still require release review; no deployment was performed.
- Existing Hosting site: read-only confirmed; no Hosting release in this task.
- Google Console current branding/audience/scopes/domains/verification state:
  not directly observed. Console final actions remain human-owned.
- Three previously unresolved presentation labels: authorized evidence obtained;
  scoped display aliases and regression tests added.
- Real-device verification of this revision: not performed.
- Settings has public policy links, including signed-out entry. Destinations
  use https://sports-calendar-sync.com/, /privacy and /terms. Taisei Kawakami
  and support@sports-calendar-sync.com are owner-confirmed; DNS/TLS, domain
  proof and publication remain.
- Logo public-use rights: source inventory complete; permission not established.
  The public UI uses neutral badges/monograms and never requests these images.

The whole goal is **not closed** until the remaining evidence, public assets,
Google operational steps and real-device acceptance are complete. Do not use
passing code tests as a claim that Google's warning has disappeared.
