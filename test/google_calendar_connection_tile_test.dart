import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/repositories/google_calendar_connection_repository.dart';
import 'package:sports_calendar_sync/presentation/widgets/google_calendar_connection_tile.dart';
import 'package:url_launcher/url_launcher.dart';

Widget app(GoogleCalendarConnectionRepository repository) => MaterialApp(
      home: Scaffold(
        body: GoogleCalendarConnectionTile(
          key: UniqueKey(),
          repository: repository,
          launch: (uri, {mode = LaunchMode.platformDefault}) async => true,
        ),
      ),
    );

void main() {
  testWidgets('renders disconnected then connecting without claiming success',
      (tester) async {
    final begin = Completer<Object?>();
    final repository = GoogleCalendarConnectionRepository(call: (name) async {
      if (name == 'getGoogleCalendarConnectionStatus') {
        return {'connected': false};
      }
      return begin.future;
    });
    await tester.pumpWidget(app(repository));
    await tester.pump();
    expect(find.text('未連携'), findsOneWidget);
    await tester.tap(find.text('Google Calendarと連携'));
    await tester.pump();
    expect(find.text('処理中'), findsOneWidget);
    begin.complete({
      'authorizationUrl': 'https://accounts.google.com/o/oauth2/v2/auth?state=x'
    });
    await tester.pump();
    expect(find.text('処理中'), findsOneWidget);
  });

  testWidgets('failed browser launch is an error, not connection success',
      (tester) async {
    final repository = GoogleCalendarConnectionRepository(call: (name) async {
      if (name == 'getGoogleCalendarConnectionStatus') {
        return {'connected': false};
      }
      return {
        'authorizationUrl':
            'https://accounts.google.com/o/oauth2/v2/auth?state=x'
      };
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GoogleCalendarConnectionTile(
          repository: repository,
          launch: (uri, {mode = LaunchMode.platformDefault}) async => false,
        ),
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('Google Calendarと連携'));
    await tester.pump();
    expect(find.text('エラー（タップして再試行）'), findsOneWidget);
    expect(find.text('連携済み・同期済み'), findsNothing);
  });

  testWidgets('renders connected and error states from backend status',
      (tester) async {
    await tester.pumpWidget(app(GoogleCalendarConnectionRepository(
      call: (_) async => {'connected': true, 'calendarName': 'Sports Calendar', 'syncStatus': 'synced'},
    )));
    await tester.pump();
    expect(find.text('連携済み・同期済み'), findsOneWidget);
    expect(find.text('連携解除'), findsOneWidget);

    await tester.pumpWidget(app(GoogleCalendarConnectionRepository(
      call: (_) async => throw StateError('offline'),
    )));
    await tester.pump();
    expect(find.text('エラー（タップして再試行）'), findsOneWidget);
  });

  testWidgets('renders sync failure and reconnect-required states', (tester) async {
    await tester.pumpWidget(app(GoogleCalendarConnectionRepository(
      call: (_) async => {'connected': true, 'syncStatus': 'error'},
    )));
    await tester.pump();
    expect(find.text('連携済み・同期エラー（タップして再試行）'), findsOneWidget);

    await tester.pumpWidget(app(GoogleCalendarConnectionRepository(
      call: (_) async => {'connected': false, 'reauthRequired': true},
    )));
    await tester.pump();
    expect(find.text('再連携が必要です'), findsOneWidget);
  });
}
