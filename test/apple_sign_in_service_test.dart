import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sports_calendar_sync/data/auth/apple_sign_in_service.dart';

class FakeUserCredential extends Fake implements UserCredential {}

AuthorizationCredentialAppleID appleResult({
  String? token = 'synthetic-token',
}) => AuthorizationCredentialAppleID(
  userIdentifier: 'synthetic-user',
  givenName: 'Test',
  familyName: 'User',
  email: 'test@example.test',
  authorizationCode: 'synthetic-code',
  identityToken: token,
  state: null,
);
void main() {
  test(
    'success binds fresh secure nonce and Apple name to Firebase credential',
    () async {
      final hashes = <String>[];
      final credentials = <OAuthCredential>[];
      final result = FakeUserCredential();
      final service = AppleSignInService(
        request: (hash) async {
          hashes.add(hash);
          return appleResult();
        },
        authenticate: (credential) async {
          credentials.add(credential);
          return result;
        },
      );
      for (var i = 0; i < 2; i++) {
        expect(await service.signIn(), same(result));
        final c = credentials[i];
        expect(c.providerId, 'apple.com');
        expect(c.rawNonce, hasLength(32));
        expect(hashes[i], sha256.convert(utf8.encode(c.rawNonce!)).toString());
        expect(hashes[i], isNot(c.rawNonce));
        expect(c.idToken, 'synthetic-token');
        expect(c.accessToken, isNull);
        expect(c.appleFullPersonName?.givenName, 'Test');
        expect(c.appleFullPersonName?.familyName, 'User');
      }
      expect(credentials[0].rawNonce, isNot(credentials[1].rawNonce));
    },
  );
  test('cancel performs no Firebase authentication', () async {
    var calls = 0;
    final service = AppleSignInService(
      request: (_) async => throw const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'cancel',
      ),
      authenticate: (_) async {
        calls++;
        return FakeUserCredential();
      },
    );
    expect(await service.signIn(), isNull);
    expect(calls, 0);
  });
  test('missing or blank token fails before Firebase', () async {
    for (final token in [null, '', '  ']) {
      final service = AppleSignInService(
        request: (_) async => appleResult(token: token),
        authenticate: (_) async => fail('Must not authenticate'),
      );
      await expectLater(
        service.signIn(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'missing-identity-token',
          ),
        ),
      );
    }
  });
  test('Firebase error is not a cancellation', () async {
    final error = FirebaseAuthException(
      code: 'account-exists-with-different-credential',
    );
    final service = AppleSignInService(
      request: (_) async => appleResult(),
      authenticate: (_) async => throw error,
    );
    await expectLater(service.signIn(), throwsA(same(error)));
  });
  test('non-cancel Apple error remains an error', () async {
    const error = SignInWithAppleAuthorizationException(
      code: AuthorizationErrorCode.failed,
      message: 'failure',
    );
    final service = AppleSignInService(request: (_) async => throw error);
    await expectLater(service.signIn(), throwsA(same(error)));
  });
}
