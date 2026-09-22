import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sports_calendar_sync/data/auth/apple_sign_in_service.dart';
import 'package:sports_calendar_sync/presentation/screens/sign_in_screen.dart';

Future<void> pumpSignIn(
  WidgetTester tester,
  TargetPlatform platform, {
  bool configured = false,
  AppleSignInService? service,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appleSignInConfiguredProvider.overrideWithValue(configured),
        if (service != null)
          appleSignInServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        theme: ThemeData(platform: platform),
        home: const SignInScreen(),
      ),
    ),
  );
}

void main() {
  for (final configured in [false, true]) {
    testWidgets('Android Google only with Apple flag $configured', (
      tester,
    ) async {
      await pumpSignIn(tester, TargetPlatform.android, configured: configured);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Googleでサインイン'),
            )
            .onPressed,
        isNotNull,
      );
      expect(find.textContaining('Apple'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  }
  testWidgets('iOS hides unavailable Apple without preparation text', (
    tester,
  ) async {
    await pumpSignIn(tester, TargetPlatform.iOS);
    expect(find.text('Googleでサインイン'), findsOneWidget);
    expect(find.textContaining('Apple'), findsNothing);
  });
  testWidgets('configured iOS has Google and standard Apple button', (
    tester,
  ) async {
    await pumpSignIn(tester, TargetPlatform.iOS, configured: true);
    expect(find.text('Googleでサインイン'), findsOneWidget);
    expect(find.byType(SignInWithAppleButton), findsOneWidget);
    expect(find.textContaining('準備中'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });
  testWidgets('macOS retains preparation state', (tester) async {
    await pumpSignIn(tester, TargetPlatform.macOS);
    expect(find.text('Appleでサインイン（準備中）'), findsOneWidget);
  });
  testWidgets(
    'Apple cancel restores UI silently without Firebase/profile access',
    (tester) async {
      await pumpSignIn(
        tester,
        TargetPlatform.iOS,
        configured: true,
        service: AppleSignInService(
          request: (_) async =>
              throw const SignInWithAppleAuthorizationException(
                code: AuthorizationErrorCode.canceled,
                message: 'private provider text',
              ),
        ),
      );
      await tester.tap(find.byType(SignInWithAppleButton));
      await tester.pumpAndSettle();
      expect(find.text('Googleでサインイン'), findsOneWidget);
      expect(find.textContaining('完了できませんでした'), findsNothing);
      expect(find.textContaining('private provider text'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final code in [
    'invalid-credential',
    'account-exists-with-different-credential',
  ]) {
    testWidgets('Apple $code is sanitized', (tester) async {
      await pumpSignIn(
        tester,
        TargetPlatform.iOS,
        configured: true,
        service: AppleSignInService(
          request: (_) async => throw FirebaseAuthException(
            code: code,
            message: 'private provider text',
          ),
        ),
      );
      await tester.tap(find.byType(SignInWithAppleButton));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          code == 'invalid-credential' ? '完了できませんでした' : '以前利用した方法',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('private provider text'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
