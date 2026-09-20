import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('distinguishes Apple and generic subscriptions from Google',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarSyncSettingsSection(
            calendarSyncButton: Icon(Icons.link),
            googleCalendarTile: ListTile(
              title: Text('Google Calendar'),
              subtitle: Text('直接連携'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Apple・その他のカレンダー'), findsOneWidget);
    expect(find.text('購読URLで同期'), findsOneWidget);
    expect(find.text('Google Calendar'), findsOneWidget);
  });
}
