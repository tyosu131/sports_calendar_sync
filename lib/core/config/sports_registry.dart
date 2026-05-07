import '../../domain/models/sport_definition.dart';

/// SportsRegistry — single source of truth for all selectable competitions.
///
/// ## Design
/// - All competition definitions live in [_definitions] only.
/// - UI, repositories, and sync pipelines must reference [SportsRegistry.enabled]
///   or [SportsRegistry.findByKey]; they must NOT hard-code competition names.
/// - Adding / removing / reordering competitions requires only editing
///   [_definitions].
///
/// ## Key naming
/// Each [SportDefinition.competitionKey] identifies a specific league or
/// competition, not a generic sport.  Format: "{sportCategory}_{abbreviation}".
/// The same key is stored in Firestore as `competitionKey` (new documents) and
/// `sportKey` (legacy alias).
///
/// ## Initial 8 competitions
/// J1 League, Premier League, NPB, MLB, NBA, NFL, NHL, B.League
class SportsRegistry {
  SportsRegistry._();

  // ---------------------------------------------------------------------------
  // Competition definitions — edit here only
  // ---------------------------------------------------------------------------

  static const List<SportDefinition> _definitions = [
    SportDefinition(
      competitionKey: 'football_j1',
      displayNameJa: 'Jリーグ',
      displayNameEn: 'J.League',
      sportCategory: 'football',
      sortOrder: 10,
      enabled: true,
      dataSourceKey: 'apisports_football',
      iconAsset: null,
    ),
    SportDefinition(
      competitionKey: 'football_premier',
      displayNameJa: 'プレミアリーグ',
      displayNameEn: 'Premier League',
      sportCategory: 'football',
      sortOrder: 20,
      enabled: true,
      dataSourceKey: 'apisports_football',
      iconAsset: null,
    ),
    SportDefinition(
      competitionKey: 'baseball_npb',
      displayNameJa: 'NPB',
      displayNameEn: 'NPB',
      sportCategory: 'baseball',
      sortOrder: 30,
      enabled: true,
      dataSourceKey: 'apisports_baseball',
      iconAsset: null,
    ),
    SportDefinition(
      competitionKey: 'baseball_mlb',
      displayNameJa: 'MLB',
      displayNameEn: 'MLB',
      sportCategory: 'baseball',
      sortOrder: 40,
      enabled: true,
      dataSourceKey: 'apisports_baseball',
      iconAsset: null,
    ),
    SportDefinition(
      competitionKey: 'basketball_nba',
      displayNameJa: 'NBA',
      displayNameEn: 'NBA',
      sportCategory: 'basketball',
      sortOrder: 50,
      enabled: true,
      dataSourceKey: 'apisports_basketball',
      iconAsset: null,
    ),
    SportDefinition(
      competitionKey: 'americanfootball_nfl',
      displayNameJa: 'NFL',
      displayNameEn: 'NFL',
      sportCategory: 'americanFootball',
      sortOrder: 60,
      enabled: true,
      dataSourceKey: 'apisports_american_football',
      iconAsset: null,
    ),
    SportDefinition(
      competitionKey: 'hockey_nhl',
      displayNameJa: 'NHL',
      displayNameEn: 'NHL',
      sportCategory: 'hockey',
      sortOrder: 70,
      enabled: true,
      dataSourceKey: 'apisports_hockey',
      iconAsset: null,
    ),
    SportDefinition(
      competitionKey: 'basketball_b_league',
      displayNameJa: 'Bリーグ',
      displayNameEn: 'B.League',
      sportCategory: 'basketball',
      sortOrder: 80,
      enabled: true,
      dataSourceKey: 'apisports_basketball',
      iconAsset: null,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// All competition definitions regardless of [SportDefinition.enabled].
  static List<SportDefinition> get all => List.unmodifiable(_definitions);

  /// Enabled competitions only, sorted by [SportDefinition.sortOrder] ascending.
  static List<SportDefinition> get enabled => List.unmodifiable(
        _definitions.where((s) => s.enabled).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );

  /// Returns the [SportDefinition] for [competitionKey], or null if not found.
  static SportDefinition? findByKey(String competitionKey) {
    try {
      return _definitions.firstWhere((s) => s.competitionKey == competitionKey);
    } catch (_) {
      return null;
    }
  }

  /// Returns enabled competitions whose [SportDefinition.sportCategory] matches.
  static List<SportDefinition> findByCategory(String sportCategory) =>
      enabled.where((s) => s.sportCategory == sportCategory).toList();

  /// Distinct sport categories of enabled competitions, in sortOrder order.
  static List<String> get enabledCategories {
    final seen = <String>{};
    return enabled.map((s) => s.sportCategory).where(seen.add).toList();
  }

  /// Returns enabled competitions that use the given [dataSourceKey].
  static List<SportDefinition> findByDataSource(String dataSourceKey) =>
      enabled.where((s) => s.dataSourceKey == dataSourceKey).toList();
}
