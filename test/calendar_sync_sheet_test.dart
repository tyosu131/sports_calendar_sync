import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/repositories/google_calendar_connection_repository.dart';
import 'package:sports_calendar_sync/presentation/widgets/calendar_sync_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

const token = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ';

Widget app({
  required Future<String> Function() ensureFeed,
  required GoogleCalendarConnectionRepository google,
  Future<bool> Function(Uri)? launchExternal,
}) =>
    MaterialApp(
      home: Scaffold(
        body: CalendarSyncSheet(
          ensureCalendarFeed: ensureFeed,
          googleRepository: google,
          launchGoogle: (uri, {mode = LaunchMode.platformDefault}) async => true,
          launchExternal: launchExternal,
        ),
      ),
    );

GoogleCalendarConnectionRepository googleRepository(
  Future<Object?> Function(String) call,
) => GoogleCalendarConnectionRepository(call: call);

void main() {
  testWidgets('shows three providers with no legacy or raw URL text', (tester) async {
    var feedCalls = 0;
    await tester.pumpWidget(app(
      ensureFeed: () async { feedCalls++; return token; },
      google: googleRepository((_) async => {'connected': false}),
    ));
    await tester.pump();

    expect(find.text('Google Calendar'), findsOneWidget);
    expect(find.text('Apple Calendar'), findsOneWidget);
    expect(find.text('その他のカレンダー'), findsOneWidget);
    expect(find.textContaining('互換用'), findsNothing);
    expect(find.textContaining('google.com/calendar/render'), findsNothing);
    expect(find.textContaining('cloudfunctions.net'), findsNothing);
    expect(feedCalls, 0);
  });

  testWidgets('Google connect and reconnect never issue an ICS feed', (tester) async {
    for (final reauth in [false, true]) {
      var feedCalls = 0;
      var beginCalls = 0;
      await tester.pumpWidget(app(
        ensureFeed: () async { feedCalls++; return token; },
        google: googleRepository((name) async {
          if (name == 'getGoogleCalendarConnectionStatus') {
            return {'connected': false, 'reauthRequired': reauth};
          }
          beginCalls++;
          return {'authorizationUrl': 'https://accounts.google.com/oauth'};
        }),
      ));
      await tester.pump();
      await tester.tap(find.text(reauth ? '再連携' : 'Google Calendarと連携'));
      await tester.pump();
      expect(beginCalls, 1);
      expect(feedCalls, 0);
    }
  });

  testWidgets('connected Google uses syncNow without issuing an ICS feed', (tester) async {
    var feedCalls = 0;
    var syncCalls = 0;
    await tester.pumpWidget(app(
      ensureFeed: () async { feedCalls++; return token; },
      google: googleRepository((name) async {
        if (name == 'syncGoogleCalendarNow') {
          syncCalls++;
          return {'status': 'synced'};
        }
        return {'connected': true, 'syncStatus': 'synced'};
      }),
    ));
    await tester.pump();
    await tester.tap(find.text('今すぐ同期'));
    await tester.pump();
    expect(syncCalls, 1);
    expect(feedCalls, 0);
    expect(find.text('連携済み・同期済み'), findsOneWidget);
  });

  testWidgets('Apple lazily issues feed and opens a webcal external URI', (tester) async {
    var feedCalls = 0;
    Uri? launched;
    await tester.pumpWidget(app(
      ensureFeed: () async { feedCalls++; return token; },
      google: googleRepository((_) async => {'connected': false}),
      launchExternal: (uri) async { launched = uri; return true; },
    ));
    await tester.pump();
    await tester.tap(find.text('Apple Calendar'));
    await tester.pump();
    expect(feedCalls, 1);
    expect(launched?.scheme, 'webcal');
    expect(launched?.queryParameters['token'], token);
  });

  testWidgets('Other lazily issues feed then offers copy/share without raw URL', (tester) async {
    var feedCalls = 0;
    await tester.pumpWidget(app(
      ensureFeed: () async { feedCalls++; return token; },
      google: googleRepository((_) async => {'connected': false}),
    ));
    await tester.pump();
    await tester.tap(find.text('その他のカレンダー'));
    await tester.pumpAndSettle();
    expect(feedCalls, 1);
    expect(find.text('購読URLをコピー'), findsOneWidget);
    expect(find.text('URLをシェア'), findsOneWidget);
    expect(find.textContaining('cloudfunctions.net'), findsNothing);
  });
}
