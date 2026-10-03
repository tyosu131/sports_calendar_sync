import '../../core/utils/date_time_utils.dart';
import '../models/game.dart';
import '../models/team.dart';
import 'club_presentation_data.dart';
import 'team_display_name_policy.dart';
import 'team_presentation_policy.dart';

/// Short card title.
///
/// A reviewed catalog alias is used only when it matches the start of
/// [displayName], contains at least two characters, and is shorter than that
/// name. Otherwise the full display name is returned and the card ellipsizes
/// it. Names are not cut to a fixed length, and missing aliases are not
/// invented.
String leagueTeamCardLabel({
  required String displayName,
  required DisplayLanguage language,
  ClubPresentation? presentation,
}) {
  final full = displayName.trim();
  if (full.isEmpty) return full;
  return _catalogPrefixLabel(
        full: full,
        language: language,
        presentation: presentation,
      ) ??
      full;
}

String leagueTeamCardLabelForTeam(Team team) {
  final full = teamDisplayNames.teamName(team);
  final language = teamDisplayNames.languageFor(team.competitionKey);
  final presentation = (team.competitionKey?.startsWith('football_') ?? false)
      ? clubPresentation([
          team.nameJa,
          team.nameEn,
          full,
        ], competitionKey: team.competitionKey)
      : null;
  return leagueTeamCardLabel(
    displayName: full,
    language: language,
    presentation: presentation,
  );
}

String leagueTeamCardLabelForName(
  String displayName, {
  String? competitionKey,
}) {
  final language = teamDisplayNames.languageFor(competitionKey);
  final presentation = (competitionKey?.startsWith('football_') ?? false)
      ? clubPresentation([displayName], competitionKey: competitionKey)
      : null;
  return leagueTeamCardLabel(
    displayName: displayName,
    language: language,
    presentation: presentation,
  );
}

/// Next opponent and kickoff for one team, from games already loaded.
class LeagueTeamNextMatch {
  const LeagueTeamNextMatch({required this.opponent, required this.when});

  final String opponent;
  final String when;
}

LeagueTeamNextMatch? nextMatchForTeam(
  Team team,
  List<Game> games, {
  required String competitionContextKey,
}) {
  final contextKey = competitionContextKey.trim();
  final upcoming =
      games
          .where(
            (game) =>
                (game.homeTeamId == team.id || game.awayTeamId == team.id) &&
                game.competitionKey == contextKey,
          )
          .toList()
        ..sort((a, b) => a.startTimeUtc.compareTo(b.startTimeUtc));
  if (upcoming.isEmpty) return null;
  final game = upcoming.first;
  final isHome = game.homeTeamId == team.id;
  final opponentName = isHome
      ? teamDisplayNames.awayName(game)
      : teamDisplayNames.homeName(game);
  final short = leagueTeamCardLabelForName(
    opponentName,
    competitionKey: game.competitionKey,
  );
  final start = game.startTimeUtc.toDate();
  final when =
      '${DateTimeUtils.formatDateOnly(start)} ${DateTimeUtils.formatTimeOnly(start)}';
  return LeagueTeamNextMatch(opponent: 'vs $short', when: when);
}

String? _catalogPrefixLabel({
  required String full,
  required DisplayLanguage language,
  required ClubPresentation? presentation,
}) {
  if (presentation == null) return null;
  final pool = <String>[
    if (language == DisplayLanguage.japanese &&
        presentation.nameJa.trim().isNotEmpty)
      presentation.nameJa,
    if (language == DisplayLanguage.english &&
        presentation.nameEn.trim().isNotEmpty)
      presentation.nameEn,
    ...presentation.aliases,
    ...presentation.scopedAliases,
  ];
  String? best;
  final seen = <String>{};
  for (final raw in pool) {
    final name = raw.trim();
    if (name.isEmpty || !seen.add(name)) continue;
    final length = name.runes.length;
    // One character is an initial, not a place name. The full name is not a
    // shorter label.
    if (length < 2 || length >= full.runes.length) continue;
    if (!full.startsWith(name)) continue;
    final japanese = _hasKanaOrKanji(name);
    if (language == DisplayLanguage.japanese && !japanese) continue;
    if (language == DisplayLanguage.english && japanese) continue;
    if (best == null) {
      best = name;
      continue;
    }
    final byLength = length.compareTo(best.runes.length);
    if (byLength < 0 || (byLength == 0 && name.compareTo(best) < 0)) {
      best = name;
    }
  }
  return best;
}

bool _hasKanaOrKanji(String value) {
  return value.runes.any(
    (rune) =>
        (rune >= 0x3040 && rune <= 0x30FF) ||
        (rune >= 0x4E00 && rune <= 0x9FFF),
  );
}
