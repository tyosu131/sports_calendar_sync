import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/providers/auth_providers.dart';
import 'package:sports_calendar_sync/domain/models/user_profile.dart';
import 'package:sports_calendar_sync/presentation/screens/home_screen.dart';

void main() {
  testWidgets('a signed-in missing profile is not the sign-in prompt', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith((ref) => const AsyncData('uid')),
          userProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.value(null),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('プロフィールを確認できません'), findsWidgets);
    expect(find.text('サインインが必要です'), findsNothing);
    expect(find.text('サインイン'), findsNothing);
  });
}
