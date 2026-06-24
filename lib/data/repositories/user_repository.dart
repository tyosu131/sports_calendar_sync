import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/app_constants.dart';
import '../../domain/models/user_profile.dart';

/// User profile / auth API used by the app.
abstract class UserRepository {
  User? get currentUser;

  Stream<User?> get authStateChanges;

  Future<UserProfile?> fetchProfile(String uid);

  Stream<UserProfile?> watchProfile(String uid);

  Future<void> upsertProfile(UserProfile profile);

  Future<UserProfile> createProfileFromFirebaseUser(User user);

  Future<void> followTeam(String uid, String teamId, {String? competitionKey});

  Future<void> unfollowTeam(
    String uid,
    String teamId, {
    String? competitionKey,
  });

  Future<void> signOut();
}

/// Handles all Firestore operations for user profiles.
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  /// Returns the currently signed-in Firebase user, or null.
  @override
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Fetch user profile from Firestore. Returns null if not found.
  @override
  Future<UserProfile?> fetchProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc.data()!, uid);
  }

  /// Stream of user profile changes (real-time).
  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromFirestore(snap.data()!, uid);
    });
  }

  /// Create or update user profile in Firestore.
  @override
  Future<void> upsertProfile(UserProfile profile) async {
    await _users
        .doc(profile.uid)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  /// Create a new profile on first sign-in.
  @override
  Future<UserProfile> createProfileFromFirebaseUser(User user) async {
    final profile = UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: Timestamp.now(),
    );
    await upsertProfile(profile);
    return profile;
  }

  /// Add a team to the user's followed list.
  ///
  /// When [competitionKey] is provided, the team is also added to
  /// [UserProfile.favoriteTeamIdsByCompetition] for that competition, and
  /// [UserProfile.selectedCompetitions] is updated accordingly.
  /// The legacy [UserProfile.followedTeamIds] flat list is always kept in sync
  /// so the existing `getCalendar` Cloud Function continues to work.
  @override
  Future<void> followTeam(
    String uid,
    String teamId, {
    String? competitionKey,
  }) async {
    final updates = <String, dynamic>{
      // Legacy flat list — required by getCalendar Cloud Function.
      'followedTeamIds': FieldValue.arrayUnion([teamId]),
    };

    if (competitionKey != null) {
      // Per-competition tracking (Phase 1+).
      updates['favoriteTeamIdsByCompetition.$competitionKey'] =
          FieldValue.arrayUnion([teamId]);
      updates['selectedCompetitions'] = FieldValue.arrayUnion([competitionKey]);
    }

    await _users.doc(uid).update(updates);
  }

  /// Remove a team from the user's followed list.
  ///
  /// When [competitionKey] is provided, the team is also removed from
  /// [UserProfile.favoriteTeamIdsByCompetition] for that competition.
  /// The legacy [UserProfile.followedTeamIds] flat list is always kept in sync.
  @override
  Future<void> unfollowTeam(
    String uid,
    String teamId, {
    String? competitionKey,
  }) async {
    final updates = <String, dynamic>{
      // Legacy flat list — required by getCalendar Cloud Function.
      'followedTeamIds': FieldValue.arrayRemove([teamId]),
    };

    if (competitionKey != null) {
      // Per-competition tracking (Phase 1+).
      updates['favoriteTeamIdsByCompetition.$competitionKey'] =
          FieldValue.arrayRemove([teamId]);
      // Note: we intentionally do NOT remove the competitionKey from
      // selectedCompetitions here — the user may still follow other teams in
      // that competition, and removing it would require a read-then-write.
    }

    await _users.doc(uid).update(updates);
  }

  /// Sign out the current user.
  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

/// In-memory user repository for free MVP sample mode.
///
/// This repository never reads or writes Firestore. It keeps followed teams in
/// memory for the current app session only.
class SampleUserRepository implements UserRepository {
  SampleUserRepository()
    : _profile = UserProfile(
        uid: sampleUid,
        email: 'sample@example.com',
        displayName: 'Sample User',
        selectedCompetitions: const ['football_j1'],
        favoriteTeamIdsByCompetition: const {
          'football_j1': ['kashima_antlers', 'gamba_osaka'],
        },
        followedTeamIds: const ['kashima_antlers', 'gamba_osaka'],
        createdAt: Timestamp.fromMillisecondsSinceEpoch(0),
      );

  static const sampleUid = 'sample_user';

  UserProfile _profile;
  final _profileUpdates = StreamController<UserProfile?>.broadcast();

  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);

  @override
  Future<UserProfile?> fetchProfile(String uid) async {
    return uid == sampleUid ? _profile : null;
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    yield uid == sampleUid ? _profile : null;
    if (uid == sampleUid) {
      yield* _profileUpdates.stream;
    }
  }

  @override
  Future<void> upsertProfile(UserProfile profile) async {
    _profile = profile.copyWith(uid: sampleUid);
    _profileUpdates.add(_profile);
  }

  @override
  Future<UserProfile> createProfileFromFirebaseUser(User user) async {
    _profile = _profile.copyWith(
      email: user.email ?? _profile.email,
      displayName: user.displayName ?? _profile.displayName,
      photoUrl: user.photoURL ?? _profile.photoUrl,
    );
    _profileUpdates.add(_profile);
    return _profile;
  }

  @override
  Future<void> followTeam(
    String uid,
    String teamId, {
    String? competitionKey,
  }) async {
    if (uid != sampleUid) return;

    final followedTeamIds = {..._profile.allFavoriteTeamIds, teamId}.toList();

    final favorites = _copyFavorites(_profile.favoriteTeamIdsByCompetition);
    if (competitionKey != null) {
      favorites[competitionKey] = {
        ...(favorites[competitionKey] ?? const <String>[]),
        teamId,
      }.toList();
    }

    final selectedCompetitions = {
      ..._profile.selectedCompetitions,
      ?competitionKey,
    }.toList();

    _profile = _profile.copyWith(
      followedTeamIds: followedTeamIds,
      selectedCompetitions: selectedCompetitions,
      favoriteTeamIdsByCompetition: favorites,
    );
    _profileUpdates.add(_profile);
  }

  @override
  Future<void> unfollowTeam(
    String uid,
    String teamId, {
    String? competitionKey,
  }) async {
    if (uid != sampleUid) return;

    final followedTeamIds = _profile.allFavoriteTeamIds
        .where((id) => id != teamId)
        .toList();

    final favorites = _copyFavorites(_profile.favoriteTeamIdsByCompetition);
    if (competitionKey != null) {
      favorites[competitionKey] =
          (favorites[competitionKey] ?? const <String>[])
              .where((id) => id != teamId)
              .toList();
    } else {
      for (final entry in favorites.entries) {
        favorites[entry.key] = entry.value.where((id) => id != teamId).toList();
      }
    }

    _profile = _profile.copyWith(
      followedTeamIds: followedTeamIds,
      favoriteTeamIdsByCompetition: favorites,
    );
    _profileUpdates.add(_profile);
  }

  @override
  Future<void> signOut() async {
    // No-op in sample mode. Keeping the profile available makes the free MVP
    // usable without Firebase Auth.
  }

  Map<String, List<String>> _copyFavorites(Map<String, List<String>> source) {
    return {
      for (final entry in source.entries) entry.key: [...entry.value],
    };
  }
}
