import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/presentation/widgets/calendar_sync_button.dart';

void main() {
  testWidgets('calendar sync action uses sync rather than calendar icon',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: CalendarSyncButton())),
      ),
    );

    expect(find.byIcon(Icons.sync_alt), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month), findsNothing);
    expect(
      find.byTooltip('フォロー中のチームをカレンダーに同期'),
      findsOneWidget,
    );
  });
}
