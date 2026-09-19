import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/presentation/screens/sign_in_screen.dart';

void main() {
  testWidgets('V1 keeps Google and Apple authentication options', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignInScreen())),
    );
    expect(find.text('Googleでサインイン'), findsOneWidget);
    expect(find.text('Appleでサインイン'), findsOneWidget);
    expect(find.textContaining('メール'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
