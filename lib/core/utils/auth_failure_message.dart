/// Converts authentication failures into stable, user-facing copy.
/// Raw platform/Firebase diagnostics should only be sent to debug logging.
String authenticationFailureMessage(String provider) =>
    '$providerでのサインインを完了できませんでした。'
    '時間をおいてもう一度お試しください。';
