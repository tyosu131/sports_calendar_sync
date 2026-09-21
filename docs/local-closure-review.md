# Local closure review — 2026-09-21

## Post-audit blocking-finding fix

The generated catalog is now the only alias resolver. Removed both legacy
Japanese evidence modules and their tracked JS/sourcemap outputs; their explicit
aliases were already present in the generated catalog. Final raw precedence is
provider → English → Japanese, trimming only surrounding whitespace. The new
26-case shared fixture covers final-policy and local/server ICS/Google output.
The normal full gates were rerun: Functions 141, config 10, Flutter 112, analyze
clean, public-site build and generator check pass. Offline coverage output is
byte-identical to the existing 89-game report (178 expected names and candidate
URLs; 0 public real logos, 178 neutral fallbacks). In-memory TypeScript emission
matches all 61 current generated outputs, with zero diagnostics.

Separate post-gate direct probes of actual Dart and compiled TypeScript agree:
`FC Tokyo（女子）`, `Kashima Antlers（ユース）`, `FC Tokyo未確認` remain verbatim;
English `FC Tokyo` + provider `JEF United` returns raw `JEF United`.
No synthetic negative alias was added. Independent Pre-PR review is still
required; this is not a PRE_PR_READY declaration or deployed/device evidence.

Files changed by this fix, relative to its starting uncommitted tree:

- `functions/src/domain/teamDisplayNamePolicy.ts`
- `lib/domain/policies/team_display_name_policy.dart`
- `functions/lib/domain/teamDisplayNamePolicy.js` and `.js.map` (built)
- `functions/src/domain/japaneseClubDisplayEvidence.ts` (deleted)
- `functions/lib/domain/japaneseClubDisplayEvidence.js` and `.js.map` (retired outputs)
- `lib/domain/policies/japanese_club_display_evidence.dart` (deleted)
- `functions/test/presentation-name-regressions.test.js` (new)
- `test/presentation_name_regressions_test.dart` (new)
- `test/fixtures/presentation_name_regressions.json` (new)
- `docs/current-state.md`, `docs/oauth-presentation-closure.md`, this document

OAuth, public-site config, canonical mapping, follow/membership/sync/calendar
inclusion and logo rights code were unchanged by this fix. The three unrelated
macOS files retain their recorded pre-task hashes. No staging, commit, push,
Firestore write, live sports request, Console mutation or deployment occurred.
The older inventory/status below records the preceding public-information pass;
the deletions and additions listed here supersede it for the current revision.

## Verdict and authority

Local implementation and deterministic standard gates pass. The **whole public
closure remains pending** domain DNS/TLS and ownership verification, human
Google Console verification/release and deployed iPhone acceptance. Public
operator/contact/domain values are now confirmed. Unlicensed logos are disabled
in favor of the approved neutral UI, so their permission is not a release blocker.
This is one scope, with no split PR or silent deferral. No commit, push, PR,
deploy, Firestore write, non-dry seed, secret output or Cloud mutation occurred.

Branch: `codex/oauth-and-team-presentation-closure`.
HEAD and freshly fetched origin/main: `e27d4490939654026316c8cd98fc1e2e6a407ceb`.
Existing uncommitted implementation was preserved and audited. This pass added
full frozen-data parity/coverage, policy links, alias-context refinement and
explicit provenance/domain release evidence.

## Root causes and resolution

- JEF: previous reviewed aliases missed exact `JEF United`. The user's explicit
  presentation requirement supplies the reviewed alias; no GOAL canonical ID is added.
- Tokyo: previous alias was `FC Tokyo`; the authorized GOAL details plus club
  history/venue evidence establish the contextual `Tokyo` display alias.
- Domestic cups: old Home fallback stopped at J1; J2/J3 master names existed but
  those participants had no eligible logo lookup. Schedule/Detail lacked Home's enrichment.
- Overseas: GOAL Game docs omit logos, opponents lack canonical mappings, and
  Arsenal's project master omits its logo. New reviewed external URL metadata
  resolves display technically; source permission is still required for release.

Japanese domestic families use confirmed Japanese names. Overseas families use
English. Priority: Game logo, existing canonical master logo, unique exact
presentation master/catalog metadata, fallback. Alias matching is exact after
limited normalization, never fuzzy; conflicting matches do not guess a logo.
Formal club names are not limited to J1; ambiguous short aliases require context.
Home/Schedule/Detail share bounded screen-level enrichment; Search/Followed use
the same naming/catalog policy. No per-card Firestore reads.

## Coverage and identity evidence

[All 57 competition/participant rows](v1-presentation-coverage.md): 89 games,
178 slots, 52 labels, 178 expected names and candidate logo URLs resolved.
Public rendering uses 178 neutral badges/monograms and zero uncleared logo assets. No blanket image-delivery or licensed-use claim.

- Flutter tests run actual Game/Team policies and local ICS generation against
  the frozen public snapshot. Functions tests run actual Game normalization,
  ICS serialization and Google event generation against the same expectations.
- Both test suites assert canonical IDs remain equal to captured inputs;
  absent opponent IDs stay absent. Google event IDs remain stable.
- GOAL identity map, adapter, V1 bindings, lifecycle/sync pipelines, Game model,
  follow providers, game repository, personalized-calendar selection and Google
  reconciliation have **no diff against HEAD**. Production inclusion queries
  still use canonical `homeTeamId` / `awayTeamId`.
- No Game/Team/membership document was changed. Two V1 sync targets and six
  active families remain unchanged; FA Cup and excluded competitions stay inactive.

## OAuth and release boundary

Valid state plus `access_denied` without code returns 200 cancellation with
manual/automatic app return. Invalid/expired/reused state, malformed or conflicting
parameters and token failure remain failures. Cancellation consumes only state;
no credential, connection, calendar or sync mutation. Reconnect copy preserves
existing-state meaning. All required HTTP/HTML/state/provider-mutation cases pass.

Homepage/privacy/terms, Hosting guard and Settings links are prepared. Google-owned
safe-return behavior is not intercepted. [Publishing worksheet](google-oauth-publishing.md)
separates Branding, Audience, Clients, Data Access, domains and Verification.
Confirmed public values: Taisei Kawakami; support@sports-calendar-sync.com;
https://sports-calendar-sync.com/; /privacy; /terms. The owner confirmed email
forwarding works. Site configuration is not evidence of completed DNS/TLS,
Search Console ownership verification, publication or Google approval.
[Every logo source](logo-provenance.md) is classified: 60 existing project URLs,
29 new ESPN references, and three unused GOAL evidence URLs. No image rehosting.

## Exact final local verification

| Command | Result |
|---|---|
| `PATH="/opt/homebrew/opt/node@20/bin:$PATH" npm --prefix functions run build` | PASS |
| `PATH="/opt/homebrew/opt/node@20/bin:$PATH" npm --prefix functions test` | PASS — 141 tests (post-audit fix) |
| `PATH="/opt/homebrew/opt/node@20/bin:$PATH" npm --prefix functions run validate:config` | PASS — 10 tests |
| `flutter analyze --no-pub` | PASS — no issues |
| `flutter test --no-pub` | PASS — 112 tests (post-audit fix) |
| `PATH="/opt/homebrew/opt/node@20/bin:$PATH" node functions/scripts/generateTeamPresentation.js --check` | PASS |
| `PATH="/opt/homebrew/opt/node@20/bin:$PATH" node functions/scripts/auditV1Presentation.js` | PASS — offline report unchanged |
| `PATH="/opt/homebrew/opt/node@20/bin:$PATH" node functions/scripts/buildPublicSite.js` | PASS — confirmed values rendered; no unresolved public placeholders |
| `git diff --check` | PASS |

Compiled Functions output is retained, including JSON. Semantic JSON equality
was checked (tsc changes indentation). No hosted CI or new-revision device run
is claimed. Required runtimes: Node20.20.2/npm10.8.2, Flutter3.41.4/Dart3.11.1.

## File inventory

Includes all existing and added changes in this delivery, with generated output;
excludes the three unrelated macOS files. No files have been staged.

- `.gitignore`
- `docs/current-state.md`
- `docs/google-calendar-connection.md`
- `docs/google-oauth-publishing.md` (new)
- `docs/local-closure-review.md` (new)
- `docs/logo-provenance.md` (new)
- `docs/oauth-presentation-closure.md` (new)
- `docs/v1-presentation-coverage.md` (new)
- `firebase.json`
- `functions/lib/domain/clubPresentation.js` (new)
- `functions/lib/domain/clubPresentation.js.map` (new)
- `functions/lib/domain/teamDisplayNamePolicy.js`
- `functions/lib/domain/teamDisplayNamePolicy.js.map`
- `functions/lib/domain/teamPresentationCatalog.json` (new)
- `functions/lib/functions/googleCalendarConnection.js`
- `functions/lib/functions/googleCalendarConnection.js.map`
- `functions/scripts/auditV1Presentation.js` (new)
- `functions/scripts/buildPublicSite.js` (new)
- `functions/scripts/data/goalPresentationEvidence.json` (new)
- `functions/scripts/data/internationalClubPresentation.json` (new)
- `functions/scripts/generateTeamPresentation.js` (new)
- `functions/src/domain/clubPresentation.ts` (new)
- `functions/src/domain/teamDisplayNamePolicy.ts`
- `functions/src/domain/teamPresentationCatalog.json` (new)
- `functions/src/functions/googleCalendarConnection.ts`
- `functions/test/google-calendar-connection.test.js`
- `functions/test/presentation-catalog.test.js` (new)
- `functions/test/public-site.test.js` (new)
- `functions/test/v1-presentation-coverage.test.js` (new)
- `hosting/site.json` (new)
- `hosting/templates/index.html` (new)
- `hosting/templates/privacy.html` (new)
- `hosting/templates/style.css` (new)
- `hosting/templates/terms.html` (new)
- `lib/data/providers/game_providers.dart`
- `lib/data/repositories/team_repository.dart`
- `lib/domain/policies/club_presentation_data.dart` (new)
- `lib/domain/policies/team_display_name_policy.dart`
- `lib/domain/policies/team_presentation_policy.dart` (new)
- `lib/presentation/screens/home_screen.dart`
- `lib/presentation/screens/schedule_screen.dart`
- `lib/presentation/screens/settings_screen.dart`
- `lib/presentation/screens/team_detail_screen.dart`
- `lib/presentation/widgets/game_card.dart`
- `lib/presentation/widgets/game_presentation_scope.dart` (new)
- `lib/presentation/widgets/public_policy_links.dart` (new)
- `lib/presentation/widgets/team_list_tile.dart`
- `test/fixtures/v1_presentation_snapshot.json` (new)
- `test/game_logo_resolution_test.dart`
- `test/public_policy_links_test.dart` (new)
- `test/team_presentation_policy_test.dart` (new)
- `test/v1_presentation_coverage_test.dart` (new)

## Unrelated files unchanged

- `M macos/Flutter/Flutter-Debug.xcconfig`: SHA-256 `802714a37a8fd3065fb3d8e21cbcfbb3147c7ad25f25934b64590085aa9f5b28`
- `M macos/Flutter/Flutter-Release.xcconfig`: SHA-256 `d575f436f8bab30d7096792396e73b65db242edc01913c4123d2c29e713b3a6d`
- `?? macos/Podfile`: SHA-256 `e85521f1c80ceaca2c2af8578c97857fc84f4c467514025c0b89bb55c0e8543a`

No restore/stash/discard was performed. Requested nj workflow originals remain
unavailable; their application is not asserted. The owner-confirmed public identity and domain are reflected in the current
config. Remaining DNS/TLS, verification and release actions are documented.


## Confirmed public-information application pass

Same branch/HEAD, no staging/commit/push/deploy. Human-approved values now render
through all three static pages and Settings. Support forwarding was confirmed
by the owner; the forwarding destination is not included in public HTML.
Hosting serves /privacy and /terms through cleanUrls; generated files retain
.html internally. Public configuration and generated HTML have no unresolved
operator/support/domain values. Template substitution syntax and negative-test
fixtures intentionally remain in their source files, not in public output.

Public-site build: PASS (three HTML pages plus stylesheet in ignored hosting/dist).
Functions build PASS, Functions tests 114/114, config tests 10/10, Flutter analyze
PASS, Flutter tests 85/85, catalog --check PASS, git diff --check PASS.

No runtime OAuth/canonical/follow/calendar inclusion changes in this pass.
The public logo boundary now enforces the confirmed rights-only policy across
Game and Team surfaces: metadata remains available; no unapproved remote image
is requested. All 178 captured slots use neutral fallback until reviewed rights
are supplied. That is an approved release behavior, not an unresolved logo blocker.

Exact files changed in this pass (relative to the starting uncommitted tree):

- `docs/current-state.md`
- `docs/google-calendar-connection.md`
- `docs/google-oauth-publishing.md`
- `docs/local-closure-review.md`
- `docs/logo-provenance.md`
- `docs/oauth-presentation-closure.md`
- `docs/v1-presentation-coverage.md`
- `firebase.json`
- `functions/scripts/auditV1Presentation.js`
- `functions/test/public-site.test.js`
- `hosting/site.json`
- `hosting/templates/index.html`
- `hosting/templates/privacy.html`
- `hosting/templates/terms.html`
- `lib/domain/policies/team_presentation_policy.dart`
- `lib/presentation/widgets/game_card.dart`
- `lib/presentation/widgets/game_presentation_scope.dart`
- `lib/presentation/widgets/public_policy_links.dart`
- `test/game_logo_resolution_test.dart`
- `test/public_policy_links_test.dart`
- `test/team_presentation_policy_test.dart`
- `test/v1_presentation_coverage_test.dart`

Ignored generated output: hosting/dist/index.html, privacy.html, terms.html, style.css.

Final git status (includes unchanged, unrelated macOS work):

```text
 M .gitignore
 M docs/current-state.md
 M docs/google-calendar-connection.md
 M firebase.json
 M functions/lib/domain/teamDisplayNamePolicy.js
 M functions/lib/domain/teamDisplayNamePolicy.js.map
 M functions/lib/functions/googleCalendarConnection.js
 M functions/lib/functions/googleCalendarConnection.js.map
 M functions/src/domain/teamDisplayNamePolicy.ts
 M functions/src/functions/googleCalendarConnection.ts
 M functions/test/google-calendar-connection.test.js
 M lib/data/providers/game_providers.dart
 M lib/data/repositories/team_repository.dart
 M lib/domain/policies/team_display_name_policy.dart
 M lib/presentation/screens/home_screen.dart
 M lib/presentation/screens/schedule_screen.dart
 M lib/presentation/screens/settings_screen.dart
 M lib/presentation/screens/team_detail_screen.dart
 M lib/presentation/widgets/game_card.dart
 M lib/presentation/widgets/team_list_tile.dart
 M macos/Flutter/Flutter-Debug.xcconfig
 M macos/Flutter/Flutter-Release.xcconfig
 M test/game_logo_resolution_test.dart
?? docs/google-oauth-publishing.md
?? docs/local-closure-review.md
?? docs/logo-provenance.md
?? docs/oauth-presentation-closure.md
?? docs/v1-presentation-coverage.md
?? functions/lib/domain/clubPresentation.js
?? functions/lib/domain/clubPresentation.js.map
?? functions/lib/domain/teamPresentationCatalog.json
?? functions/scripts/auditV1Presentation.js
?? functions/scripts/buildPublicSite.js
?? functions/scripts/data/goalPresentationEvidence.json
?? functions/scripts/data/internationalClubPresentation.json
?? functions/scripts/generateTeamPresentation.js
?? functions/src/domain/clubPresentation.ts
?? functions/src/domain/teamPresentationCatalog.json
?? functions/test/presentation-catalog.test.js
?? functions/test/public-site.test.js
?? functions/test/v1-presentation-coverage.test.js
?? hosting/site.json
?? hosting/templates/index.html
?? hosting/templates/privacy.html
?? hosting/templates/style.css
?? hosting/templates/terms.html
?? lib/domain/policies/club_presentation_data.dart
?? lib/domain/policies/team_presentation_policy.dart
?? lib/presentation/widgets/game_presentation_scope.dart
?? lib/presentation/widgets/public_policy_links.dart
?? macos/Podfile
?? test/fixtures/v1_presentation_snapshot.json
?? test/public_policy_links_test.dart
?? test/team_presentation_policy_test.dart
?? test/v1_presentation_coverage_test.dart
```
