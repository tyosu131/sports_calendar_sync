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
  });

  final String time;
  final String date;
  final bool isToday;

  /// Null when the fixture has no authoritative venue timezone.
  final String? venueTimeZone;
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
  );
}
