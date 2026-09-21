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
            appleAction: Icon(Icons.open_in_new),
            otherAction: Icon(Icons.link),
            googleCalendarTile: ListTile(
              title: Text('Google Calendar'),
              subtitle: Text('直接連携'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Apple Calendar'), findsOneWidget);
    expect(find.text('Apple Calendarで購読'), findsOneWidget);
    expect(find.text('その他のカレンダー'), findsOneWidget);
    expect(find.text('ICS購読URLをコピー・共有'), findsOneWidget);
    expect(find.text('Google Calendar'), findsOneWidget);
    expect(find.text('連携解除'), findsNothing);
    expect(find.text('購読中'), findsNothing);
    expect(find.text('同期済み'), findsNothing);
  });
}
