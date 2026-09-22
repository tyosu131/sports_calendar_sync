import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/config/auth_readiness.dart';

final appleSignInConfiguredProvider = Provider<bool>(
  (_) => AuthReadiness.appleSignInEnabled,
);
final appleSignInServiceProvider = Provider<AppleSignInService>(
  (_) => AppleSignInService(),
);

/// Native Apple authentication only. Google login and Calendar OAuth are separate.
/// Inject the two network boundaries for deterministic tests; never log tokens.
class AppleSignInService {
  AppleSignInService({
    Future<AuthorizationCredentialAppleID> Function(String nonce)? request,
    Future<UserCredential> Function(OAuthCredential credential)? authenticate,
  }) : _request = request ?? _requestNative,
       _authenticate = authenticate ?? _authenticateFirebase;

  final Future<AuthorizationCredentialAppleID> Function(String nonce) _request;
  final Future<UserCredential> Function(OAuthCredential credential)
  _authenticate;

  /// Null is an explicit user cancellation, not a failed authentication.
  Future<UserCredential?> signIn() async {
    final rawNonce =
        generateNonce(); // package uses Random.secure(), per attempt
    final nonceHash = sha256.convert(utf8.encode(rawNonce)).toString();
    final AuthorizationCredentialAppleID apple;
    try {
      apple = await _request(nonceHash);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
    final token = apple.identityToken;
    if (token == null || token.trim().isEmpty) {
      throw FirebaseAuthException(code: 'missing-identity-token');
    }
    // Apple's authorizationCode is for code exchange/revocation, not an access
    // token. Firebase verifies the token's nonce against this original nonce.
    return _authenticate(
      AppleAuthProvider.credentialWithIDToken(
        token,
        rawNonce,
        AppleFullPersonName(
          givenName: apple.givenName,
          familyName: apple.familyName,
        ),
      ),
    );
  }

  static Future<AuthorizationCredentialAppleID> _requestNative(String nonce) =>
      SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

  static Future<UserCredential> _authenticateFirebase(
    OAuthCredential credential,
  ) => FirebaseAuth.instance.signInWithCredential(credential);
}
