import 'package:intl/intl.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/config/display_language_setting.dart';
import '../../core/utils/date_time_utils.dart';

/// Clock shown for a kickoff.
///
/// [venueTimeZone] is set only when the fixture carries an authoritative
/// venue IANA zone. Current games do not: [providerTimezone] is the source
/// clock (GOAL writes `UTC`; API-Football writes the request timezone,
/// including a request that happens to be `Asia/Tokyo`), and [venueName]
/// is a place name. Neither is a venue clock, so the displayed time stays
/// JST derived from `startTimeUTC`.
class DisplayedKickoff {
  const DisplayedKickoff({
    required this.time,
    required this.date,
    required this.isToday,
    required this.venueTimeZone,
    this.reference,
  });

  final String time;
  final String date;
  final bool isToday;

  /// Null when the fixture has no authoritative venue timezone.
  final String? venueTimeZone;

  /// Secondary clock for an overseas competition, shown small under JST.
  /// Null for Japanese competitions and competitions without a reference.
  final ReferenceKickoff? reference;
}

/// Kickoff in a competition's published reference clock.
///
/// This is the clock the competition publishes its schedule in (UK time for
/// the Premier League, US Eastern for MLB / NBA / NFL / NHL / UFC). It is not
/// claimed to be the venue clock: a Los Angeles game still shows ET.
class ReferenceKickoff {
  const ReferenceKickoff({
    required this.label,
    required this.time,
    required this.zone,
    this.date,
  });

  /// Short clock name, e.g. 「英国時間」 / 「米東部時間」 (UK / ET in English).
  final String label;

  /// HH:mm in [zone].
  final String time;

  /// IANA zone id.
  final String zone;

  /// M/d in [zone], set only when it differs from the JST calendar date.
  final String? date;

  /// One line, e.g. 「米東部時間 10/30 20:15」.
  String get text => [label, ?date, time].join(' ');
}

const _referenceClocks = <String, ({String zone, String ja, String en})>{
  'football_premier': (zone: 'Europe/London', ja: '英国時間', en: 'UK'),
  'baseball_mlb': (zone: 'America/New_York', ja: '米東部時間', en: 'ET'),
  'basketball_nba': (zone: 'America/New_York', ja: '米東部時間', en: 'ET'),
  'americanfootball_nfl': (zone: 'America/New_York', ja: '米東部時間', en: 'ET'),
  'hockey_nhl': (zone: 'America/New_York', ja: '米東部時間', en: 'ET'),
  'mma_ufc': (zone: 'America/New_York', ja: '米東部時間', en: 'ET'),
};

var _timeZonesReady = false;

/// Reference clock for [competitionKey], or null when none is defined.
ReferenceKickoff? referenceKickoff({
  required DateTime startTimeUtc,
  required String? competitionKey,
}) {
  final clock = _referenceClocks[competitionKey?.trim()];
  if (clock == null) return null;
  if (!_timeZonesReady) {
    tz_data.initializeTimeZones();
    _timeZonesReady = true;
  }
  final local = tz.TZDateTime.from(
    startTimeUtc.toUtc(),
    tz.getLocation(clock.zone),
  );
  final jst = DateTimeUtils.toJst(startTimeUtc);
  final sameDay =
      local.year == jst.year &&
      local.month == jst.month &&
      local.day == jst.day;
  return ReferenceKickoff(
    label: displayLanguageForcesEnglish ? clock.en : clock.ja,
    time: DateFormat('HH:mm').format(local),
    zone: clock.zone,
    date: sameDay ? null : '${local.month}/${local.day}',
  );
}

/// Rejects every timezone value stored on current fixtures.
///
/// There is no separate venue-zone field. Returning a zone from
/// [providerTimezone] or from [venueName] would invent one.
String? authoritativeVenueTimeZone({
  required String providerTimezone,
  String? venueName,
}) {
  final provider = providerTimezone.trim();
  final venue = venueName?.trim() ?? '';
  // Empty and non-empty values are both rejected. No field on the fixture
  // is an authoritative venue IANA zone, so none is returned.
  if (provider.isEmpty && venue.isEmpty) return null;
  return null;
}

DisplayedKickoff displayedKickoff({
  required DateTime startTimeUtc,
  required String providerTimezone,
  String? venueName,
  String? competitionKey,
}) {
  final venueTimeZone = authoritativeVenueTimeZone(
    providerTimezone: providerTimezone,
    venueName: venueName,
  );
  return DisplayedKickoff(
    time: DateTimeUtils.formatTimeOnly(startTimeUtc),
    date: DateTimeUtils.formatJstDate(startTimeUtc),
    isToday: DateTimeUtils.isToday(startTimeUtc),
    venueTimeZone: venueTimeZone,
    reference: referenceKickoff(
      startTimeUtc: startTimeUtc,
      competitionKey: competitionKey,
    ),
  );
}
