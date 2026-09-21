# Google OAuth publishing and verification — release worksheet

This is part of the same OAuth/presentation delivery bundle, not a later PR.
Code completion, Hosting publication, Audience publication, brand verification,
and (where required) sensitive-scope verification are different milestones.
Passing repository CI cannot establish any Console milestone.

## Confirmed public identity (Human-approved, 2026-09-21)

| Field | Confirmed value |
|---|---|
| Brand | Sports Calendar |
| Operator | Taisei Kawakami |
| Domain / Authorized domain to configure | sports-calendar-sync.com |
| Support email | support@sports-calendar-sync.com |
| Homepage | https://sports-calendar-sync.com/ |
| Privacy Policy | https://sports-calendar-sync.com/privacy |
| Terms | https://sports-calendar-sync.com/terms |

The owner confirmed support-email forwarding works. No email was sent by this
change; the private forwarding destination is not published in the website.
Operator/contact/domain selection is **complete** and is no longer a blocker.
No additional domain purchase is proposed.

The existing Firebase Hosting site ID remains `sports-calendar-sync-a4564`.
The public origin is now the confirmed custom domain, not the default project
subdomain. `cleanUrls: true` serves the static privacy.html/terms.html artifacts
at `/privacy` and `/terms`; `trailingSlash: false` keeps those canonical paths.
No OAuth rewrite is added. Attaching the custom domain, DNS/TLS validation,
Search Console ownership verification and Hosting publication remain human
release actions, not results established by this local configuration.

Google requires ownership verification for the relevant top private domains:
[brand verification](https://developers.google.com/identity/verification/authentication-verification).
The approved domain supplies the intended ownership boundary; it does not prove
that Search Console or Google OAuth verification has already completed.
[Firebase custom-domain setup](https://firebase.google.com/docs/hosting/custom-domain)
provides the remaining DNS/TLS steps. Do not overwrite working mail-forwarding
MX/TXT records when configuring Hosting DNS.

The current callback stays:
`https://asia-northeast1-sports-calendar-sync-a4564.cloudfunctions.net/googleCalendarOAuthCallback`.
Read-only `gcloud functions describe` confirmed this URI ACTIVE on Node 20,
updated `2026-09-21T02:21:52.489Z`; no secret values were read.
It is an HTTPS server callback independent of Firebase sign-in and has no need
to become the user's primary calendar. Moving it just for appearance is not
required by the code. A Hosting rewrite is an option **if** Console domain
validation requires it; change the web client's exact redirect URI and
`GOOGLE_CALENDAR_OAUTH_REDIRECT_URI` together, redeploy bound Functions, and retest
success/cancel/state failures. Do not change only one side.

The Google-owned warning appears before our callback. Its safe-return link is
Google-controlled. Google states that unverified brand details may display the
application domain instead of the app name. Thus the prominent
`cloudfunctions.net` display is consistent with incomplete brand verification;
the exact Console cause cannot be proven from source or that screenshot alone.
See [Manage OAuth App Branding](https://support.google.com/cloud/answer/15549049?hl=en).

## Ready-to-review public artifacts

- `hosting/templates/index.html`: product purpose, supported target clubs,
  optional Google/ICS connection, narrow access and policy links.
- `privacy.html`: actual profile/follow/Calendar data, credential protection,
  Google API Limited Use statement, rights-cleared logos / neutral fallback, retention,
  disconnect/revoke and contact-based deletion requests. No nonexistent
  in-app account-deletion capability is claimed.
- `terms.html`: service scope, external data limitations, disconnect, rights and
  contact. The operator must approve these public commitments before release.
- `style.css`: accessible static layout, no third-party scripts or analytics.
- `hosting/site.json`: public operator/contact/origin only; **no secrets**.
  Operator, support email and public origin contain the confirmed values above.
- `functions/scripts/buildPublicSite.js`: escapes the supplied public values,
  rejects missing identity/contact and writes only ignored `hosting/dist/`.
  Firebase Hosting's predeploy hook invokes the same guard.
- Settings includes homepage/privacy/terms links even when signed out. The
  app origin is `https://sports-calendar-sync.com`; links use `/privacy` and
  `/terms`. A parity test guards the app/config values and exact URLs. The
  released app and OAuth Branding must point to these same public pages.

Public values are configured. Build locally before any separately approved release:

```sh
PATH="/opt/homebrew/opt/node@20/bin:$PATH" node functions/scripts/buildPublicSite.js
# Inspect hosting/dist before the final publication action.
PATH="/opt/homebrew/opt/node@20/bin:$PATH" firebase deploy --only hosting --project sports-calendar-sync-a4564
```

The deploy command is a release action, **not executed by this change**. It
publishes only static Hosting content, not Functions/Firestore rules. Before
submitting to Google, check HTTP 200 with no login at all three public URLs and
verify the visible operator, product and support address. Until publication,
these are configured destinations, not claims of publicly available pages.

## Human Console checklist

| Item | State | Evidence / exact next action | Owner |
|---|---|---|---|
| App name | REPO-EVIDENCED; Console UNKNOWN | Use `Sports Calendar` consistently; confirm Console name | Human / Google Cloud Console |
| App logo | UNKNOWN / optional | Only submit an owned app logo; club logos are not app branding | Human / Google Cloud Console |
| Support / developer contacts | REPO-EVIDENCED; HUMAN-CONSOLE-CHECK | Taisei Kawakami / support@sports-calendar-sync.com; forwarding confirmed by owner; apply Console contacts | Human / Google Cloud Console |
| Homepage | REPO-EVIDENCED, not published | Build/review/publish `/` on the confirmed site | Human / public web property |
| Privacy Policy | REPO-EVIDENCED, operator review pending | Approve commitments; publish `/privacy`; use same link on consent and homepage | Human / public web property |
| Terms | REPO-EVIDENCED, operator review pending | Approve and publish `/terms`; include in external production Branding | Human / public web property |
| Authorized domains | HUMAN-CONSOLE-CHECK | Verify sports-calendar-sync.com using a project Owner/Editor in Search Console; validate the unchanged callback domain too | Human / Google Cloud Console |
| Audience / Publishing status | UNKNOWN | Prior docs said External/Testing, but this investigation did not observe current Console. Confirm intended External production audience; final Publish is human-owned | Human / Google Cloud Console |
| Test users | HUMAN-CONSOLE-CHECK | Review test-only allowlist after production transition; do not remove testers before a validated release | Human / Google Cloud Console |
| Calendar API enabled | REPO-EVIDENCED (read-only Cloud) | `gcloud services list --enabled` returned `calendar-json.googleapis.com` on 2026-09-21; no enable action needed | Human / Google Cloud Console |
| Data Access | REPO-EVIDENCED; Console UNKNOWN | Calendar code requests only `https://www.googleapis.com/auth/calendar.app.created`; compare exact Console scopes/category and remove obsolete broader requests | Human / Google Cloud Console |
| Web OAuth client | HUMAN-CONSOLE-CHECK | Confirm the client corresponding to the existing secret; do not paste client secrets into evidence | Human / Google Cloud Console |
| Redirect URI | REPO-EVIDENCED; runtime secret not read | Exact HTTPS callback above; confirm client and configured secret agree; keep Firebase identity client concerns separate | Human / Google Cloud Console |
| Brand verification | HUMAN-CONSOLE-CHECK | Submit approved name/contacts/public URLs/domain proof from Branding; record actual review outcome | Human / Google Cloud Console |
| Data-access verification | HUMAN-CONSOLE-CHECK | Use Console's actual scope category/requirements. If required, submit scope justification and demonstration below | Human / Google Cloud Console |
| Runtime implementation/tests | REPO-EVIDENCED | Existing CI plus catalog/site/callback tests; no CI live API requests | Repo |

The official Calendar scope list describes access but is not evidence of the
current project's configured scope classification. Do not declare this scope
non-sensitive/sensitive without checking Google's current classification in
Console. [Calendar authorization guide](https://developers.google.com/workspace/calendar/api/auth).
Incremental authorization (`include_granted_scopes=true`) can include prior
grants; unchanged source scope does not prove old broader grants are absent.
Inspect existing consent grants and test a fresh authorization where necessary.

The [current Branding help](https://support.google.com/cloud/answer/15549049?hl=en)
requires homepage, privacy and terms links for external production apps. All
three are prepared here, even though another general guide calls terms optional.
The [verification requirements](https://support.google.com/cloud/answer/13464321?hl=en)
also require an accessible in-product privacy link. Current Console Branding,
Audience, Clients, Data Access and Verification Center values remain unobserved;
the worksheet is not a claim that Google has approved anything.

## Submission materials

**Product description:** Sports Calendar lets users follow supported sports
teams and keep official fixtures in an app-created secondary Google calendar.
It updates kickoff, venue, lifecycle and score information without accessing
the user's primary calendar. Google connection is optional and independent of
Google/Apple Firebase login.

**Scope justification:** `calendar.app.created` allows creation and maintenance
of the app-created Sports Calendar and its managed fixture events. Offline
refresh access is necessary for scheduled updates when the app is closed. No
broader Calendar scope is requested. Credentials are encrypted on the server;
access tokens are transient and never returned to Flutter.

**Demo recording script (human account/device required):** show homepage and
policy links → sign in → Settings disconnected → connect → exact consent scope
and app identity → accept → callback/app return → connected/synced → secondary
calendar and sample fixture update → disconnect → no further automatic sync,
calendar retained. Also record cancellation returning safely to disconnected
(or unchanged connected state during reconnect). Do not show credentials,
personal unrelated events, OAuth codes, or private subscription URLs. Provide
the reviewer's requested access instructions without committing passwords.

**Final verification:** do not instruct ordinary users to bypass the unverified
warning as a permanent solution. Confirm the warning/branding outcome with a
fresh non-test-user account only after Google/Console publication requirements
are satisfied. Publishing alone is not proof of verification.

## iPhone / release acceptance

1. Deploy the reviewed Functions revision and install the reviewed app build.
2. OAuth success/cancel on a new connection and reconnect; warm return and cold
   start both land in Settings, and Back reaches Home.
3. Confirm backend-connected/synced state rather than browser-open success.
4. Home/Search/followed/detail/Schedule show the same names and logos for
   Kawasaki, Arsenal, JEF, Vissel, Fulham, Tottenham, Real Madrid and both cups.
5. Verify public pages and the actual Google-owned consent/brand screens.
6. Check Tokyo/Tochigi/Sabah against their documented scoped presentation
   evidence; keep identity/follow mappings unchanged.

No physical-device execution, Console mutation, verification submission, or
Google approval is asserted by this worksheet.
