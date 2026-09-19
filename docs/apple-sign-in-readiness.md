# Apple Sign-In readiness (Human Gate)

The Apple option remains in the application and failures are handled without
showing raw platform exceptions. The repository intentionally does **not**
enable the entitlement unconditionally: development currently uses a Personal
Team, for which that capability can make the proven device build un-signable.

To complete the external-account gate:

1. Enroll the signing account in the Apple Developer Program.
2. In Certificates, Identifiers & Profiles, enable **Sign in with Apple** for
   the App ID matching the Runner bundle identifier.
3. Add the Sign in with Apple capability in Xcode, producing a Runner
   entitlement containing `com.apple.developer.applesignin`, and refresh the
   provisioning profile. Commit only the entitlement/project wiring; never
   commit a team ID, certificate, key, or provisioning UUID.
4. Enable the Apple provider in Firebase Authentication and supply any Apple
   service ID, team ID, key ID, and private key required by that console. Do
   not put these values in Git.
5. Re-run Google and Apple sign-in on a physical iPhone. Apple physical-device
   E2E is not considered verified until this succeeds.

## iOS dependency configuration

`Profile.xcconfig` now composes the CocoaPods Profile settings with Flutter's
generated settings, matching the existing Debug and Release pattern. The
minimum deployment target remains iOS 15.

This repository's existing top-level policy ignores `*.lock`, and the merged
iPhone baseline does not contain an `ios/Podfile.lock`. That policy is preserved
in this closure rather than checking in a hand-authored lockfile when CocoaPods
is unavailable in the cloud environment. A maintainer may separately change
the repository-wide lock policy after generating and reviewing a real lockfile
with the supported CocoaPods version.
