import '../../core/utils/date_time_utils.dart';
import '../models/game.dart';
import '../models/team.dart';
import 'club_presentation_data.dart';
import 'team_display_name_policy.dart';
import 'team_presentation_policy.dart';

/// Short card title. Uses an existing catalog alias when one is a short
/// prefix of the display name. Otherwise keeps a short trailing token, or the
/// full name when cutting it would invent a label.
String leagueTeamCardLabel({
  required String displayName,
  required DisplayLanguage language,
  ClubPresentation? presentation,
}) {
  final full = displayName.trim();
  if (full.isEmpty) return full;
  final fromCatalog = _catalogShortLabel(
    full: full,
    language: language,
    presentation: presentation,
  );
  if (fromCatalog != null) return fromCatalog;
  return _fallbackShortLabel(full);
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

String? _catalogShortLabel({
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
  ];
  final shorts = <String>[];
  final seen = <String>{};
  for (final raw in pool) {
    final name = raw.trim();
    if (!seen.add(name)) continue;
    final length = name.runes.length;
    if (length < 2 || length > 6) continue;
    final japanese = _hasKanaOrKanji(name);
    if (language == DisplayLanguage.japanese && !japanese) continue;
    if (language == DisplayLanguage.english && japanese) continue;
    shorts.add(name);
  }
  if (shorts.isEmpty) return null;
  shorts.sort((a, b) {
    final aPrefix = full.startsWith(a) ? 0 : 1;
    final bPrefix = full.startsWith(b) ? 0 : 1;
    final byPrefix = aPrefix.compareTo(bPrefix);
    if (byPrefix != 0) return byPrefix;
    final byLength = a.runes.length.compareTo(b.runes.length);
    if (byLength != 0) return byLength;
    return a.compareTo(b);
  });
  final best = shorts.first;
  if (!full.startsWith(best) && best.runes.length > 4) return null;
  return best;
}

String _fallbackShortLabel(String full) {
  final parts = full
      .split(RegExp(r'[\s・･]+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    final last = parts.last;
    if (last.runes.length <= 10) return last;
  }
  return full;
}

bool _hasKanaOrKanji(String value) {
  return value.runes.any(
    (rune) =>
        (rune >= 0x3040 && rune <= 0x30FF) ||
        (rune >= 0x4E00 && rune <= 0x9FFF),
  );
}
