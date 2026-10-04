import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/providers/auth_providers.dart';
import 'package:sports_calendar_sync/presentation/widgets/calendar_sync_button.dart';

void main() {
  testWidgets('auth loading is not the calendar sign-in snackbar', (
    tester,
  ) async {
    await _pump(tester, const AsyncLoading<String?>());
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(find.text('カレンダー同期にはサインインが必要です'), findsNothing);
    expect(find.text('カレンダー同期の状態を確認できません'), findsNothing);
  });

  testWidgets('auth failure is not the calendar sign-in snackbar', (
    tester,
  ) async {
    await _pump(
      tester,
      AsyncError<String?>(StateError('permission-denied'), StackTrace.empty),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('カレンダー同期にはサインインが必要です'), findsNothing);
    expect(find.text('カレンダー同期の状態を確認できません'), findsOneWidget);
  });

  testWidgets('settled signed-out still asks for calendar sign-in', (
    tester,
  ) async {
    await _pump(tester, const AsyncData<String?>(null));
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(find.text('カレンダー同期にはサインインが必要です'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, AsyncValue<String?> session) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [authSessionProvider.overrideWith((ref) => session)],
      child: const MaterialApp(home: Scaffold(body: CalendarSyncButton())),
    ),
  );
}
