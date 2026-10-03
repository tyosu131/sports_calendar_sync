/// Where one perspective team is listed on a fixture.
///
/// [stadium] means that team's id is the fixture home id.
/// [travel] means that team's id is the fixture away id.
///
/// This is the stored home/away designation (`homeTeamId` / `awayTeamId`).
/// Games have no neutral-venue flag and no stadium master, so [stadium] is
/// not proof the match is at the club's own ground. [travel] is a transit
/// cue, not a flight.
enum FollowedFixturePlace { stadium, travel }

/// Short Japanese label. The icon is never the only signal.
String followedFixturePlaceLabel(FollowedFixturePlace place) => switch (place) {
  FollowedFixturePlace.stadium => 'スタジアム',
  FollowedFixturePlace.travel => '移動',
};

/// Venue cue for the cards a person actually scans.
///
/// Returns null when the cue would be a guess:
/// - no perspective id matches either side
/// - both sides contain a perspective id (a single label would be wrong
///   for one of them)
/// - both sides are the same id
///
/// Matching is exact on canonical team ids. Source ids and display names
/// are not consulted.
FollowedFixturePlace? fixturePlaceForPerspective({
  required String? homeTeamId,
  required String? awayTeamId,
  required Iterable<String> perspectiveTeamIds,
}) {
  final home = _canonicalId(homeTeamId);
  final away = _canonicalId(awayTeamId);
  if (home != null && away != null && home == away) return null;

  final perspective = {for (final id in perspectiveTeamIds) ?_canonicalId(id)};
  if (perspective.isEmpty) return null;

  final homeListed = home != null && perspective.contains(home);
  final awayListed = away != null && perspective.contains(away);
  if (homeListed == awayListed) return null;
  return homeListed
      ? FollowedFixturePlace.stadium
      : FollowedFixturePlace.travel;
}

String? _canonicalId(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
