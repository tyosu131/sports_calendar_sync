# Apple Sign-In — deferred Store-readiness guide

Status: **DEFERRED_STORE_READINESS** (owner decision, 2026-09-22).
Apple Sign-In implementation is prepared but intentionally disabled for the tester V1.
Apple Developer Program enrollment and Apple/Firebase configuration are deferred until App Store release preparation.
The owner will not enroll during tester V1. External setup has not been performed
for this activation, and no iPhone Apple-auth E2E is claimed or required now.
This document is the future activation runbook, not a tester release gate.
Earlier Personal Team evidence remains valid; the entitlement is not attached
to tester signing. README summarizes policy; current-state records operational
evidence; this guide preserves the deferred configuration and verification steps.

## Goal / scope / acceptance

One mobile authentication and operational closure: preserve the Firebase-generated
Android OAuth config and proven Google flow; keep Google only on Android and iOS
tester V1; retain secure native Apple sign-in for later activation; record Node 22
deployment and Android E2E evidence.
No email/password, account merge UI, identifier migration, production keys,
Console writes, deployment, calendar/domain changes or unrelated macOS changes.
Acceptance is Google-only Android/iOS by default, with deterministic tests and
Apple implementation retained but disabled. The future human steps below do not
block tester V1.

## Repository evidence and implementation

- `sign_in_with_apple` ^6.1.4 (locally resolved 6.1.4); existing Firebase Auth ^6.2.0.
- Previous code requested an Apple identity token without a nonce and passed an
  authorization code as an access token. That path has been replaced.
- `AppleSignInService` uses the package's `generateNonce()` (32 characters from
  `Random.secure()`), SHA-256 via `crypto`, and
  `AppleAuthProvider.credentialWithIDToken(token, rawNonce, fullName)` followed by
  Firebase `signInWithCredential`. Full name is passed on first consent; missing
  name on subsequent sign-ins does not fabricate a name. No tokens/nonces/provider
  payloads are logged or manually persisted. Firebase SDK session storage remains.
- Cancellation returns null before Firebase/profile operations. Missing token
  fails safely. Other failures get sanitized UI; account-collision errors direct
  the user to their previous login method. Existing profile-by-UID and routing
  behavior is retained. Google credential acquisition is unchanged.
- iOS minimum deployment target is 15; native Apple Sign-In requires iOS 13+.
  Firebase initialization and the iOS Firebase plist already exist. They do not
  prove that the Apple provider or signing capability is enabled.
- No active `CODE_SIGN_ENTITLEMENTS` exists. `Runner/AppleSignIn.entitlements`
  declares the capability but is intentionally not wired to Personal Team builds.
  Wiring requires a capable signing team/provisioning profile, verified below.
- Android always hides Apple, including with the Apple build flag. iOS tester V1
  intentionally hides it (no 準備中 UI). `APPLE_SIGN_IN_ENABLED` defaults to
  `false`; only a future explicitly enabled iOS build uses SignInWithAppleButton.
  `--dart-define=APPLE_SIGN_IN_ENABLED=true` is a non-secret build readiness flag,
  not evidence of Console setup and not a security authorization boundary.

## Future App Store preparation — deferred manual actions

Do not perform these for tester V1. First approve the final bundle ID and its
Firebase registration as part of Store preparation. The current tester ID is
`com.example.sportsCalendarSync`; do not change it in this PR or invent its
replacement. Never copy secrets into Git.

| Where / menu | Field and expected value | Why / verification |
|---|---|---|
| Apple Developer → Account → Membership | Active Apple Developer Program team; use the owner's actual team | Sign in with Apple capability requires program membership. If enrollment is needed, cost/ownership decision stays with the owner. Personal Team is insufficient. |
| Certificates, Identifiers & Profiles → Identifiers → App IDs | Select the approved final bundle ID after identifier migration; Capabilities → Sign in with Apple → Enable/Save. Configure as primary App ID unless an existing approved group is used | Native token audience and signed app identity must match. Verify saved capability; do not invent a new bundle ID. |
| Xcode → ios/Runner.xcworkspace → Runner → Signing & Capabilities | Select the actual paid team; add Sign in with Apple; Build Settings → Code Signing Entitlements = `Runner/AppleSignIn.entitlements` for Debug/Profile/Release | Refresh automatic signing or regenerate the manual provisioning profile after enabling the App ID capability. Verify Xcode signs successfully and both profile and signed app include `com.apple.developer.applesignin` = `[Default]`. Keep team certificates/keys/profile files out of Git. Review resulting project wiring before sharing it. |
| Firebase Console → sports-calendar-sync-a4564 → Project settings → Your apps → iOS | Registration for the approved final bundle ID | Must match the native App ID after migration; the existing tester plist is not proof of provider enablement. |
| Firebase Console → Authentication → Sign-in method → Apple | Enable provider and Save | Required to exchange native Apple ID tokens. Native code does not launch a Services-ID web flow. Do not invent a Services ID or treat an empty optional field as a known error. Record whether the console requires OAuth code flow fields for this project; use the conditional steps below if required/configured. |
| Local configured iOS build | `flutter run --dart-define=APPLE_SIGN_IN_ENABLED=true` after signing/provider setup | Verify Google and standard Apple buttons, success → Firebase user/profile → Home, repeat sign-in, cancel without error, Share Email and Hide My Email. Use an iCloud account with 2FA. Do not distribute the Apple-enabled build before this passes. |

### Conditional Services ID / OAuth code flow configuration

Firebase's full Apple setup guide covers website association and OAuth code flow.
These fields are not values the native app can infer. If required by the Console
or if that flow is configured, complete it as one consistent Apple/Firebase setup:

1. Apple Developer → Identifiers → Services IDs: choose/register the owner's
   service identifier (reverse-domain string; **not** an invented value from this
   task). Enable Sign in with Apple → Configure, select the primary App ID above.
2. Domains and Subdomains: `sports-calendar-sync-a4564.firebaseapp.com`;
   Return URLs: `https://sports-calendar-sync-a4564.firebaseapp.com/__/auth/handler`.
   This is Firebase Auth's handler, **not** the Google Calendar OAuth callback.
3. Apple Developer → Keys → Sign in with Apple: associate the actual primary App
   ID, obtain Key ID and download the private `.p8` once into secure owner storage.
4. Firebase → Authentication → Apple: Services ID = actual service identifier;
   OAuth code flow → Apple Team ID = actual membership team ID; Key ID = matching
   Apple key identifier; Private key = the matching `.p8` content, Console only.
   Save and verify sign-in; never print or commit the private key.
5. If Firebase authentication emails are used, Apple → Services → Sign in with
   Apple → Email Sources: configure Private Email Relay for the actual Firebase
   sender (`noreply@sports-calendar-sync-a4564.firebaseapp.com` unless customized).
   This task adds no email/password or email-link flow. Verify relay only if used.

No production key or Console setting is created by this PR. The entitlement
source is prepared, but actual signing/provisioning remains a deferred Store
dependency, not a tester V1 blocker.

## Account identity / collisions

The Apple-specific checks below apply before future activation, not to the
current Google-only tester release.

Profiles remain keyed by Firebase UID, not by email. The app never calls
`linkWithCredential` or merges users by email. Firebase itself can auto-link
trusted providers sharing an email (official example: Apple then Google).
Google's trusted status depends on email domain; collision settings and account
history matter. Other combinations can raise
`account-exists-with-different-credential`; the UI asks for the prior login method.
Hide My Email can produce a different Firebase user from Google. Do not merge
that user with a real-email profile without a separately reviewed consent/linking
flow. In Firebase Authentication → Settings → User account linking, inspect the
current same-email policy; do not change it speculatively. Verify owner-approved
test accounts in Authentication → Users, including UID/provider list and retained
follow data. No claim of matching UID is made before that device test.

## Sources checked for this implementation

- [Firebase Flutter native Apple flow](https://firebase.google.com/docs/auth/flutter/federated-auth#apple)
- [Firebase Apple setup, nonce and anonymized data requirements](https://firebase.google.com/docs/auth/ios/apple)
- [Firebase trusted providers and automatic linking](https://firebase.google.com/docs/auth/users#verified_email_addresses)
- [Installed package 6.1.4 setup and standard button](https://pub.dev/packages/sign_in_with_apple/versions/6.1.4)

## iOS dependency configuration

Profile.xcconfig composes CocoaPods Profile and Flutter generated settings like
Debug/Release. iOS remains 15. The repository ignores lockfiles; do not hand-write
or stage Podfile.lock, provisioning profiles, certificates or private keys.
