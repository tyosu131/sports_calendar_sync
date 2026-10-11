# V1.5 Release Closure

## Purpose

Close the current tester V1.5 without adding new product scope.

Repository implementation and stabilization are already merged through PR #55. The remaining work is to prove that the chosen release candidate is compatible with production configuration and behaves correctly on the real tester device.

This document is a closure worksheet, not proof that production is current. Do not treat repository CI as deployment evidence.

## Scope

In scope:

- latest Home / Search / League / Follow / Schedule behavior
- Japanese domestic-football display policy
- auth/profile/follow-state hardening
- Firestore decode fail-fast behavior
- Google Calendar and Apple / ICS paths already present in V1
- production rules / indexes / Functions revision confirmation needed by those paths
- one focused real-device smoke pass

Out of scope for V1.5 closure:

- compact Schedule aliases
- venue-local timezone display
- UFC or new provider coverage
- enabling unverified third-party logos
- Apple Sign-In activation
- App Store / Play Store publication
- `sportKey` migration
- new AWS architecture work

## Execution record

The stateful execution record is GitHub Issue #57, `V1.5 release closure`.

Record the release-candidate SHA, build/install date, device, production-config evidence, and smoke results in that issue. Do not commit a filled candidate SHA back into the candidate itself; that would create a new commit with a different SHA.

Baseline when this worksheet was created: main contained PR #55 merge `c7e467e`. This is historical context only; it is not an instruction to install that SHA.

## Repository gates

Before device handoff, verify the chosen candidate rather than assuming an older PASS still applies.

| Gate | Required result | Evidence |
| --- | --- | --- |
| Functions build | PASS |  |
| Functions tests | PASS |  |
| Functions validate:config | PASS |  |
| Flutter analyze | PASS |  |
| Flutter tests | PASS |  |
| Effective diff / PR review | no open Must finding |  |

PR #55 head `6f57b14` passed the standard CI before merge. If the release candidate contains later code-bearing changes, rerun the relevant gates.

## Production configuration gate

Use `docs/production-config-handoff.md`. Do not infer deployed revisions from Git history.

| Dependency | Required for this smoke | Production evidence |
| --- | --- | --- |
| Firestore rules | Search / League / Follow paths |  |
| Firestore indexes | typed Search and game queries |  |
| Functions | Google Calendar and Apple / ICS; required for PR #53 calendar-side Japanese names |  |

Minimum expectations:

- rules include public read for `competitionSeasonMemberships`
- indexes cover current team-search and game-query contracts
- if external calendar Japanese domestic names are part of acceptance, deployed Functions include PR #53 policy (`1fe5ecc` or a descendant containing it)

Any deployment or production mutation is a Human Gate and requires explicit approval.

## Real-device smoke matrix

Use production mode: no `USE_SAMPLE_DATA`.

Capture the exact error text when a path fails. Do not convert a configuration error into an empty-state observation.

| Path | Check | PASS / FAIL | Evidence / note |
| --- | --- | --- | --- |
| Launch / auth | Google sign-in session resolves normally |  |  |
| Home / お気に入り | followed teams and upcoming games render |  |  |
| Home sport tabs | 野球 / サッカー / その他スポーツ swipe/tap correctly |  |  |
| Sport sub-nav | ホーム / リーグ resets correctly when sport changes |  |  |
| Search / フォロー中 | followed list is not replaced by another sport result |  |  |
| Search / サッカー / ホーム | empty query loads scoped teams |  |  |
| Search typed query | text search succeeds without `failed-precondition` |  |  |
| Search clear | clear button restores empty-query result |  |  |
| League browser | Jリーグ opens and team grid loads |  |  |
| Follow | follow succeeds and state updates |  |  |
| Unfollow | unfollow succeeds and state updates |  |  |
| Missing/error distinction | no permission/network failure appears as a normal empty list |  |  |
| Team detail | team and next games render |  |  |
| Schedule | followed-team schedule renders |  |  |
| Japanese domestic names | domestic club names are Japanese in-app |  |  |
| Overseas names | Premier / other overseas names remain English where policy requires |  |  |
| Home/Away presentation | side frame + stadium/transit cue remains readable |  |  |
| Google Calendar | existing connection/status and sync path works |  |  |
| Google Calendar names | domestic Japanese names appear if latest Functions were deployed |  |  |
| Apple / ICS | existing feed opens/subscribes and events remain usable |  |  |
| Apple / ICS names | domestic Japanese names appear if latest Functions were deployed |  |  |

## Failure routing

### Search screen error

Record:

- exact screen
- selected top tab
- ホーム / リーグ selection
- whether search text was entered
- exact `エラー:` text

Useful distinctions:

- typed search + `failed-precondition` -> composite index candidate
- Jリーグ team list + `permission-denied` -> membership rules candidate
- decode error naming collection/document/field -> data-contract drift candidate
- initial フォロー中 failure -> do not automatically blame membership/indexes

### Follow failure

A profile read failure must not look like zero follows.

A follow/unfollow write failure should stay on the current screen and show the user-visible update failure. It must not silently navigate to sign-in unless the session is actually signed out.

### Calendar failure

Separate:

- client auth/session failure
- callable / Functions failure
- OAuth external configuration
- sync failure after connection
- presentation-name mismatch caused by stale Functions

Do not diagnose one category from another category's symptom.

## Stop condition

V1.5 is closed when all of the following are true:

1. a concrete release candidate SHA is recorded in the active release-closure issue
2. required repository gates for that candidate are PASS
3. required production rules / indexes / Functions revisions are confirmed
4. the focused real-device smoke matrix has no open blocker
5. no failure is being masked as a normal empty state
6. PR #53 domestic naming is verified in-app
7. external-calendar naming is either verified with the required Functions revision or explicitly deferred from V1.5 acceptance
8. no open Must finding remains

New feature ideas discovered during smoke are separate V1.6 / V2 candidates unless they block an existing V1.5 acceptance item.

## Human Gates

Stop and ask before:

- deploying Functions
- deploying Firestore rules
- deploying Firestore indexes
- writing / seeding production Firestore
- invoking production sync that mutates data
- changing OAuth Console / redirect URI / secret configuration
- changing Apple Developer configuration
- merging a corrective PR
- changing V1.5 acceptance scope
