/// Repository-controlled authentication capability readiness.
///
/// Enable only in an iOS build whose Apple/Firebase/provisioning configuration
/// has been checked; see docs/apple-sign-in-readiness.md. Not a secret.
abstract final class AuthReadiness {
  static const bool appleSignInEnabled = bool.fromEnvironment(
    'APPLE_SIGN_IN_ENABLED',
    defaultValue: false,
  );
}
