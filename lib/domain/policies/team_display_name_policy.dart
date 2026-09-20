import '../models/game.dart';
import '../models/team.dart';
import 'japanese_club_display_evidence.dart';

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
    'football_j_league_cup',
    'football_emperor_cup',
  };

  DisplayLanguage languageFor(String? competitionKey) => languageOverride ??
      (_japaneseCompetitions.contains(competitionKey)
          ? DisplayLanguage.japanese
          : DisplayLanguage.english);

  String teamName(Team team) => _select(
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
    if (language == DisplayLanguage.english) {
      return en.isNotEmpty ? en : raw.isNotEmpty ? raw : ja;
    }

    // GOAL legacy documents may contain the provider's English value in the
    // *NameJa field. Only use repository-confirmed master evidence to localize.
    final confirmed = japaneseClubDisplayName(en) ??
        japaneseClubDisplayName(raw) ??
        japaneseClubDisplayName(ja);
    if (confirmed != null) return confirmed;
    if (_containsJapanese(ja)) return ja;
    return raw.isNotEmpty ? raw : en.isNotEmpty ? en : ja;
  }

  bool _containsJapanese(String value) =>
      RegExp(r'[\u3040-\u30ff\u3400-\u9fff]').hasMatch(value);
}

const _canonicalNames = <String, ({String japanese, String english})>{
  'kawasaki_frontale': (
    japanese: '川崎フロンターレ',
    english: 'Kawasaki Frontale',
  ),
  'arsenal': (japanese: 'アーセナル', english: 'Arsenal'),
};

const teamDisplayNames = TeamDisplayNamePolicy();
