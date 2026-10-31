import '../../core/config/display_language_setting.dart';
import '../models/game.dart';
import '../models/team.dart';
import 'japanese_domestic_football.dart';
import 'team_presentation_policy.dart';

/// Language of one displayed name.
enum DisplayLanguage { japanese, english }

/// The single app-side policy for choosing team, fighter and venue names.
///
/// Rule (auto mode):
/// - Japanese teams, people and venues use Japanese.
/// - Teams, people and venues from abroad use English.
///
/// When Settings selects English, every name uses English.
///
/// A name lookup only affects presentation. It never assigns or implies a
/// canonical Team id.
class TeamDisplayNamePolicy {
  const TeamDisplayNamePolicy({this.languageOverride});

  /// Fixed language for tests or callers. Null follows the Settings choice.
  final DisplayLanguage? languageOverride;

  DisplayLanguage? get _override =>
      languageOverride ??
      (displayLanguageForcesEnglish ? DisplayLanguage.english : null);

  /// Language for a competition context with no side-specific evidence.
  DisplayLanguage languageFor(String? competitionKey) =>
      _override ??
      (isJapaneseDomesticCompetition(competitionKey)
          ? DisplayLanguage.japanese
          : DisplayLanguage.english);

  /// Language for one team or person.
  ///
  /// A Japanese team or person keeps Japanese in an international
  /// competition (for example Japan in a friendly, or a Japanese UFC
  /// fighter). Evidence is the provider country stored by sync. There is no
  /// hand-kept list of ids: rosters change too often to maintain one.
  DisplayLanguage languageForSide({
    required String? competitionKey,
    String? country,
  }) {
    final override = _override;
    if (override != null) return override;
    if (isJapaneseCountry(country)) return DisplayLanguage.japanese;
    return languageFor(competitionKey);
  }

  String teamName(Team team) => _select(
    teamId: team.id,
    competitionKey: team.competitionKey,
    country: team.country,
    japanese: team.nameJa,
    english: team.nameEn,
  );

  String homeName(Game game) => _select(
    teamId: game.homeTeamId,
    competitionKey: game.competitionKey,
    country: game.homeTeamCountry,
    japanese: game.homeTeamNameJa,
    english: game.homeTeamNameEn,
    provider: game.homeTeamProviderName,
  );

  String awayName(Game game) => _select(
    teamId: game.awayTeamId,
    competitionKey: game.competitionKey,
    country: game.awayTeamCountry,
    japanese: game.awayTeamNameJa,
    english: game.awayTeamNameEn,
    provider: game.awayTeamProviderName,
  );

  /// Venue name. Follows the home side: a Japanese venue uses Japanese,
  /// a venue abroad uses English. Falls back to the stored provider value
  /// when the requested language is not stored.
  String? venueName(Game game) {
    final language = languageForSide(
      competitionKey: game.competitionKey,
      country: game.homeTeamCountry,
    );
    final preferred = language == DisplayLanguage.japanese
        ? game.venueJa
        : game.venueEn;
    final value = preferred?.trim();
    if (value != null && value.isNotEmpty) return value;
    return game.venue;
  }

  String _select({
    String? teamId,
    required String? competitionKey,
    String? country,
    required String japanese,
    required String? english,
    String? provider,
  }) {
    final ja = japanese.trim();
    final en = english?.trim() ?? '';
    final raw = provider?.trim() ?? '';
    final language = languageForSide(
      competitionKey: competitionKey,
      country: country,
    );
    final canonical = _canonicalNames[teamId];
    if (canonical != null) {
      return language == DisplayLanguage.japanese
          ? canonical.japanese
          : canonical.english;
    }
    final isFootball = competitionKey?.startsWith('football_') ?? false;
    final evidence = isFootball
        ? clubPresentation([en, raw, ja], competitionKey: competitionKey)
        : null;
    final confirmed = language == DisplayLanguage.english
        ? evidence?.nameEn
        : evidence?.nameJa;
    if (confirmed != null && confirmed.isNotEmpty) return confirmed;

    // Outside football, nameJa / nameEn are written by our own master data
    // (no provider copy), so the requested language field is used directly.
    if (!isFootball) {
      final requested = language == DisplayLanguage.japanese ? ja : en;
      if (requested.isNotEmpty) return requested;
    }

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

/// Provider country / nationality value for Japan.
bool isJapaneseCountry(String? country) {
  final value = country?.trim().toLowerCase();
  return value == 'japan' || value == 'jp' || value == 'jpn' || value == '日本';
}

const _canonicalNames = <String, ({String japanese, String english})>{
  'kawasaki_frontale': (japanese: '川崎フロンターレ', english: 'Kawasaki Frontale'),
  'arsenal': (japanese: 'アーセナル', english: 'Arsenal'),
};

const teamDisplayNames = TeamDisplayNamePolicy();
