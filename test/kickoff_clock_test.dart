import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sports_calendar_sync/core/utils/date_time_utils.dart';
import 'package:sports_calendar_sync/domain/policies/kickoff_clock.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  test('provider clocks and venue names are not a venue timezone', () {
    const zones = [
      'UTC',
      'Etc/UTC',
      'Asia/Tokyo',
      'Europe/London',
      'America/New_York',
    ];
    for (final zone in zones) {
      expect(
        authoritativeVenueTimeZone(
          providerTimezone: zone,
          venueName: 'Old Trafford',
        ),
        isNull,
        reason: '$zone is not a venue clock',
      );
    }
    expect(
      authoritativeVenueTimeZone(providerTimezone: '', venueName: '国立'),
      isNull,
    );
    expect(authoritativeVenueTimeZone(providerTimezone: 'UTC'), isNull);
  });

  test(
    'kickoff stays JST from startTimeUTC for every stored provider clock',
    () {
      final start = DateTime.utc(2026, 10, 17, 10);
      final jst = DateTimeUtils.formatTimeOnly(start);
      expect(jst, '19:00');

      for (final zone in ['UTC', 'Asia/Tokyo', 'America/New_York']) {
        final shown = displayedKickoff(
          startTimeUtc: start,
          providerTimezone: zone,
          venueName: 'Emirates Stadium',
        );
        expect(shown.venueTimeZone, isNull);
        expect(shown.time, jst);
        expect(shown.time, isNot('10:00'));
        expect(shown.time, isNot('06:00'));
        expect(shown.date, DateTimeUtils.formatJstDate(start));
        expect(shown.time.contains(zone), isFalse);
      }
    },
  );
}
