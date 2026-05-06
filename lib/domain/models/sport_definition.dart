/// SportDefinition — an entry in [SportsRegistry] representing a selectable
/// competition target (league / tournament) within the app.
///
/// ## Naming rationale
/// The field [competitionKey] (and the corresponding Firestore field) is named
/// "competition" rather than "sport" because each entry represents a specific
/// league or competition (e.g. "J1 League", "Premier League"), not a generic
/// sport category.  A single sport category (e.g. "football") may have multiple
/// competition entries.
///
/// ## Usage
/// - Add / remove / reorder competitions by editing [SportsRegistry._definitions].
/// - UI and sync pipelines reference [SportsRegistry.enabled]; they must NOT
///   hard-code competition names.
class SportDefinition {
  const SportDefinition({
    required this.competitionKey,
    required this.displayNameJa,
    required this.displayNameEn,
    required this.sportCategory,
    required this.sortOrder,
    this.enabled = true,
    this.dataSourceKey,
    this.iconAsset,
  });

  /// Unique key for this competition entry.
  /// Matches the value stored in Firestore fields `competitionKey` (new) and
  /// `sportKey` (legacy alias kept for backward compatibility).
  ///
  /// Format: "{sportCategory}_{league_abbreviation}"
  /// Examples: "football_j1", "football_premier", "baseball_npb", "basketball_nba"
  final String competitionKey;

  /// Japanese display name used in UI tabs and labels.
  final String displayNameJa;

  /// English display name used in English UI and logs.
  final String displayNameEn;

  /// Generic sport category this competition belongs to.
  /// Examples: "football", "baseball", "basketball", "americanFootball", "hockey"
  final String sportCategory;

  /// Display order (ascending = shown first).
  final int sortOrder;

  /// When false, the competition is hidden from UI and skipped by sync pipelines.
  final bool enabled;

  /// Identifies the external data source for this competition.
  /// null = not yet configured (Phase 0 placeholder).
  /// Examples: "apisports_football", "apisports_baseball"
  final String? dataSourceKey;

  /// Asset path for the competition icon.  null = use default icon.
  final String? iconAsset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SportDefinition &&
          runtimeType == other.runtimeType &&
          competitionKey == other.competitionKey;

  @override
  int get hashCode => competitionKey.hashCode;

  @override
  String toString() =>
      'SportDefinition(competitionKey: $competitionKey, displayNameEn: $displayNameEn)';
}
