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
  /// Firebase is resolved on first use.
  ///
  /// Follow screens read this type to tell a sample repository from production.
  /// Resolving [FirebaseFirestore.instance] in the constructor throws in widget
  /// tests that never initialize Firebase and never write a follow.
  FirestoreUserRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestoreOverride = firestore,
      _authOverride = auth;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

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
  /// [competitionKey] is retained only for call-site compatibility. It does
  /// not affect the canonical, global follow state.
  @override
  Future<void> followTeam(String uid, String teamId, {String? competitionKey}) {
    return _writeFollow(uid, teamId, follow: true);
  }

  /// Remove a team from the user's followed list.
  ///
  /// [competitionKey] is retained only for call-site compatibility. It does
  /// not affect the canonical, global follow state.
  @override
  Future<void> unfollowTeam(
    String uid,
    String teamId, {
    String? competitionKey,
  }) {
    return _writeFollow(uid, teamId, follow: false);
  }

  /// One update so a legacy document gains the keys rules require after write.
  Future<void> _writeFollow(
    String uid,
    String teamId, {
    required bool follow,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_users.doc(uid));
      transaction.update(
        _users.doc(uid),
        followFieldUpdates(
          existing: snapshot.data(),
          teamId: teamId,
          follow: follow,
          authEmail: _auth.currentUser?.email,
        ),
      );
    });
  }

  /// Sign out the current user.
  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

/// Fields for a follow or unfollow update.
///
/// Rules require `email`, `followedTeamIds`, and `preferredLanguage` on the
/// document after the update. [FieldValue.arrayUnion] alone leaves a legacy
/// document missing those keys, and the update is permission-denied.
/// Existing values are not overwritten. `preferredLanguage` is filled with
/// `ja` only when the key is absent, matching the read fallback. `email` is
/// filled only from the signed-in Auth user when the key is absent.
Map<String, dynamic> followFieldUpdates({
  required Map<String, dynamic>? existing,
  required String teamId,
  required bool follow,
  String? authEmail,
}) {
  final data = existing ?? const <String, dynamic>{};
  final updates = <String, dynamic>{
    'followedTeamIds': follow
        ? FieldValue.arrayUnion([teamId])
        : FieldValue.arrayRemove([teamId]),
  };
  if (!data.containsKey('preferredLanguage')) {
    updates['preferredLanguage'] = 'ja';
  }
  if (!data.containsKey('email')) {
    final email = authEmail?.trim();
    if (email != null && email.isNotEmpty) {
      updates['email'] = email;
    }
  }
  return updates;
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

    // competitionKey is a compatibility-only argument. Stable team identity
    // makes follow state global regardless of discovery context.
    final followedTeamIds = {..._profile.followedTeamIds, teamId}.toList();

    _profile = _profile.copyWith(followedTeamIds: followedTeamIds);
    _profileUpdates.add(_profile);
  }

  @override
  Future<void> unfollowTeam(
    String uid,
    String teamId, {
    String? competitionKey,
  }) async {
    if (uid != sampleUid) return;

    // competitionKey is a compatibility-only argument. Unfollow is global.
    final followedTeamIds = _profile.followedTeamIds
        .where((id) => id != teamId)
        .toList();

    _profile = _profile.copyWith(followedTeamIds: followedTeamIds);
    _profileUpdates.add(_profile);
  }

  @override
  Future<void> signOut() async {
    // No-op in sample mode. Keeping the profile available makes the free MVP
    // usable without Firebase Auth.
  }
}
