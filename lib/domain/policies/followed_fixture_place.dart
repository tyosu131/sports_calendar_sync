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

/// Spoken side fact. The chip shows an icon only; this is not drawn on the card.
String followedFixturePlaceSemanticsLabel(FollowedFixturePlace place) =>
    switch (place) {
      FollowedFixturePlace.stadium => 'フォロー中のチームはホーム側',
      FollowedFixturePlace.travel => 'フォロー中のチームはアウェイ側',
    };

/// Venue cues for the cards a person actually scans.
///
/// Each side is independent: a followed home id adds [FollowedFixturePlace.stadium],
/// a followed away id adds [FollowedFixturePlace.travel]. Both can be present.
/// The set is empty when neither side matches, or both sides are the same id.
///
/// Matching is exact on canonical team ids. Source ids and display names
/// are not consulted.
Set<FollowedFixturePlace> fixturePlaceForPerspective({
  required String? homeTeamId,
  required String? awayTeamId,
  required Iterable<String> perspectiveTeamIds,
}) {
  final home = _canonicalId(homeTeamId);
  final away = _canonicalId(awayTeamId);
  if (home != null && away != null && home == away) return const {};

  final perspective = {for (final id in perspectiveTeamIds) ?_canonicalId(id)};
  if (perspective.isEmpty) return const {};

  return {
    if (home != null && perspective.contains(home))
      FollowedFixturePlace.stadium,
    if (away != null && perspective.contains(away)) FollowedFixturePlace.travel,
  };
}

String? _canonicalId(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
