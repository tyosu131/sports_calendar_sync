import '../models/game.dart';
import '../models/team.dart';
import 'team_presentation_policy.dart';

/// Optional override point for a future explicit user language preference.
enum DisplayLanguage { japanese, english }

/// The single app-side policy for choosing team names.
///
/// A name lookup only affects presentation. It never assigns or implies a
/// canonical Team id.
class TeamDisplayNamePolicy {
  const TeamDisplayNamePolicy({this.languageOverride});

  final DisplayLanguage? languageOverride;

  static const _japaneseCompetitions = {
    'football_j1',
    'football_j2',
    'football_j3',
    'football_j_league_cup',
    'football_emperor_cup',
  };

  DisplayLanguage languageFor(String? competitionKey) =>
      languageOverride ??
      (_japaneseCompetitions.contains(competitionKey)
          ? DisplayLanguage.japanese
          : DisplayLanguage.english);

  String teamName(Team team) => _select(
    teamId: team.id,
    competitionKey: team.competitionKey,
    japanese: team.nameJa,
    english: team.nameEn,
  );

  String homeName(Game game) => _select(
    teamId: game.homeTeamId,
    competitionKey: game.competitionKey,
    japanese: game.homeTeamNameJa,
    english: game.homeTeamNameEn,
    provider: game.homeTeamProviderName,
  );

  String awayName(Game game) => _select(
    teamId: game.awayTeamId,
    competitionKey: game.competitionKey,
    japanese: game.awayTeamNameJa,
    english: game.awayTeamNameEn,
    provider: game.awayTeamProviderName,
  );

  String _select({
    String? teamId,
    required String? competitionKey,
    required String japanese,
    required String? english,
    String? provider,
  }) {
    final ja = japanese.trim();
    final en = english?.trim() ?? '';
    final raw = provider?.trim() ?? '';
    final language = languageFor(competitionKey);
    final canonical = _canonicalNames[teamId];
    if (canonical != null) {
      return language == DisplayLanguage.japanese
          ? canonical.japanese
          : canonical.english;
    }
    final evidence = (competitionKey?.startsWith('football_') ?? false)
        ? clubPresentation([en, raw, ja], competitionKey: competitionKey)
        : null;
    final confirmed = language == DisplayLanguage.english
        ? evidence?.nameEn
        : evidence?.nameJa;
    if (confirmed != null && confirmed.isNotEmpty) return confirmed;

    // A catalog miss/conflict is final. Preserve qualifiers and raw names;
    // retrying individual fields would override the unique-evidence check.
    // GOAL stores the original participant in provider; En is the legacy copy.
    // Field precedence is provenance, not a choice between catalog candidates.
    return raw.isNotEmpty
        ? raw
        : en.isNotEmpty
        ? en
        : ja;
  }
}

const _canonicalNames = <String, ({String japanese, String english})>{
  'kawasaki_frontale': (japanese: '川崎フロンターレ', english: 'Kawasaki Frontale'),
  'arsenal': (japanese: 'アーセナル', english: 'Arsenal'),
};

const teamDisplayNames = TeamDisplayNamePolicy();
