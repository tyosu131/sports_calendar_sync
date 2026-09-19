import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/presentation/screens/sign_in_screen.dart';

void main() {
  testWidgets('Google stays enabled while Apple readiness is gated', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignInScreen())),
    );
    expect(find.text('Googleでサインイン'), findsOneWidget);
    final googleButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Googleでサインイン'),
    );
    expect(googleButton.onPressed, isNotNull);
    expect(
      find.widgetWithText(OutlinedButton, 'Appleでサインイン'),
      findsNothing,
    );
    expect(find.text('Appleでサインイン（準備中）'), findsOneWidget);
    expect(find.textContaining('メール'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
