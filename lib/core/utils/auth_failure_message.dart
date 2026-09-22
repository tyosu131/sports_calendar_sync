/// Converts authentication failures into stable, user-facing copy.
/// Raw platform/Firebase diagnostics should only be sent to debug logging.
String authenticationFailureMessage(String provider) =>
    '$providerでのサインインを完了できませんでした。'
    '時間をおいてもう一度お試しください。';

String appleAuthenticationFailureMessage(String code) =>
    code == 'account-exists-with-different-credential' ||
        code == 'credential-already-in-use' ||
        code == 'email-already-in-use'
    ? '以前利用した方法でサインインしてください。'
    : authenticationFailureMessage('Apple');
