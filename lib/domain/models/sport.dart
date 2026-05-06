/// sport.dart
///
/// ## Phase 0 policy
/// - The [SportType] enum is kept for backward compatibility only.
/// - New code must use [SportsRegistry] + [SportDefinition] instead.
/// - To list competitions in UI, use [SportsRegistry.enabled], not
///   [SportType.values].
library;

import '../../core/config/sports_registry.dart';
import 'sport_definition.dart';

/// @deprecated Kept for backward compatibility.  Use [SportsRegistry] instead.
enum SportType {
  football,
  baseball,
  basketball,
  americanFootball,
  rugby,
  hockey,
}

extension SportTypeExtension on SportType {
  String get displayNameJa {
    switch (this) {
      case SportType.football:
        return 'サッカー';
      case SportType.baseball:
        return '野球';
      case SportType.basketball:
        return 'バスケットボール';
      case SportType.americanFootball:
        return 'アメリカンフットボール';
      case SportType.rugby:
        return 'ラグビー';
      case SportType.hockey:
        return 'ホッケー';
    }
  }

  String get displayNameEn {
    switch (this) {
      case SportType.football:
        return 'Football';
      case SportType.baseball:
        return 'Baseball';
      case SportType.basketball:
        return 'Basketball';
      case SportType.americanFootball:
        return 'American Football';
      case SportType.rugby:
        return 'Rugby';
      case SportType.hockey:
        return 'Hockey';
    }
  }

  String get iconAsset {
    switch (this) {
      case SportType.football:
        return 'assets/icons/football.png';
      case SportType.baseball:
        return 'assets/icons/baseball.png';
      case SportType.basketball:
        return 'assets/icons/basketball.png';
      case SportType.americanFootball:
        return 'assets/icons/american_football.png';
      case SportType.rugby:
        return 'assets/icons/rugby.png';
      case SportType.hockey:
        return 'assets/icons/hockey.png';
    }
  }

  /// Maps this [SportType] to the [SportDefinition.sportCategory] string used
  /// in [SportsRegistry].
  String get sportCategory =>
      name == 'americanFootball' ? 'americanFootball' : name;
}

/// A sports league stored in Firestore under /leagues/{id}.
///
/// ## competitionKey
/// Identifies which competition entry in [SportsRegistry] this league maps to.
/// Must match a [SportDefinition.competitionKey].
///
/// When reading legacy Firestore documents that lack `competitionKey`, the
/// field is left as null rather than guessed from `sportType`.
/// Callers that need a non-null value should handle null explicitly.
///
/// ## Backward compatibility
/// - Firestore field `sportKey` is a legacy alias for `competitionKey`.
///   Both are written on save; `competitionKey` takes precedence on read.
/// - [rapidApiId] is a legacy alias for [externalLeagueId].
/// - [sportType] getter is kept for legacy callers; new code should use
///   [competitionKey] and [sportDefinition].
class League {
  const League({
    required this.id,
    required this.nameEn,
    required this.nameJa,
    required this.country,
    this.competitionKey,
    this.logoUrl,
    this.externalLeagueId,
    @Deprecated('Use competitionKey') SportType? sportType,
    @Deprecated('Use externalLeagueId') int? rapidApiId,
  })  : _sportType = sportType,
        _rapidApiId = rapidApiId;

  final String id;
  final String nameEn;
  final String nameJa;

  /// Competition key matching [SportDefinition.competitionKey].
  /// null when the Firestore document predates Phase 0.
  final String? competitionKey;

  final String country;
  final String? logoUrl;

  /// External API league ID (API-SPORTS or other source).
  final int? externalLeagueId;

  // ignore: deprecated_member_use_from_same_package
  final SportType? _sportType;
  // ignore: deprecated_member_use_from_same_package
  final int? _rapidApiId;

  /// @deprecated Use [competitionKey].
  // ignore: deprecated_member_use_from_same_package
  SportType? get sportType => _sportType;

  /// @deprecated Use [externalLeagueId].
  // ignore: deprecated_member_use_from_same_package
  int? get rapidApiId => _rapidApiId ?? externalLeagueId;

  /// Returns the [SportDefinition] for this league, or null if [competitionKey]
  /// is null or not found in [SportsRegistry].
  SportDefinition? get sportDefinition =>
      competitionKey != null ? SportsRegistry.findByKey(competitionKey!) : null;

  factory League.fromFirestore(Map<String, dynamic> data, String docId) {
    // Prefer the new `competitionKey` field; fall back to legacy `sportKey`.
    // Do NOT infer from `sportType` — ambiguous inference is worse than null.
    final competitionKey =
        data['competitionKey'] as String? ?? data['sportKey'] as String?;

    return League(
      id: docId,
      nameEn: data['nameEn'] as String,
      nameJa: data['nameJa'] as String,
      competitionKey: competitionKey,
      country: data['country'] as String,
      logoUrl: data['logoUrl'] as String?,
      externalLeagueId: data['externalLeagueId'] as int? ??
          data['rapidApiId'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nameEn': nameEn,
      'nameJa': nameJa,
      if (competitionKey != null) 'competitionKey': competitionKey,
      // Legacy alias — kept so existing queries on `sportKey` still work.
      if (competitionKey != null) 'sportKey': competitionKey,
      'country': country,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (externalLeagueId != null) 'externalLeagueId': externalLeagueId,
      // Legacy alias.
      if (externalLeagueId != null) 'rapidApiId': externalLeagueId,
    };
  }
}
