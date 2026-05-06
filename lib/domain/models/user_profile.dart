import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile stored in Firestore under /users/{uid}.
///
/// ## selectedCompetitions / favoriteTeamIdsByCompetition
/// Phase 0 adds per-competition team tracking.
/// - [selectedCompetitions]: competition keys the user has opted into.
///   Each value must match a [SportDefinition.competitionKey] in [SportsRegistry].
/// - [favoriteTeamIdsByCompetition]: map from competitionKey to list of team IDs.
///
/// ## Backward compatibility
/// - [followedTeamIds] is a legacy flat list kept for the existing
///   `getCalendar` Cloud Function which queries this field directly.
///   On save, [allFavoriteTeamIds] is written to `followedTeamIds` so the
///   function continues to work without modification.
/// - Legacy Firestore documents that only have `followedTeamIds` are read
///   correctly; [selectedCompetitions] and [favoriteTeamIdsByCompetition]
///   will be empty.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.selectedCompetitions = const [],
    this.favoriteTeamIdsByCompetition = const {},
    this.followedTeamIds = const [],
    this.preferredLanguage = 'ja',
    this.createdAt,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  /// Competition keys the user has opted into.
  /// Each value matches [SportDefinition.competitionKey] in [SportsRegistry].
  /// Examples: ["football_j1", "baseball_npb"]
  final List<String> selectedCompetitions;

  /// Map from competitionKey to list of followed team IDs.
  /// Example: {"football_j1": ["kashima_antlers"], "baseball_npb": ["yomiuri_giants"]}
  final Map<String, List<String>> favoriteTeamIdsByCompetition;

  /// @deprecated Use [favoriteTeamIdsByCompetition].
  /// Kept for backward compatibility with the `getCalendar` Cloud Function.
  final List<String> followedTeamIds;

  /// 'ja' or 'en'.
  final String preferredLanguage;

  final Timestamp? createdAt;

  /// All followed team IDs across all competitions (deduped).
  /// Used by the legacy `getCalendar` function and as the value written to
  /// the `followedTeamIds` Firestore field.
  List<String> get allFavoriteTeamIds {
    if (favoriteTeamIdsByCompetition.isNotEmpty) {
      return favoriteTeamIdsByCompetition.values
          .expand((ids) => ids)
          .toSet()
          .toList();
    }
    // Fallback: legacy documents only have followedTeamIds.
    return followedTeamIds;
  }

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    final Map<String, List<String>> favoriteTeamIdsByCompetition = {};
    final rawMap = data['favoriteTeamIdsByCompetition'] as Map<String, dynamic>?;
    if (rawMap != null) {
      rawMap.forEach((key, value) {
        favoriteTeamIdsByCompetition[key] =
            List<String>.from(value as List? ?? []);
      });
    }

    return UserProfile(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      selectedCompetitions: List<String>.from(
          data['selectedCompetitions'] as List? ?? []),
      favoriteTeamIdsByCompetition: favoriteTeamIdsByCompetition,
      followedTeamIds: List<String>.from(
          data['followedTeamIds'] as List? ?? []),
      preferredLanguage: data['preferredLanguage'] as String? ?? 'ja',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'selectedCompetitions': selectedCompetitions,
      'favoriteTeamIdsByCompetition': favoriteTeamIdsByCompetition,
      // Legacy field — written so getCalendar Cloud Function keeps working.
      'followedTeamIds': allFavoriteTeamIds,
      'preferredLanguage': preferredLanguage,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    List<String>? selectedCompetitions,
    Map<String, List<String>>? favoriteTeamIdsByCompetition,
    List<String>? followedTeamIds,
    String? preferredLanguage,
    Timestamp? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      selectedCompetitions: selectedCompetitions ?? this.selectedCompetitions,
      favoriteTeamIdsByCompetition:
          favoriteTeamIdsByCompetition ?? this.favoriteTeamIdsByCompetition,
      followedTeamIds: followedTeamIds ?? this.followedTeamIds,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns the followed team IDs for a specific competition.
  List<String> favoriteTeamIdsForCompetition(String competitionKey) =>
      favoriteTeamIdsByCompetition[competitionKey] ?? [];

  /// Returns true if the user has opted into the given competition.
  bool hasCompetitionSelected(String competitionKey) =>
      selectedCompetitions.contains(competitionKey);
}
