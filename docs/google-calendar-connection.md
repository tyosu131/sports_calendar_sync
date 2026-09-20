# Google Calendar connection setup

## Status and boundary

The connection code is complete, but **Google Cloud OAuth configuration is not
complete by this repository change**. No deployment or production secret
mutation is performed here. Game/event synchronization is intentionally out of
scope.

The Firebase-authenticated callable starts a separate Google OAuth flow. A
random, ten-minute, single-use state is stored only as a SHA-256 hash and bound
to the Firebase UID. The browser callback derives ownership exclusively from
that state. It exchanges the code for offline credentials, then creates or
recovers the app-created `Sports Calendar` secondary calendar.

Refresh tokens are AES-256-GCM encrypted. Only ciphertext, IV, authentication
tag, and algorithm are stored in the server-only
`googleCalendarCredentials/{uid}` collection. Connection metadata is stored in
`googleCalendarConnections/{uid}`; neither collection is client-readable.
Access tokens are used transiently and are not persisted.

The calendar carries the description marker
`sports-calendar-sync:app-created`. On reconnect, bootstrap checks a recorded
calendar ID directly with `calendars.get` using the newly authorized credential.
It reuses an accessible calendar, but creates and records a new app-created
calendar when the old ID is deleted or belongs to another Google account. This
recovery uses the narrow scope and does not require calendar-list discovery.
Disconnect deletes the encrypted credential and marks the connection inactive,
while deliberately preserving the Google calendar and its contents.

## Human-required Google Cloud configuration

1. Enable **Google Calendar API** in the deployment project.
2. Configure the OAuth consent screen and request only
   `https://www.googleapis.com/auth/calendar.app.created`.
3. Create an OAuth **Web application** client. Add the deployed HTTPS URL for
   `googleCalendarOAuthCallback` as an exact authorized redirect URI.
4. If the consent screen is in testing, add all intended Google accounts as
   test users. Complete Google's production verification/review when required;
   this remains a release concern.
5. Configure these Firebase Functions/Secret Manager secrets (values must never
   be committed):
   - `GOOGLE_CALENDAR_OAUTH_CLIENT_ID`
   - `GOOGLE_CALENDAR_OAUTH_CLIENT_SECRET`
   - `GOOGLE_CALENDAR_OAUTH_REDIRECT_URI`
   - `GOOGLE_CALENDAR_TOKEN_ENCRYPTION_KEY` — a base64-encoded 32-byte random key
6. Deploy the functions and Firestore rules through the normal release process,
   then verify consent, callback, reconnect, and disconnect with a test user.

Official references: [Calendar API authorization scopes](https://developers.google.com/workspace/calendar/api/auth),
[OAuth 2.0 web-server flow](https://developers.google.com/identity/protocols/oauth2/web-server),
and [Firebase Functions secrets](https://firebase.google.com/docs/functions/config-env#secret-manager).

## Operational notes and risks

- Revocation at Google is not attempted on disconnect; local write capability
  is removed immediately and the calendar is retained.
- A recorded calendar that returns `404` or `410` from `calendars.get` is
  replaced on reconnect. Authentication, quota, and unexpected provider errors
  fail the connection instead of silently creating or activating a calendar.
- The app-created scope must be validated against the configured OAuth project
  during release testing. The code does not silently fall back to broader
  Calendar scopes.
- State and credential collections should have retention/monitoring policies;
  expired state documents are rejected but are not proactively swept in this
  foundation phase.
- There is a small orphan-calendar risk if the process terminates after Google
  creates a calendar but before Firestore records its ID. Calendar-list recovery
  was intentionally not added because it would require permission beyond the
  mandated `calendar.app.created` bootstrap boundary. A later operational
  reconciliation design must not silently widen that scope.
