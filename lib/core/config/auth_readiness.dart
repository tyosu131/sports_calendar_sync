/// Repository-controlled authentication capability readiness.
///
/// Change this single value to `true` only after the Apple Developer, Firebase,
/// provisioning, and physical-device gates in `docs/apple-sign-in-readiness.md`
/// have all been completed.
abstract final class AuthReadiness {
  static const bool appleSignInEnabled = false;
}
