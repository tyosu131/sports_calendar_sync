import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/app_constants.dart';
import '../../domain/models/user_profile.dart';

/// Handles all Firestore operations for user profiles.
class UserRepository {
  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  /// Returns the currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Fetch user profile from Firestore. Returns null if not found.
  Future<UserProfile?> fetchProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc.data()!, uid);
  }

  /// Stream of user profile changes (real-time).
  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromFirestore(snap.data()!, uid);
    });
  }

  /// Create or update user profile in Firestore.
  Future<void> upsertProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );
  }

  /// Create a new profile on first sign-in.
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
      updates['selectedCompetitions'] =
          FieldValue.arrayUnion([competitionKey]);
    }

    await _users.doc(uid).update(updates);
  }

  /// Remove a team from the user's followed list.
  ///
  /// When [competitionKey] is provided, the team is also removed from
  /// [UserProfile.favoriteTeamIdsByCompetition] for that competition.
  /// The legacy [UserProfile.followedTeamIds] flat list is always kept in sync.
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
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
