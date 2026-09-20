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
}
