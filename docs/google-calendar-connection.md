# Google Calendar direct synchronization

## Delivery state

- **Code complete:** OAuth connection, direct event reconciliation, triggers, app return, and sanitized UI status are implemented in this repository.
- **Production deployed:** no. This change does not deploy Functions or Firestore rules and does not mutate secrets.
- **Production verified:** no. Real-device callback return and real Google event behavior must be verified after review/deployment.

The Google OAuth application remains External / Testing. Google's unverified-app warning and OAuth publishing/verification are operational work, not completed by this change. Functions intentionally remain on Node.js 20; its announced decommission must be handled separately.

## Architecture and permission boundary

The integration requests only `https://www.googleapis.com/auth/calendar.app.created`. It creates and exclusively manages the secondary **Sports Calendar**; it neither requests primary-calendar access nor broad Calendar scopes. Canonical Firestore games plus `users/{uid}.followedTeamIds` are the source of truth. The public personalized ICS feed remains available for Apple Calendar and generic/manual subscriptions.

ICS and Google adapters consume the same pure calendar presentation policy. It supplies compact competition labels, localized team names produced by canonical normalization, authoritative finished scores (including 0-0), venue, and lifecycle status. ICS maps cancelled/postponed to RFC 5545 `CANCELLED`/`TENTATIVE`. Google maps postponed to `tentative`, while a canonical cancellation remains a live `confirmed` resource with `[CANCELLED]` in its title because Google's event status `cancelled` represents deletion.

Google requires event end time while the canonical model has no authoritative end. The Google adapter alone uses an explicitly synthetic two-hour duration. It is not written to Firestore and can be changed without changing provider truth.

## Identity and reconciliation

Event IDs are `sc` plus a SHA-256 hex digest of the canonical Firestore game ID. This satisfies Google's base32hex-compatible ID alphabet, is stable across mutable fixture changes, and avoids exposing or assuming validity of raw IDs. Each event also carries private properties `sportsCalendarSync=1` and `gameId=<canonical id>`.

For an active user, reconciliation:

1. loads the server-only connection and AES-256-GCM credential;
2. decrypts the refresh token and exchanges it for an in-memory short-lived access token;
3. verifies the recorded app-created calendar, creating and persisting a replacement only on genuine 404/410 absence;
4. queries the same 30-day lookback window as personalized ICS and reapplies followed-team membership;
5. lists only marker-bearing managed events;
6. creates missing, updates changed, deletes stale managed events, and leaves unmarked/user events untouched;
7. persists sanitized `lastSyncAt`, `lastSyncStatus`, `lastSyncErrorCode`, and counters.

Deterministic identity makes retries idempotent. A manually deleted Google event is inserted again; a retained Google tombstone conflict is restored with the same ID. Cancelled, postponed, and finished games remain desired while they remain inside the shared calendar window.

## Triggers and quota behavior

- **Initial/manual:** after backend connection becomes active, Flutter invokes authenticated `syncGoogleCalendarNow`. The callable derives the UID only from Firebase Auth and returns sanitized counters.
- **Canonical refresh:** one bounded reconciliation pass runs after successful scheduled or admin GOAL ingestion. Up to three users run concurrently; one user's failure is isolated and does not roll back canonical ingestion.
- **Follow/unfollow:** the `users/{uid}` update trigger compares `followedTeamIds` and reconciles only that user. The client Firestore write is not coupled to Google success.

No per-game Firestore trigger or unbounded fan-out is used.

## Credential and error semantics

Refresh credentials remain in the existing server-only collection and use the existing Secret Manager AES-256-GCM key. Decryption validates algorithm, key, IV, tag, ciphertext, and authentication before use. Refresh/access tokens, OAuth codes, client secrets, and encrypted payloads are never returned or deliberately logged; access tokens are never persisted.

`invalid_grant`, rejected credentials, missing credentials, and malformed ciphertext transition the connection to `reauth_required`, delete the unusable credential, preserve the user's Google calendar, and stop automatic retry. Calendar API 403 quota reasons (`userRateLimitExceeded`, `rateLimitExceeded`, and `quotaExceeded`) and HTTP 429 retain `active`, record a sanitized retryable error, and never trigger calendar recreation or destructive reconciliation. A 403 is not treated as permanent based on status alone. Only 404/410 from calendar lookup means missing calendar.

## OAuth return and UI race handling

The registered HTTPS callback remains unchanged. After server persistence it renders a styled Japanese result page, attempts `sportscalendar://google-calendar/oauth-complete`, and always provides an explicit **Sports Calendarに戻る** button and fallback instruction. iOS and Android register that minimal scheme. Failure pages provide a return button but never claim success or expose provider details.

Browser launch itself is not success. On app resume Flutter polls authoritative connection status with bounded backoff (about 5.5 seconds), then settles to disconnected, retryable error, or connected. A newly connected account starts sync immediately. UI states distinguish checking, syncing, synced, sync error/retry, and reauthentication required. The legacy Google ICS action is explicitly labeled as a manual compatibility route.

## Operational verification still required

After merge, an operator must deploy the Functions/rules with the existing four Google secrets, then verify on real iOS and Android devices: successful and denied callback return, background/terminated-app return, initial event population, follow/unfollow, score/kickoff/venue updates, manual deletion recreation, calendar deletion recovery, revocation/reauth, and transient quota behavior. Also inspect sanitized Function logs and Firestore sync metadata. Do not claim OAuth verification/publishing until Google completes it.
