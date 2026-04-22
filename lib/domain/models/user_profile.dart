import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile stored in Firestore under /users/{uid}
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.followedTeamIds = const [],
    this.preferredLanguage = 'ja',
    this.createdAt,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  /// List of team IDs the user follows
  final List<String> followedTeamIds;

  /// 'ja' or 'en'
  final String preferredLanguage;

  final Timestamp? createdAt;

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      followedTeamIds: List<String>.from(data['followedTeamIds'] as List? ?? []),
      preferredLanguage: data['preferredLanguage'] as String? ?? 'ja',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
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
    List<String>? followedTeamIds,
    String? preferredLanguage,
    Timestamp? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      followedTeamIds: followedTeamIds ?? this.followedTeamIds,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool isFollowing(String teamId) => followedTeamIds.contains(teamId);
}
