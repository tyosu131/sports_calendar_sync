import '../../core/utils/date_time_utils.dart';
import '../models/game.dart';
import '../models/team.dart';
import 'team_display_name_policy.dart';

/// League-card and compact labels.
///
/// Search aliases are identity hints, not a display contract. There is no
/// product short name, so callers receive the canonical display name and
/// ellipsize it in the widget.
String leagueTeamCardLabel(String displayName) => displayName.trim();

String leagueTeamCardLabelForTeam(Team team) =>
    leagueTeamCardLabel(teamDisplayNames.teamName(team));

String leagueTeamCardLabelForName(String displayName) =>
    leagueTeamCardLabel(displayName);

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
  final start = game.startTimeUtc.toDate();
  final when =
      '${DateTimeUtils.formatDateOnly(start)} ${DateTimeUtils.formatTimeOnly(start)}';
  return LeagueTeamNextMatch(opponent: 'vs ${opponentName.trim()}', when: when);
}
