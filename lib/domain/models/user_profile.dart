import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile stored in Firestore under /users/{uid}.
///
/// ## Canonical follow state
/// [followedTeamIds] is the authoritative list of stable team IDs followed by
/// the user. Following a team is independent of the competition in which the
/// team was discovered.
///
/// ## Compatibility fields
/// - [selectedCompetitions]: competition keys the user has opted into.
///   Each value must match a [SportDefinition.competitionKey] in [SportsRegistry].
/// - [favoriteTeamIdsByCompetition]: map from competitionKey to list of team IDs.
/// These fields remain readable and writable for existing documents, but they
/// are not canonical follow state.
///
/// ## Backward compatibility
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

  /// Compatibility field: competition keys the user has opted into.
  /// This is not canonical follow state.
  /// Each value matches [SportDefinition.competitionKey] in [SportsRegistry].
  /// Examples: ["football_j1", "baseball_npb"]
  final List<String> selectedCompetitions;

  /// Compatibility field mapping competitionKey to team IDs.
  /// This is not canonical follow state.
  /// Example: {"football_j1": ["kashima_antlers"], "baseball_npb": ["yomiuri_giants"]}
  final Map<String, List<String>> favoriteTeamIdsByCompetition;

  /// Stable team IDs currently followed by the user.
  /// This flat list is the authoritative, competition-independent follow state.
  final List<String> followedTeamIds;

  /// 'ja' or 'en'.
  final String preferredLanguage;

  final Timestamp? createdAt;

  /// Compatibility alias for the canonical [followedTeamIds] list.
  List<String> get allFavoriteTeamIds => followedTeamIds;

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
      // Canonical follow state; also consumed by getCalendar.
      'followedTeamIds': followedTeamIds,
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

  /// Returns compatibility team IDs recorded for a specific competition.
  /// This does not determine whether a team is globally followed.
  List<String> favoriteTeamIdsForCompetition(String competitionKey) =>
      favoriteTeamIdsByCompetition[competitionKey] ?? [];

  /// Returns true if the compatibility competition preference is selected.
  /// This does not determine whether a team is globally followed.
  bool hasCompetitionSelected(String competitionKey) =>
      selectedCompetitions.contains(competitionKey);
}
