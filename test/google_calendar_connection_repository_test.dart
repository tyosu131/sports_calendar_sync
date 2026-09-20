import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/repositories/google_calendar_connection_repository.dart';

void main() {
  test('accepts only the Google HTTPS authorization host', () async {
    final repository = GoogleCalendarConnectionRepository(
      call: (_) async => {'authorizationUrl': 'javascript:alert(1)'},
    );
    await expectLater(repository.begin(), throwsA(isA<InvalidGoogleCalendarResponse>()));
  });

  test('rejects malformed status and disconnect responses', () async {
    final repository = GoogleCalendarConnectionRepository(call: (_) async => {'connected': 'yes'});
    await expectLater(repository.status(), throwsA(isA<InvalidGoogleCalendarResponse>()));
    await expectLater(repository.disconnect(), throwsA(isA<InvalidGoogleCalendarResponse>()));
  });

  test('parses sanitized connection status', () async {
    final repository = GoogleCalendarConnectionRepository(
      call: (_) async => {'connected': true, 'calendarName': 'Sports Calendar'},
    );
    final status = await repository.status();
    expect(status.connected, isTrue);
    expect(status.calendarName, 'Sports Calendar');
  });

  test('parses sync and reconnect status and returns sanitized sync result', () async {
    final repository = GoogleCalendarConnectionRepository(call: (name) async =>
      name == 'syncGoogleCalendarNow'
        ? {'status': 'synced', 'created': 1}
        : {'connected': false, 'reauthRequired': true, 'syncStatus': 'error'});
    final status = await repository.status();
    expect(status.reauthRequired, isTrue);
    expect(status.syncStatus, 'error');
    expect(await repository.syncNow(), 'synced');
  });

  test('OAuth completion polling is bounded and converges to connected', () async {
    var calls = 0;
    final repository = GoogleCalendarConnectionRepository(call: (_) async {
      calls++;
      return {'connected': calls >= 3, 'syncStatus': calls >= 3 ? 'synced' : null};
    });
    final result = await repository.waitForConnection(
      delays: const [Duration.zero, Duration.zero, Duration.zero],
      wait: (_) async {},
    );
    expect(result.connected, isTrue);
    expect(calls, 3);
  });

  test('OAuth completion polling stops disconnected and propagates errors', () async {
    var calls = 0;
    final disconnected = GoogleCalendarConnectionRepository(call: (_) async {
      calls++;
      return {'connected': false};
    });
    expect((await disconnected.waitForConnection(
      delays: const [Duration.zero, Duration.zero], wait: (_) async {},
    )).connected, isFalse);
    expect(calls, 3);
    final failed = GoogleCalendarConnectionRepository(call: (_) async => throw StateError('offline'));
    await expectLater(failed.waitForConnection(delays: const []), throwsStateError);
  });
}
